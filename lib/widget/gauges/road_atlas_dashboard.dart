import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../dashboard_brand_mark.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../core/app_colors.dart';
import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../../providers/obd_provider.dart';
import '../../services/usb_gnss_reader.dart';
import '../vehicle_top_view.dart';
import '../display_units.dart';
import '../vehicle_stage.dart';
import 'local_position_view.dart';

class RoadAtlasDashboard extends StatelessWidget {
  const RoadAtlasDashboard({
    super.key,
    required this.data,
    required this.source,
    this.preview = false,
    this.onGarage,
  });

  // Like the other legacy instrument widgets, data is already in display units.
  final ObdData data;
  final String source;
  final bool preview;
  final VoidCallback? onGarage;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final vehicle = settings.selectedVehicle;
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 300 || constraints.maxWidth < 590;
          final showInstruments =
              !preview &&
              constraints.maxWidth >= 760 &&
              constraints.maxHeight >= 260;
          return Row(
            textDirection: !preview && settings.roadAtlasVehicleOnRight
                ? TextDirection.rtl
                : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: compact ? 4 : 3,
                child: _RoadPanel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const DashboardBrandMark(width: 38),
                          const Spacer(),
                          if (onGarage != null)
                            IconButton(
                              tooltip: 'Abrir garaje',
                              onPressed: onGarage,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.directions_car_outlined,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child:
                            vehicle != null &&
                                !preview &&
                                vehicle.artworkPath == null
                            ? VehicleTopView(
                                colorHex: settings.vehicleColorHex,
                                vehicle: vehicle,
                              )
                            : VehiclePhoto(
                                artwork: preview ? null : vehicle?.artworkPath,
                                demo: preview || vehicle == null,
                                reduceMotion: true,
                              ),
                      ),
                      if (!preview && vehicle != null)
                        Text(
                          '${vehicle.brand} ${vehicle.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${data.speed}',
                                style: TextStyle(
                                  height: 1,
                                  fontSize: compact ? 38 : 69,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const SpeedUnitLabel(
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: _RoadPanel(
                  padding: EdgeInsets.zero,
                  child: preview
                      ? const _MapPlaceholder(label: 'MAPA EN VIVO')
                      : const _RoadMap(),
                ),
              ),
              if (showInstruments) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _RoadPanel(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SideReading(
                          Icons.speed_rounded,
                          'RPM',
                          data.rpm == 0 && source == 'SIN CONEXIÓN'
                              ? '—'
                              : '${data.rpm} rpm',
                        ),
                        _SideReading(
                          Icons.thermostat_outlined,
                          'TEMPERATURA',
                          data.engineTemp == 0 && source == 'SIN CONEXIÓN'
                              ? '—'
                              : '${settings.convertTemp(data.engineTemp).round()} ${settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F'}',
                        ),
                        _SideReading(
                          Icons.bolt_outlined,
                          'BATERÍA',
                          data.voltage <= 0
                              ? '—'
                              : '${data.voltage.toStringAsFixed(1)} V',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SideReading extends StatelessWidget {
  const _SideReading(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.accent, size: 18),
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondaryColor,
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _RoadPanel extends StatelessWidget {
  const _RoadPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.hardEdge,
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF122731), Color(0xFF091219)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF254B5A)),
    ),
    child: child,
  );
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const LocalPositionView(trail: []),
      Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: AppColors.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _RoadMap extends StatefulWidget {
  const _RoadMap();

  @override
  State<_RoadMap> createState() => _RoadMapState();
}

class _RoadMapState extends State<_RoadMap> with WidgetsBindingObserver {
  static const _tileHost = 'tile.openstreetmap.org';
  static const _userAgent =
      'DashCore/2.0 (https://github.com/FRITO-SALAMI/DashCore)';
  final _trail = LocalTrail();
  final Map<(int, int, int), Future<Uint8List?>> _visibleTiles = {};
  final _failedTiles = <(int, int, int)>{};
  final _retriedTiles = <(int, int, int)>{};
  Timer? _tileRetry;
  bool _mapUnavailable = false;
  StreamSubscription<Position>? _positions;
  StreamSubscription<UsbEvent>? _usbEvents;
  UsbGnssReader? _usbReader;
  (UsbDevice, int)? _usbSource;
  String? _sourceError;
  HttpClient? _client;
  ObdProvider? _obd;
  Position? _position;
  bool _enabled = false;
  bool _isForeground = true;
  bool _isCurrent = true;
  bool _appActive = true;
  static const _zoom = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _appActive = context.watch<DashSettingsProvider>().isAppActive;
    _updateActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android's USB permission dialog briefly makes the activity inactive.
    if (state == AppLifecycleState.inactive) return;
    _isForeground = state == AppLifecycleState.resumed;
    _updateActivity();
  }

  void _updateActivity() {
    if (!_enabled || !_isCurrent || !_isForeground || !_appActive) {
      _stop();
      return;
    }
    if (_positions != null || _usbReader != null) return;
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6)
      ..maxConnectionsPerHost = 6;
    final usb = _usbSource;
    if (usb != null) {
      final reader = UsbGnssReader();
      _usbReader = reader;
      _usbEvents = UsbSerial.usbEventStream?.listen((event) {
        if (event.event == UsbEvent.ACTION_USB_DETACHED &&
            event.device?.deviceName == usb.$1.deviceName) {
          _usbFailed(reader, 'El receptor GPS USB se desconectó.');
        }
      });
      unawaited(
        reader
            .start(
              usb.$1,
              usb.$2,
              _onPosition,
              () => _usbFailed(reader, 'Se perdió la señal del puerto USB.'),
            )
            .catchError((Object error) {
              _usbFailed(
                reader,
                error is StateError
                    ? error.message
                    : 'No se pudo abrir el GPS USB.',
              );
            }),
      );
      return;
    }
    final obd = context.read<ObdProvider>();
    _obd = obd;
    _positions = obd.gpsPositions.listen(_onPosition);
    final last = obd.lastGpsPosition;
    if (last != null &&
        DateTime.now().difference(last.timestamp) <
            const Duration(seconds: 20)) {
      _onPosition(last);
    }
    final clientAtStart = _client;
    unawaited(
      obd.acquireVisualLocation().then((ready) {
        if (!mounted || ready || !identical(_client, clientAtStart)) return;
        _stop();
        setState(() {
          _enabled = false;
          _sourceError =
              'Activa la ubicación y permite su uso para ver el mapa.';
        });
      }),
    );
  }

