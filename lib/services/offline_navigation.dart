import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

double localMeters(num a, num b, num c, num d) {
  final y = (a - c) * 111320;
  final x = (b - d) * 105600;
  return math.sqrt(x * x + y * y);
}

class OfflineMapData {
  OfflineMapData(this.raw);
  final Map<String, dynamic> raw;
  List<dynamic> get nodes => raw['nodes'];
  List<dynamic> get roads => raw['roads'];
  List<dynamic> get places => raw['places'];
  bool contains(double lat, double lon) =>
      lat >= 18.39 && lat <= 18.62 && lon >= -70.08 && lon <= -69.76;
  static Future<OfflineMapData> load() async {
    final bytes = await rootBundle.load('assets/maps/santo_domingo.json.gz');
    final data = await compute(
      _decodeMap,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return OfflineMapData(data);
  }

  List<List<dynamic>> search(String text) {
    final query = _normalize(text);
    if (query.length < 3) return [];
    final words = query.split(' ').where((s) => s.isNotEmpty);
    return places
        .where((p) => words.every((w) => _normalize(p[0]).contains(w)))
        .take(25)
        .map((p) => List<dynamic>.from(p))
        .toList();
  }

  Future<List<int>> route(double lat, double lon, List<dynamic> target) =>
      compute(_route, {
        'map': raw,
        'start': [lat, lon],
        'target': [target[1], target[2]],
      });
}

String _normalize(String value) {
  var result = value.toLowerCase();
  for (final pair in ['áa', 'ée', 'íi', 'óo', 'úu', 'ñn']) {
    result = result.replaceAll(pair[0], pair[1]);
  }
  return result
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(' +'), ' ')
      .trim();
}

Map<String, dynamic> _decodeMap(Uint8List bytes) {
  final data =
      jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
  final nodes = data['nodes'] as List;
  data['roadBounds'] = (data['roads'] as List).map((road) {
    double south = 90, west = 180, north = -90, east = -180;
    for (final id in road[0]) {
      final p = nodes[id];
      south = math.min(south, (p[0] as num).toDouble());
      north = math.max(north, (p[0] as num).toDouble());
      west = math.min(west, (p[1] as num).toDouble());
      east = math.max(east, (p[1] as num).toDouble());
    }
    return [south, west, north, east];
  }).toList();
  return data;
}

// An A* request owns its graph and runs in an isolate, then releases it.
List<int> _route(Map<String, dynamic> args) {
  final data = args['map'] as Map<String, dynamic>;
  final nodes = data['nodes'] as List;
  final roads = data['roads'] as List;
  final start = args['start'] as List, target = args['target'] as List;
  int nearest(List point) {
    var best = -1;
    var distance = 250.0;
    for (var i = 0; i < nodes.length; i++) {
      final p = nodes[i];
      final d = localMeters(point[0], point[1], p[0], p[1]);
      if (d < distance) {
        best = i;
        distance = d;
      }
    }
    return best;
  }

  final source = nearest(start), finish = nearest(target);
  if (source < 0 || finish < 0) return [];
  final adjacency = <int, List<(int, int, double)>>{};
  for (var r = 0; r < roads.length; r++) {
    final road = roads[r];
    final ids = road[0] as List;
    for (var i = 1; i < ids.length; i++) {
      final a = ids[i - 1] as int, b = ids[i] as int;
      final p = nodes[a], q = nodes[b];
      final distance = localMeters(p[0], p[1], q[0], q[1]);
      if (road[3] != -1) (adjacency[a] ??= []).add((b, r, distance));
      if (road[3] != 1) (adjacency[b] ??= []).add((a, r, distance));
    }
  }
  final restrictions = <int, List<dynamic>>{};
  for (final r in data['restrictions'] as List) {
    (restrictions[r[0]] ??= []).add(r);
  }
  double heuristic(int n) =>
      localMeters(nodes[n][0], nodes[n][1], nodes[finish][0], nodes[finish][1]);
  final count = roads.length + 1;
  final initial = source * count;
  final costs = <int, double>{initial: 0}, previous = <int, int>{};
  final queue = _RouteQueue()..add((heuristic(source), initial));
  while (queue.isNotEmpty) {
    final current = queue.pop();
    final state = current.$2;
    final node = state ~/ count, incoming = state % count - 1;
    final cost = costs[state]!;
    if (current.$1 > cost + heuristic(node) + .01) continue;
    if (node == finish) {
      final path = <int>[node];
      var cursor = state;
      while (previous.containsKey(cursor)) {
        cursor = previous[cursor]!;
        path.add(cursor ~/ count);
      }
      return path.reversed.toList();
    }
    for (final edge in adjacency[node] ?? <(int, int, double)>[]) {
      var allowed = true;
      for (final rule in restrictions[node] ?? []) {
        if (rule[1] == incoming &&
            (rule[3] ? edge.$2 != rule[2] : edge.$2 == rule[2])) {
          allowed = false;
          break;
        }
      }
      if (!allowed) continue;
      final next = edge.$1 * count + edge.$2 + 1;
      final score = cost + edge.$3;
      if (score >= (costs[next] ?? double.infinity)) continue;
      costs[next] = score;
      previous[next] = state;
      queue.add((score + heuristic(edge.$1), next));
    }
  }
  return [];
}

class _RouteQueue {
  final _items = <(double, int)>[];
  bool get isNotEmpty => _items.isNotEmpty;
  void add((double, int) item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final p = (i - 1) ~/ 2;
      if (_items[p].$1 <= item.$1) break;
      _items[i] = _items[p];
      i = p;
    }
    _items[i] = item;
  }

  (double, int) pop() {
    final first = _items.first, last = _items.removeLast();
    if (_items.isEmpty) return first;
    var i = 0;
    while (i * 2 + 1 < _items.length) {
      var c = i * 2 + 1;
      if (c + 1 < _items.length && _items[c + 1].$1 < _items[c].$1) c++;
      if (_items[c].$1 >= last.$1) break;
      _items[i] = _items[c];
      i = c;
    }
    _items[i] = last;
    return first;
  }
}
