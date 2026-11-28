import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/offline_navigation.dart';

class OfflineNavigator extends StatefulWidget {
  const OfflineNavigator({
    super.key,
    required this.position,
    required this.onGps,
    required this.onUsb,
    required this.enabled,
    this.sourceError,
  });
  final Position? position;
  final VoidCallback onGps, onUsb;
  final bool enabled;
  final String? sourceError;
  @override
  State<OfflineNavigator> createState() => _OfflineNavigatorState();
}

class _OfflineNavigatorState extends State<OfflineNavigator> {
  OfflineMapData? _map;
  String? _error;
  List<dynamic>? _target;
  List<int> _route = [];
  bool _routing = false;
  int _generation = 0;
  int _progress = 0;
  DateTime _lastRoute = DateTime(2000);
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    OfflineMapData.load()
        .then((data) {
          if (mounted) setState(() => _map = data);
        })
        .catchError((Object e) {
          if (mounted)
            setState(() => _error = 'No se pudo abrir el mapa local.');
        });
  }

  @override
  void didUpdateWidget(covariant OfflineNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final p = widget.position;
    if (p != null && p != oldWidget.position && _route.isNotEmpty) {
      var distance = double.infinity;
      var next = _progress;
      for (
        var i = _progress;
        i < math.min(_route.length, _progress + 150);
        i++
      ) {
        final point = _map!.nodes[_route[i]];
        final end = _map!.nodes[_route[math.min(i + 1, _route.length - 1)]];
        final x = (end[1] - point[1]) * 105600,
            y = (end[0] - point[0]) * 111320;
        final px = (p.longitude - point[1]) * 105600,
            py = (p.latitude - point[0]) * 111320;
        final length = x * x + y * y;
        final t = length == 0
            ? 0.0
            : ((px * x + py * y) / length).clamp(0.0, 1.0);
        final d = math.sqrt(math.pow(px - t * x, 2) + math.pow(py - t * y, 2));
        if (d < distance) {
          distance = d;
          next = i;
        }
      }
      _progress = next;
      if (distance > 90 &&
          !_routing &&
          DateTime.now().difference(_lastRoute).inSeconds > 10)
        _navigate();
    }
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final p = widget.position, map = _map, target = _target;
    if (p == null || map == null || target == null) return;
    if (!map.contains(p.latitude, p.longitude)) {
      setState(
        () => _error = 'Tu posición está fuera del mapa de Santo Domingo.',
      );
      return;
    }
    final generation = ++_generation;
    setState(() {
      _routing = true;
      _error = null;
    });
    _lastRoute = DateTime.now();
    try {
      final route = await map.route(p.latitude, p.longitude, target);
      if (!mounted || generation != _generation) return;
      setState(() {
        _route = route;
        _progress = 0;
        _error = route.isEmpty
            ? 'No hay una ruta conectada a esa dirección en el mapa local.'
            : null;
      });
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() => _error = 'No se pudo calcular esta ruta.');
    } finally {
      if (mounted && generation == _generation)
        setState(() => _routing = false);
    }
  }

  Future<void> _destination() async {
    if (_map == null) return;
    _search.clear();
    final choice = await showModalBottomSheet<List<dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final matches = _map!.search(_search.text);
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * .85,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 8,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: (_) => update(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Dirección o lugar en Santo Domingo',
                      hintText: 'Calle, número o lugar',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  if (_search.text.length >= 3 && matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Esta dirección no figura en los datos locales de OpenStreetMap.',
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(matches[i][0]),
                        subtitle: Text(
                          '${(matches[i][1] as num).toStringAsFixed(4)}, ${(matches[i][2] as num).toStringAsFixed(4)}',
                        ),
                        onTap: () => Navigator.pop(context, matches[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      _target = choice;
      _route = [];
      _progress = 0;
    });
    if (widget.position == null) {
      widget.onGps();
      setState(() => _error = 'Esperando posición GPS para calcular la ruta.');
    } else
      await _navigate();
  }

  String _guidance() {
    if (_route.isEmpty) return _target?[0] ?? 'Santo Domingo · mapa local';
    final map = _map!, p = widget.position;
    final last = map.nodes[_route.last];
    if (p != null &&
        localMeters(p.latitude, p.longitude, last[0], last[1]) < 30)
      return 'Has llegado al destino';
    var remaining = 0.0;
    for (var i = _progress + 1; i < _route.length; i++) {
      final a = map.nodes[_route[i - 1]], b = map.nodes[_route[i]];
      remaining += localMeters(a[0], a[1], b[0], b[1]);
    }
    var instruction = 'Continúa por la ruta';
    var ahead = 0.0;
    for (var i = _progress + 1; i < _route.length - 1; i++) {
      final a = map.nodes[_route[i - 1]],
          b = map.nodes[_route[i]],
          c = map.nodes[_route[i + 1]];
      ahead += localMeters(a[0], a[1], b[0], b[1]);
      final first = math.atan2((b[1] - a[1]) * 105600, (b[0] - a[0]) * 111320);
      final second = math.atan2((c[1] - b[1]) * 105600, (c[0] - b[0]) * 111320);
      var delta = second - first;
      while (delta > math.pi) delta -= 2 * math.pi;
      while (delta < -math.pi) delta += 2 * math.pi;
      if (delta.abs() > .65 && ahead > 12) {
        instruction =
            'En ${ahead.round()} m, gira a la ${delta > 0 ? 'derecha' : 'izquierda'}';
        break;
      }
      if (ahead > 500) break;
    }
    return '$instruction · ${(remaining / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position, map = _map;
    if (p != null &&
        _target != null &&
        _route.isEmpty &&
        !_routing &&
        _error == 'Esperando posición GPS para calcular la ruta.') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigate();
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF09151F)),
        if (map != null)
          RepaintBoundary(
            child: CustomPaint(
              painter: _OfflineStreets(map, p, _route, _progress),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: map == null ? null : _destination,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar dirección'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'GPS del equipo',
                onPressed: widget.onGps,
                icon: const Icon(Icons.my_location),
              ),
              IconButton.filledTonal(
                tooltip: 'Receptor GPS USB',
                onPressed: widget.onUsb,
                icon: const Icon(Icons.usb),
              ),
            ],
          ),
        ),
        if (map == null) const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 24,
          left: 8,
          right: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xED081019),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  if (_routing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  Expanded(
                    child: Text(
                      _routing
                          ? 'Calculando ruta local…'
                          : widget.sourceError ?? _error ?? _guidance(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_target != null)
                    IconButton(
                      tooltip: 'Terminar ruta',
                      onPressed: () {
                        _generation++;
                        setState(() {
                          _route = [];
                          _target = null;
                          _routing = false;
                          _error = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 4,
          right: 8,
          child: Text(
            '© OpenStreetMap contributors · ODbL',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _OfflineStreets extends CustomPainter {
  _OfflineStreets(this.map, this.position, this.route, this.progress);
  final OfflineMapData map;
  final Position? position;
  final List<int> route;
  final int progress;
  @override
  void paint(Canvas canvas, Size size) {
    final lat = position?.latitude ?? 18.4861,
        lon = position?.longitude ?? -69.9312;
    final scale = size.shortestSide / 1700;
    Offset project(dynamic p) => Offset(
      size.width / 2 + (p[1] - lon) * 105600 * scale,
      size.height / 2 - (p[0] - lat) * 111320 * scale,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final visible = (Offset.zero & size).inflate(35);
    final labels = <String>{};
    var count = 0;
    for (var roadIndex = 0; roadIndex < map.roads.length; roadIndex++) {
      final road = map.roads[roadIndex];
      final bounds = map.raw['roadBounds'][roadIndex];
      final halfLat = (size.height / 2 + 40) / scale / 111320,
          halfLon = (size.width / 2 + 40) / scale / 105600;
      if (bounds[2] < lat - halfLat ||
          bounds[0] > lat + halfLat ||
          bounds[3] < lon - halfLon ||
          bounds[1] > lon + halfLon)
        continue;
      final ids = road[0] as List;
      final path = Path();
      var seen = false;
      for (var i = 0; i < ids.length; i++) {
        final point = project(map.nodes[ids[i]]);
        if (i == 0)
          path.moveTo(point.dx, point.dy);
        else
          path.lineTo(point.dx, point.dy);
        if (visible.contains(point)) seen = true;
      }
      if (!seen) continue;
      final major = [
        'motorway',
        'trunk',
        'primary',
        'secondary',
        'tertiary',
      ].contains(road[2]);
      canvas.drawPath(
        path,
        paint
          ..color = major ? const Color(0xFF386074) : const Color(0xFF223746)
          ..strokeWidth = major ? 5 : 2.3,
      );
      if (major && count < 16 && labels.add(road[1])) {
        final point = project(map.nodes[ids[ids.length ~/ 2]]);
        if (visible.deflate(55).contains(point)) {
          final text = TextPainter(
            text: TextSpan(
              text: road[1],
              style: const TextStyle(
                color: Color(0xFFABC2D1),
                fontSize: 10,
                fontFamily: 'Inter',
                backgroundColor: Color(0xCC09151F),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 140);
          text.paint(canvas, point);
          text.dispose();
          count++;
        }
      }
    }
    if (route.isNotEmpty) {
      final path = Path();
      for (var i = progress; i < route.length; i++) {
        final p = project(map.nodes[route[i]]);
        if (i == progress)
          path.moveTo(p.dx, p.dy);
        else
          path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        paint
          ..color = const Color(0xFF052D44)
          ..strokeWidth = 10,
      );
      canvas.drawPath(
        path,
        paint
          ..color = const Color(0xFF28D9FF)
          ..strokeWidth = 5,
      );
      canvas.drawCircle(
        project(map.nodes[route.last]),
        6,
        Paint()..color = Colors.orangeAccent,
      );
    }
    if (position != null) {
      final center = size.center(Offset.zero);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      if (position!.heading.isFinite &&
          position!.heading >= 0 &&
          position!.speed > 1)
        canvas.rotate(position!.heading * math.pi / 180);
      canvas.drawCircle(
        Offset.zero,
        21,
        Paint()..color = const Color(0x331CD6F8),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, -14)
          ..lineTo(10, 12)
          ..lineTo(0, 7)
          ..lineTo(-10, 12)
          ..close(),
        Paint()..color = const Color(0xFF85EEFF),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OfflineStreets old) =>
      old.position != position ||
      old.route != route ||
      old.progress != progress ||
      old.map != map;
}