  void _usbFailed(UsbGnssReader reader, String message) {
    if (!mounted || !identical(_usbReader, reader)) return;
    _stop();
    setState(() {
      _enabled = false;
      _sourceError = message;
    });
  }

  Future<void> _selectUsb() async {
    try {
      final devices = await UsbSerial.listDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() => _sourceError = 'Conecta un receptor GPS NMEA por USB.');
        return;
      }
      UsbDevice device = devices.first;
      var baud = 9600;
      final selection = await showDialog<(UsbDevice, int)>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('GPS USB'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<UsbDevice>(
                  isExpanded: true,
                  value: device,
                  items: devices
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.productName ?? value.deviceName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) update(() => device = value);
                  },
                ),
                DropdownButton<int>(
                  value: baud,
                  items: [4800, 9600, 38400, 115200]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value baudios'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) update(() => baud = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, (device, baud)),
                child: const Text('Conectar'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || selection == null) return;
      setState(() {
        _usbSource = selection;
        _sourceError = null;
        _enabled = true;
      });
      _updateActivity();
    } catch (_) {
      if (mounted)
        setState(() => _sourceError = 'No se pudo consultar el puerto USB.');
    }
  }

  void _onPosition(Position position) {
    if (!mounted ||
        (_positions == null && _usbReader == null) ||
        !position.latitude.isFinite ||
        position.latitude.abs() > 90 ||
        !position.longitude.isFinite ||
        position.longitude.abs() > 180 ||
        !position.accuracy.isFinite ||
        position.accuracy > 50)
      return;
    _trail.add(position);
    setState(() => _position = position);
  }

  void _stop() {
    unawaited(_usbEvents?.cancel());
    _usbEvents = null;
    unawaited(_usbReader?.close());
    _usbReader = null;
    unawaited(_positions?.cancel());
    _positions = null;
    _obd?.releaseVisualLocation();
    _obd = null;
    _client?.close(force: true);
    _client = null;
    _tileRetry?.cancel();
    _tileRetry = null;
    _visibleTiles.clear();
    _failedTiles.clear();
    _retriedTiles.clear();
    _mapUnavailable = false;
    _trail.clear();
    _position = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  Future<Uint8List?> _loadTile((int, int, int) key, HttpClient client) async {
    final bytes = await _tile(key, client);
    if (!mounted ||
        !identical(_client, client) ||
        !_visibleTiles.containsKey(key)) {
      return bytes;
    }
    if (bytes == null) {
      _failedTiles.add(key);
      if (!_retriedTiles.contains(key)) {
        _tileRetry ??= Timer(const Duration(seconds: 4), () {
          _tileRetry = null;
          if (!mounted || !identical(_client, client)) return;
          setState(() {
            for (final failed in _failedTiles.difference(_retriedTiles)) {
              _retriedTiles.add(failed);
              _visibleTiles.remove(failed);
            }
          });
        });
      }
    } else {
      _failedTiles.remove(key);
    }
    final unavailable =
        _failedTiles.isNotEmpty &&
        _visibleTiles.keys.every(_failedTiles.contains);
    if (unavailable != _mapUnavailable) {
      setState(() => _mapUnavailable = unavailable);
    }
    return bytes;
  }

  Future<Uint8List?> _tile((int, int, int) key, HttpClient client) async {
    try {
      final cache = Directory(
        '${(await getTemporaryDirectory()).path}/road-atlas-osm',
      );
      await cache.create(recursive: true);
      final tile = File('${cache.path}/${key.$1}-${key.$2}-${key.$3}.png');
      final expiryFile = File('${tile.path}.expiry');
      var oldHeaders = <String>[];
      if (await tile.exists() && await expiryFile.exists()) {
        oldHeaders = await expiryFile.readAsLines();
        final expiry = int.tryParse(oldHeaders.firstOrNull ?? '') ?? 0;
        if (expiry > DateTime.now().millisecondsSinceEpoch)
          return await tile.readAsBytes();
      }
      if (!identical(_client, client)) return null;
      final request = await client.getUrl(
        Uri.https(_tileHost, '/${key.$1}/${key.$2}/${key.$3}.png'),
      );
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      if (oldHeaders.length > 1 && oldHeaders[1].isNotEmpty) {
        request.headers.set(HttpHeaders.ifNoneMatchHeader, oldHeaders[1]);
      }
      if (oldHeaders.length > 2 && oldHeaders[2].isNotEmpty) {
        request.headers.set(HttpHeaders.ifModifiedSinceHeader, oldHeaders[2]);
      }
      final response = await request.close().timeout(
        const Duration(seconds: 7),
      );
      final cached =
          response.statusCode == HttpStatus.notModified &&
          oldHeaders.isNotEmpty;
      if (!cached && response.statusCode != HttpStatus.ok) {
        await response.drain<void>().timeout(const Duration(seconds: 3));
        return null;
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 7))) {
        if (bytes.length + chunk.length > 256 * 1024) return null;
        bytes.add(chunk);
      }
      final result = cached ? await tile.readAsBytes() : bytes.takeBytes();
      if (result.isEmpty || !identical(_client, client)) return null;
      final control =
          response.headers.value(HttpHeaders.cacheControlHeader) ?? '';
      final seconds = int.tryParse(
        RegExp(r'(?:^|,)\s*max-age=(\d+)').firstMatch(control)?.group(1) ?? '',
      );
      DateTime? expires;
      final expiryHeader = response.headers.value(HttpHeaders.expiresHeader);
      if (expiryHeader != null) {
        try {
          expires = HttpDate.parse(expiryHeader);
        } on FormatException {
          /* Use fallback. */
        }
      }
      if (!control.contains('no-store')) {
        final now = DateTime.now();
        final age =
            int.tryParse(response.headers.value(HttpHeaders.ageHeader) ?? '') ??
            0;
        final deadline = control.contains('no-cache')
            ? now
            : seconds != null
            ? now.add(Duration(seconds: math.max(0, seconds - age)))
            : expires ?? now.add(const Duration(days: 7));
        if (!cached) await tile.writeAsBytes(result);
        final etag =
            response.headers.value(HttpHeaders.etagHeader) ??
            (cached && oldHeaders.length > 1 ? oldHeaders[1] : '');
        final modified =
            response.headers.value(HttpHeaders.lastModifiedHeader) ??
            (cached && oldHeaders.length > 2 ? oldHeaders[2] : '');
        await expiryFile.writeAsString(
          '${deadline.millisecondsSinceEpoch}\n$etag\n$modified',
        );
        unawaited(_trimCache(cache));
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _trimCache(Directory cache) async {
    try {
      final tiles = await cache
          .list()
          .where((item) => item.path.endsWith('.png'))
          .cast<File>()
          .toList();
      if (tiles.length <= 96) return;
      final dated = await Future.wait(
        tiles.map((file) async => (file, await file.lastModified())),
      );
      dated.sort((a, b) => b.$2.compareTo(a.$2));
      for (final tile in dated.skip(96)) {
        await tile.$1.delete();
        final expiration = File('${tile.$1.path}.expiry');
        if (await expiration.exists()) await expiration.delete();
      }
    } on FileSystemException {
      // Other tile writes can trim the same entry first.
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final client = _client;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (position == null || _mapUnavailable)
          LocalPositionView(trail: _trail.positions)
        else
          const ColoredBox(color: Color(0xFF162632)),
        if (position != null && client != null)
          LayoutBuilder(
            builder: (context, size) {
              const tileSize = 256.0;
              final count = 1 << _zoom;
              final lat =
                  position.latitude.clamp(-85.0511, 85.0511) * math.pi / 180;
              final tileX = (position.longitude + 180) / 360 * count;
              final tileY =
                  (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) /
                  2 *
                  count;
              final left = tileX - size.maxWidth / tileSize / 2;
              final top = tileY - size.maxHeight / tileSize / 2;
              final dpr = MediaQuery.devicePixelRatioOf(context);
              double snap(double value) => (value * dpr).roundToDouble() / dpr;
              final keys = <(int, int, int)>{};
              final widgets = <Widget>[];
              for (
                var y = top.floor();
                y < (top + size.maxHeight / tileSize).ceil();
                y++
              ) {
                if (y < 0 || y >= count) continue;
                for (
                  var x = left.floor();
                  x < (left + size.maxWidth / tileSize).ceil();
                  x++
                ) {
                  final key = (_zoom, x % count, y);
                  keys.add(key);
                  final xPx = snap((x - left) * tileSize);
                  final yPx = snap((y - top) * tileSize);
                  widgets.add(
                    Positioned(
                      key: ValueKey((x, y, _zoom)),
                      left: xPx,
                      top: yPx,
                      width: snap((x + 1 - left) * tileSize) - xPx,
                      height: snap((y + 1 - top) * tileSize) - yPx,
                      child: FutureBuilder<Uint8List?>(
                        future: _visibleTiles.putIfAbsent(
                          key,
                          () => _loadTile(key, client),
                        ),
                        builder: (context, snapshot) {
                          final bytes = snapshot.data;
                          return bytes == null
                              ? const SizedBox.shrink()
                              : Image.memory(
                                  bytes,
                                  fit: BoxFit.fill,
                                  cacheWidth: 256,
                                  excludeFromSemantics: true,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                );
                        },
                      ),
                    ),
                  );
                }
              }
              _visibleTiles.removeWhere((key, _) => !keys.contains(key));
              _failedTiles.removeWhere((key) => !keys.contains(key));
              _retriedTiles.removeWhere((key) => !keys.contains(key));
              return Stack(clipBehavior: Clip.hardEdge, children: widgets);
            },
          ),
        if (!_enabled)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _usbSource = null;
                        _sourceError = null;
                        _enabled = true;
                      });
                      _updateActivity();
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Usar GPS del equipo'),
                  ),
                  if (Platform.isAndroid)
                    TextButton.icon(
                      onPressed: _selectUsb,
                      icon: const Icon(Icons.usb),
                      label: const Text('Usar GPS USB'),
                    ),
                  if (_sourceError != null)
                    Text(_sourceError!, textAlign: TextAlign.center),
                  const Text(
                    'OpenStreetMap recibe el área visible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      backgroundColor: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (position == null)
          Center(
            child: Text(
              _usbSource == null
                  ? 'Esperando GPS del equipo'
                  : 'Esperando señal NMEA del GPS USB',
              style: const TextStyle(
                backgroundColor: AppColors.background,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Center(
            child: Transform.rotate(
              angle:
                  position.heading.isFinite &&
                      position.heading >= 0 &&
                      position.speed.isFinite &&
                      position.speed > 1
                  ? position.heading * math.pi / 180
                  : 0,
              child: const Icon(
                Icons.navigation_rounded,
                size: 32,
                color: AppColors.accent,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        if (position != null && _mapUnavailable)
          Positioned(
            left: 8,
            bottom: 8,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
              onPressed: () => setState(() {
                _visibleTiles.removeWhere(
                  (key, _) => _failedTiles.contains(key),
                );
                _failedTiles.clear();
                _retriedTiles.clear();
                _mapUnavailable = false;
              }),
              child: const Text('Mapa sin conexión · Reintentar'),
            ),
          ),
        if (_enabled)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(
              tooltip: 'Pausar mapa',
              icon: const Icon(Icons.location_off_outlined),
              onPressed: () {
                setState(() => _enabled = false);
                _stop();
              },
            ),
          ),
        if (position != null)
          Positioned(
            top: 8,
            left: 8,
            child: Consumer<DashSettingsProvider>(
              builder: (context, settings, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    '${_usbSource == null ? 'GPS' : 'GPS USB'} · '
                    '${position.speed.isFinite && position.speed >= 0 ? settings.displaySpeed(position.speed * 3.6).round() : '—'} '
                    '${settings.speedUnitLabel}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        if (position != null)
          Positioned(
            bottom: 2,
            right: 6,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.background,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () =>
                  launchUrl(Uri.https('www.openstreetmap.org', '/copyright')),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}
