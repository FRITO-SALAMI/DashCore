import '../display_units.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/dash_settings_provider.dart';
import '../../models/gadget_config.dart';
import '../editable_gadget_wrapper.dart';
import '../dashboard_background.dart';

// ============================================================
// VIEWBOX DEL SVG — NO CAMBIAR
// ============================================================
const double _kMapViewBoxWidth = 2000;
const double _kMapViewBoxHeight = 857;
const String _kMapAssetPath = 'assets/world_map.svg';
const double _kMapLatNorth = 83.6;
const double _kMapLatSouth = -71.4;

// ============================================================
// RENDIMIENTO (mismos valores que probamos en ORBIT)
// ============================================================
const int _kTargetFps = 12;
const double _kDotStep = _kMapViewBoxWidth / 90;
const double _kActiveNodeChance = 0.985;
const Duration _kGlobeRotationPeriod = Duration(seconds: 90);
const double _kGlobeTilt = 0.32;
const double _dominicanRotation = .5 - 592.92 / _kMapViewBoxWidth;

// ============================================================
// PALETA "MAPA REAL" — a diferencia del NEONWORLD (todo teñido
// del color de acento), acá el océano y los continentes tienen
// colores propios; el acento del tema se usa solo para el brillo
// de borde, las city-lights y el pin de dato en vivo, igual que en
// el NEONWORLD original.
// ============================================================
const Color _kOceanDeep = Color(0xFF061A2E);
const Color _kOceanShallow = Color(0xFF0E3554);
const Color _kCoastline = Color(0xFFDCE8D8);

/// Dato en vivo a mostrar sobre el globo (ej: la ciudad del
/// conductor top del ranking DASHLEAGUE, o la última posición
/// registrada en Supabase). Armalo desde tu provider/stream y
/// pasalo acá — este widget no sabe nada de Supabase, solo dibuja
/// lo que le llega.
class GlobeLiveStat {
  final double lat;
  final double lon;
  final String label;
  final String value;
  final Offset? mapPoint;
  const GlobeLiveStat({
    required this.lat,
    required this.lon,
    required this.label,
    required this.value,
    this.mapPoint,
  });
}

class OrbitWorldDashboard extends StatefulWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;

  /// Dato en vivo (ej. desde un stream de Supabase realtime sobre
  /// `profiles` o la futura tabla de DASHLEAGUE). Null = no se
  /// dibuja ningún pin todavía.
  final GlobeLiveStat? liveStat;

  const OrbitWorldDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.liveStat,
  });

  @override
  State<OrbitWorldDashboard> createState() => _OrbitWorldDashboardState();
}

class _OrbitWorldDashboardState extends State<OrbitWorldDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late _ThrottledListenable _throttled;
  final Map<String, GadgetConfig> _gadgets = {
    'temp': GadgetConfig(
      id: 'temp',
      label: 'TEMPERATURA',
      relativeX: .79,
      relativeY: .05,
      relativeWidth: .17,
      relativeHeight: .17,
    ),
    'volt': GadgetConfig(
      id: 'volt',
      label: 'VOLTAJE',
      relativeX: .79,
      relativeY: .23,
      relativeWidth: .17,
      relativeHeight: .17,
    ),
    'speed': GadgetConfig(
      id: 'speed',
      label: 'VELOCIDAD',
      relativeX: .69,
      relativeY: .58,
      relativeWidth: .29,
      relativeHeight: .38,
    ),
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _throttled = _ThrottledListenable(_pulseController, _kTargetFps);
    _loadGadgets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce =
        context.watch<DashSettingsProvider>().reduceOrbitMotion ||
        MediaQuery.maybeDisableAnimationsOf(context) == true ||
        !TickerMode.of(context);
    if (reduce) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _throttled.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final accentColor = settings.accentColor;
    final lowResource = settings.isLowResourceDevice;
    final isGifBackground = settings.backgroundImage?.endsWith('.gif') ?? false;
    final useLivingStars =
        isGifBackground ||
        (settings.backgroundImage?.contains('Estrellas__bg') ?? false) ||
        settings.backgroundImage == 'ORBIT_LIVING_STARS';

    final bool isTempWarning =
        settings.tempWarningEnabled &&
        widget.coolantTemp >= settings.tempAlertThreshold;
    final bool isSpeedWarning =
        settings.speedWarningEnabled &&
        widget.speed >= settings.displaySpeedAlertThreshold;

    return Container(
      color: const Color(0xFF05000A),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (settings.backgroundImage != null && !useLivingStars)
            DashboardBackground(
              backgroundImage: settings.backgroundImage,
              isAssetBackground: settings.isAssetBackground,
              opacity: isGifBackground ? 0.4 : 0.1,
            ),
          Positioned.fill(
            child: RepaintBoundary(
              child: lowResource
                  ? CustomPaint(
                      painter: _LivingStarsPainter(
                        phase: .3,
                        accent: accentColor,
                        lowResource: true,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _throttled,
                      builder: (context, _) => CustomPaint(
                        painter: _LivingStarsPainter(
                          phase: _throttled.value,
                          accent: accentColor,
                          lowResource: lowResource,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _NeonGridPainter(color: accentColor.withOpacity(0.04)),
              ),
            ),
          ),

          Positioned.fill(
            child: RepaintBoundary(
              child: _GlobeWidget(
                accent: accentColor,
                lowResource: lowResource,
                pulse: _throttled,
                liveStat: widget.liveStat ?? _dominicanMarker,
                landColor: settings.needleColor,
                reducedMotion: settings.reduceOrbitMotion,
              ),
            ),
          ),

          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: _gadgets.values.map((config) {
                  return Positioned(
                    left: config.relativeX * constraints.maxWidth,
                    top: config.relativeY * constraints.maxHeight,
                    width: config.relativeWidth * constraints.maxWidth,
                    height: config.relativeHeight * constraints.maxHeight,
                    child: EditableGadgetWrapper(
                      config: config,
                      isEditMode: settings.isEditMode,
                      parentSize: constraints.biggest,
                      onConfigChanged: (updated) {
                        setState(() => _gadgets[updated.id] = updated);
                      },
                      onConfigChangeEnd: _saveGadgets,
                      onTapEdit: () => _editTypography(config),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(config.fontScale),
                        ),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(fontFamily: config.fontFamily),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: config.id == 'temp'
                                ? _TempGauge(
                                    temp: widget.coolantTemp,
                                    color: accentColor,
                                    isWarning: isTempWarning,
                                  )
                                : config.id == 'volt'
                                ? _VoltageDisplay(
                                    voltage: widget.voltage,
                                    color: accentColor,
                                  )
                                : _NeonSpeedometer(
                                    speed: widget.speed,
                                    color: accentColor,
                                    isWarning: isSpeedWarning,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _dominicanMarker = GlobeLiveStat(
    lat: 18.35,
    lon: -70.15,
    // Centro medido del contorno DO en world_map.svg. Ese recurso usa
    // una proyección ilustrada, no latitud/longitud lineal.
    mapPoint: Offset(592.92, 381.59),
    label: 'REP. DOMINICANA',
    value: 'RD',
  );

  Future<void> _loadGadgets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('orbit_world_gadgets_v4');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      if (!mounted) return;
      setState(() {
        for (final item in decoded.whereType<Map>()) {
          final config = GadgetConfig.fromJson(Map<String, dynamic>.from(item));
          if (_gadgets.containsKey(config.id)) _gadgets[config.id] = config;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveGadgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'orbit_world_gadgets_v4',
      jsonEncode(_gadgets.values.map((g) => g.toJson()).toList()),
    );
  }

  Future<void> _editTypography(GadgetConfig config) async {
    final result = await showDialog<GadgetConfig>(
      context: context,
      builder: (context) {
        var scale = config.fontScale.clamp(.7, 1.5);
        const fonts = ['Inter', 'Roboto', 'monospace'];
        var family = fonts.contains(config.fontFamily)
            ? config.fontFamily
            : fonts.first;
        var locked = config.locked;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF0A1220),
            title: Text(
              config.label,
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: family,
                    dropdownColor: const Color(0xFF0A1220),
                    style: const TextStyle(color: Colors.white),
                    items: fonts
                        .map(
                          (font) =>
                              DropdownMenuItem(value: font, child: Text(font)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => family = value ?? family),
                  ),
                  Slider(
                    value: scale,
                    min: .7,
                    max: 1.5,
                    divisions: 8,
                    label: '${(scale * 100).round()}%',
                    onChanged: (value) => setDialogState(() => scale = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bloquear posición y tamaño'),
                    value: locked,
                    onChanged: (value) => setDialogState(() => locked = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  config.copyWith(
                    fontScale: scale,
                    fontFamily: family,
                    locked: locked,
                  ),
                ),
                child: const Text('APLICAR'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _gadgets[result.id] = result);
      await _saveGadgets();
    }
  }
}

// ============================================================
// THROTTLE (idéntico a ORBIT)
// ============================================================
class _ThrottledListenable extends ChangeNotifier {
  final Animation<double> source;
  final int fps;
  final Stopwatch _clock = Stopwatch()..start();
  int _previous = 0;
  double _value = 0;

  _ThrottledListenable(this.source, this.fps) {
    _value = source.value;
    source.addListener(_tick);
  }

  void _tick() {
    final now = _clock.elapsedMicroseconds;
    if (now - _previous < 1000000 / fps - 2000 || _value == source.value)
      return;
    _previous = now;
    _value = source.value;
    notifyListeners();
  }

  double get value => _value;

  @override
  void dispose() {
    source.removeListener(_tick);
    super.dispose();
  }
}

class _NeonGridPainter extends CustomPainter {
  final Color color;
  _NeonGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LivingStarsPainter extends CustomPainter {
  const _LivingStarsPainter({
    required this.phase,
    required this.accent,
    required this.lowResource,
  });

  final double phase;
  final Color accent;
  final bool lowResource;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42017);
    final count = lowResource ? 65 : 120;
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starPhase = random.nextDouble() * math.pi * 2;
      final wave = (math.sin(phase * math.pi * 2 + starPhase) + 1) / 2;
      final radius = .45 + random.nextDouble() * 1.15;
      final color = i % 7 == 0 ? accent : const Color(0xFFDCEFFF);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withOpacity(.18 + wave * .70),
      );
      if (!lowResource && i % 18 == 0) {
        canvas.drawCircle(
          Offset(x, y),
          radius * 2.8,
          Paint()
            ..color = color.withOpacity(.10 + wave * .10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LivingStarsPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.accent != accent ||
      oldDelegate.lowResource != lowResource;
}

// ============================================================
// DATOS DEL MAPA (parseo del SVG una sola vez — igual que ORBIT)
// ============================================================
class _MapRegion {
  final Path path;
  final double density;
  const _MapRegion({required this.path, required this.density});
}

class _MapDot {
  final Offset lonLat;
  final double phase;
  final bool active;
  const _MapDot({
    required this.lonLat,
    required this.phase,
    required this.active,
  });
}

class _RegionGlobe {
  final List<List<Offset>> contours;
  const _RegionGlobe(this.contours);
}

class _WorldMapData {
  static List<_MapRegion>? regions;
  static List<_MapDot>? dots;
  static List<_RegionGlobe>? globeRegions;

  static bool get isReady =>
      regions != null && dots != null && globeRegions != null;

  static Offset _viewboxToLonLat(Offset p) {
    final lon = (p.dx / _kMapViewBoxWidth) * 360 - 180;
    final lat =
        _kMapLatNorth -
        (p.dy / _kMapViewBoxHeight) * (_kMapLatNorth - _kMapLatSouth);
    return Offset(lon, lat);
  }

  static Future<void> load({required bool lowResource}) async {
    if (isReady) return;
    final raw = await rootBundle.loadString(_kMapAssetPath);
    final parsedRegions = _parseSvg(raw);
    regions = parsedRegions;
    dots = _generateDots(parsedRegions);

    final sampleStep = lowResource ? 14.0 : 7.0;
    globeRegions = parsedRegions
        .map((r) => _RegionGlobe(_extractLonLatContours(r.path, sampleStep)))
        .toList();
  }

  static List<List<Offset>> _extractLonLatContours(Path path, double step) {
    final out = <List<Offset>>[];
    for (final metric in path.computeMetrics()) {
      final pts = <Offset>[];
      var d = 0.0;
      while (d < metric.length) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) pts.add(_viewboxToLonLat(tangent.position));
        d += step;
      }
      if (pts.length > 2) out.add(pts);
    }
    return out;
  }

  static final RegExp _pathTagRe = RegExp(r'<path\b([^>]*)/?>');
  static final RegExp _dAttrRe = RegExp(r'\bd="([^"]*)"');
  static final RegExp _nameAttrRe = RegExp(r'\bname="([^"]*)"');
  static final RegExp _classAttrRe = RegExp(r'\bclass="([^"]*)"');

  static List<_MapRegion> _parseSvg(String svg) {
    final byCountry = <String, Path>{};
    for (final match in _pathTagRe.allMatches(svg)) {
      final attrs = match.group(1)!;
      final dMatch = _dAttrRe.firstMatch(attrs);
      if (dMatch == null) continue;
      final name =
          _nameAttrRe.firstMatch(attrs)?.group(1) ??
          _classAttrRe.firstMatch(attrs)?.group(1) ??
          'unknown';
      final subPath = _parseSimplePathData(dMatch.group(1)!);
      final path = byCountry.putIfAbsent(name, () => Path());
      path.addPath(subPath, Offset.zero);
    }
    return byCountry.entries
        .map((e) => _MapRegion(path: e.value, density: _densityFor(e.key)))
        .toList();
  }

  static Path _parseSimplePathData(String d) {
    final path = Path();
    final tokens = RegExp(
      r'[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?|[MmLlZz]',
    ).allMatches(d).map((m) => m.group(0)!).toList();
    int i = 0;
    String cmd = 'M';
    double x = 0, y = 0, startX = 0, startY = 0;
    bool started = false;
    double nextNum() => double.parse(tokens[i++]);

    while (i < tokens.length) {
      final t = tokens[i];
      final isCmd = RegExp(r'^[MmLlZz]$').hasMatch(t);
      if (isCmd) {
        cmd = t;
        i++;
        continue;
      }
      switch (cmd) {
        case 'M':
        case 'm':
          final nx = nextNum();
          final ny = nextNum();
          x = cmd == 'm' ? x + nx : nx;
          y = cmd == 'm' ? y + ny : ny;
          path.moveTo(x, y);
          startX = x;
          startY = y;
          started = true;
          cmd = cmd == 'm' ? 'l' : 'L';
          break;
        case 'L':
        case 'l':
          final nx = nextNum();
          final ny = nextNum();
          x = cmd == 'l' ? x + nx : nx;
          y = cmd == 'l' ? y + ny : ny;
          if (!started) {
            path.moveTo(x, y);
            started = true;
          } else {
            path.lineTo(x, y);
          }
          break;
        case 'Z':
        case 'z':
          path.close();
          x = startX;
          y = startY;
          i++;
          break;
        default:
          i++;
      }
    }
    return path;
  }

  static const _highDensity = {
    'United States',
    'China',
    'India',
    'Japan',
    'Republic of Korea',
    'Dem. Rep. Korea',
    'United Kingdom',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Netherlands',
    'Belgium',
    'Nigeria',
    'Indonesia',
    'Brazil',
    'Mexico',
    'Philippines',
    'Vietnam',
    'Bangladesh',
    'Pakistan',
    'Thailand',
    'Taiwan',
    'Poland',
    'Turkey',
    'Egypt',
    'Colombia',
  };
  static const _lowDensity = {
    'Greenland',
    'Canada',
    'Russian Federation',
    'Australia',
    'Mongolia',
    'Kazakhstan',
    'Algeria',
    'Libya',
    'Chad',
    'Niger',
    'Mali',
    'Mauritania',
    'Sudan',
    'South Sudan',
    'Namibia',
    'Botswana',
    'Western Sahara',
    'Saudi Arabia',
    'Oman',
    'Iceland',
    'Suriname',
    'French Guiana',
    'Guyana',
    'Papua New Guinea',
  };

  static double _densityFor(String country) {
    if (_highDensity.contains(country)) return 0.95;
    if (_lowDensity.contains(country)) return 0.32;
    return 0.72;
  }

  static List<_MapDot> _generateDots(List<_MapRegion> regions) {
    final result = <_MapDot>[];
    final random = math.Random(241986);
    const step = _kDotStep;

    for (double x = 0; x < _kMapViewBoxWidth; x += step) {
      for (double y = 0; y < _kMapViewBoxHeight; y += step) {
        final point = Offset(
          x + (random.nextDouble() - 0.5) * step * 0.85,
          y + (random.nextDouble() - 0.5) * step * 0.85,
        );
        _MapRegion? region;
        for (final candidate in regions) {
          if (candidate.path.contains(point)) {
            region = candidate;
            break;
          }
        }
        if (region == null) continue;
        final probability = region.density * (0.6 + random.nextDouble() * 0.4);
        if (random.nextDouble() < probability) {
          result.add(
            _MapDot(
              lonLat: _viewboxToLonLat(point),
              phase: random.nextDouble() * math.pi * 2,
              active: random.nextDouble() > _kActiveNodeChance,
            ),
          );
        }
      }
    }
    return result;
  }
}

// ============================================================
// PROYECCIÓN ORTOGRÁFICA
// ============================================================
Offset? _projectLonLat(
  Offset lonLat,
  Offset center,
  double radius,
  double sinRotation,
  double cosRotation,
) {
  final point = _spherePoints[lonLat] ??= _spherePoint(lonLat);
  final x0 = point.$1 * cosRotation + point.$3 * sinRotation;
  final z0 = point.$3 * cosRotation - point.$1 * sinRotation;
  final y = point.$2 * _cosTilt - z0 * _sinTilt;
  final z = point.$2 * _sinTilt + z0 * _cosTilt;
  if (z < -0.05) return null;
  return Offset(center.dx + radius * x0, center.dy - radius * y);
}

final _sinTilt = math.sin(_kGlobeTilt);
final _cosTilt = math.cos(_kGlobeTilt);
final _spherePoints = Expando<(double, double, double)>();

(double, double, double) _spherePoint(Offset point) {
  final longitude = point.dx * math.pi / 180;
  final latitude = point.dy * math.pi / 180;
  final cosLatitude = math.cos(latitude);
  return (
    cosLatitude * math.sin(longitude),
    math.sin(latitude),
    cosLatitude * math.cos(longitude),
  );
}

// ============================================================
// PINTADO ESTÁTICO DEL GLOBO — colores de mapa real, no monocromo
// ============================================================
void _paintGlobeStatic(
  Canvas canvas,
  Size size,
  Color accent,
  Color landColor,
  double rot,
  bool lowResource,
) {
  final center = Offset(size.width * .35, size.height * .5);
  // Deliberately oversized: the sphere is cropped by the physical display,
  // creating the illusion that it continues beyond the dashboard.
  final radius = math.min(size.width, size.height) * .64;
  final lightPoint = Offset(center.dx - radius * .42, center.dy - radius * .48);
  final globeRect = Rect.fromCircle(center: center, radius: radius);

  canvas.save();
  canvas.clipPath(Path()..addOval(globeRect));

  // Océano: gradiente azul profundo real, no teñido de acento.
  canvas.drawRect(
    globeRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.34, -.4),
        radius: 1.15,
        colors: const [_kOceanShallow, _kOceanDeep, Color(0xFF020810)],
        stops: const [0, .6, 1],
      ).createShader(globeRect),
  );

  // Graticule (meridianos/paralelos) en un celeste tenue, como un
  // mapa de referencia real, no el color de acento del auto.
  /*
  // Graticule (meridianos/paralelos) ocultos por solicitud del usuario
  final grid = Paint()
    ..color = accent.withOpacity(lowResource ? .20 : .30)
    ..style = PaintingStyle.stroke
    ..strokeWidth = lowResource ? .6 : .8;
  for (var lat = -75; lat <= 75; lat += 15) {
    final latRad = lat * math.pi / 180;
    final y = center.dy - radius * math.sin(latRad) * math.cos(_kGlobeTilt);
    final rx = radius * math.cos(latRad);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, y),
        width: rx * 2,
        height: math.max(2, rx * .14),
      ),
      grid,
    );
  }
  */
  // Continentes reales (del SVG) en verde/tierra + costa clara.
  final landFill = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(landColor, Colors.white, .20)!, landColor],
    ).createShader(globeRect);
  final landStroke = Paint()
    ..color = Color.lerp(_kCoastline, accent, .72)!.withOpacity(.82)
    ..style = PaintingStyle.stroke
    ..strokeWidth = lowResource ? .7 : .9;

  final globeRegions = _WorldMapData.globeRegions ?? const [];
  final sinRotation = math.sin(rot);
  final cosRotation = math.cos(rot);
  for (final region in globeRegions) {
    for (final contour in region.contours) {
      Path? path;
      Offset? prev;
      for (final lonLat in contour) {
        final p = _projectLonLat(
          lonLat,
          center,
          radius,
          sinRotation,
          cosRotation,
        );
        if (p == null) {
          if (path != null) {
            canvas.drawPath(path, landFill);
            canvas.drawPath(path, landStroke);
          }
          path = null;
          prev = null;
          continue;
        }
        if (path == null) {
          path = Path()..moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        prev = p;
      }
      if (path != null && prev != null) {
        canvas.drawPath(path, landFill);
        canvas.drawPath(path, landStroke);
      }
    }
  }

  // Sombreado esférico (día/noche), en multiply, igual que ORBIT.
  canvas.drawRect(
    globeRect,
    Paint()
      ..blendMode = BlendMode.multiply
      ..shader = const RadialGradient(
        center: Alignment(-.42, -.48),
        radius: 1.35,
        colors: [
          Colors.white,
          Color(0xFFB8C4D8),
          Color(0xFF222A39),
          Color(0xFF05070C),
        ],
        stops: [0, .38, .78, 1],
      ).createShader(globeRect),
  );

  canvas.drawCircle(
    lightPoint,
    radius * .2,
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(.14), Colors.white.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: lightPoint, radius: radius * .2)),
  );

  canvas.restore();

  // El borde exterior sí lleva el color de acento del tema — es lo
  // que conecta el globo "realista" con la identidad del dashboard.
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = accent.withOpacity(.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );

  if (!lowResource) {
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = accent.withOpacity(.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
}

// ============================================================
// CACHE DE FRAMES (idéntico enfoque a ORBIT: se hornea la rotación)
// ============================================================
// ============================================================
// WIDGET DEL GLOBO
// ============================================================
class _GlobeWidget extends StatefulWidget {
  final Color accent;
  final bool lowResource;
  final _ThrottledListenable pulse;
  final GlobeLiveStat? liveStat;
  final Color landColor;
  final bool reducedMotion;

  const _GlobeWidget({
    required this.accent,
    required this.lowResource,
    required this.pulse,
    required this.liveStat,
    required this.landColor,
    required this.reducedMotion,
  });

  @override
  State<_GlobeWidget> createState() => _GlobeWidgetState();
}

class _GlobeWidgetState extends State<_GlobeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final _ThrottledListenable _rotationPaint;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: _kGlobeRotationPeriod,
      value: _dominicanRotation,
    );
    _rotationPaint = _ThrottledListenable(
      _rotationController,
      widget.lowResource ? 30 : 60,
    );
    _loadMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateRotation();
  }

  @override
  void didUpdateWidget(covariant _GlobeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) _updateRotation();
  }

  void _updateRotation() {
    final reduce =
        widget.reducedMotion ||
        MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (reduce || !TickerMode.of(context)) {
      _rotationController.stop();
      if (reduce) _rotationController.value = _dominicanRotation;
    } else if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }
  }

  Future<void> _loadMap() async {
    await _WorldMapData.load(lowResource: widget.lowResource);
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _rotationPaint.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationPaint,
      builder: (context, _) => CustomPaint(
        painter: _GlobeDynamicPainter(
          accent: widget.accent,
          ready: _ready,
          lowResource: widget.lowResource,
          rotationProgress: _rotationController.value,
          pulseT: widget.pulse.value,
          liveStat: widget.liveStat,
          landColor: widget.landColor,
        ),
      ),
    );
  }
}

class _GlobeDynamicPainter extends CustomPainter {
  final Color accent;
  final bool ready;
  final bool lowResource;
  final double rotationProgress;
  final double pulseT;
  final GlobeLiveStat? liveStat;
  final Color landColor;

  _GlobeDynamicPainter({
    required this.accent,
    required this.ready,
    required this.lowResource,
    required this.rotationProgress,
    required this.pulseT,
    required this.liveStat,
    required this.landColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!ready) return;
    final rot = rotationProgress * math.pi * 2;
    _paintGlobeStatic(canvas, size, accent, landColor, rot, lowResource);

    final center = Offset(size.width * .35, size.height * .5);
    final radius = math.min(size.width, size.height) * .64;
    final sinRotation = math.sin(rot);
    final cosRotation = math.cos(rot);
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dots = _WorldMapData.dots ?? const [];
    for (final dot in dots) {
      final pos = _projectLonLat(
        dot.lonLat,
        center,
        radius,
        sinRotation,
        cosRotation,
      );
      if (pos == null) continue;
      final wave = math.sin(pulseT * math.pi * 2 + dot.phase);
      final pulse = (0.15 + ((wave + 1) / 2) * 0.45).clamp(0.07, 0.62);
      dotPaint.color = accent.withOpacity(pulse);
      canvas.drawCircle(pos, dot.active ? 1.3 : 0.75, dotPaint);
    }

    // ------------------------------------------------------
    // PIN DE DATO EN VIVO
    // Se proyecta con la rotación exacta de este frame (no está
    // horneado en el cache, porque el dato puede cambiar en
    // cualquier momento sin depender del ángulo de giro).
    // ------------------------------------------------------
    final stat = liveStat;
    if (stat != null) {
      final markerLonLat = stat.mapPoint == null
          ? Offset(stat.lon, stat.lat)
          : _WorldMapData._viewboxToLonLat(stat.mapPoint!);
      final pos = _projectLonLat(
        markerLonLat,
        center,
        radius,
        sinRotation,
        cosRotation,
      );

      if (pos != null) {
        final adjustedPos = pos;
        final pulse = (math.sin(pulseT * math.pi * 2) + 1) / 2;

        final ring = Paint()
          ..color = accent.withOpacity(0.25 + pulse * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(adjustedPos, 6 + pulse * 6, ring);

        final glow = Paint()..color = accent.withOpacity(0.18 + pulse * .18);
        canvas.drawCircle(adjustedPos, 4, glow);

        final dot = Paint()..color = Colors.white;
        canvas.drawCircle(adjustedPos, 2.6, dot);

        _drawLiveStatCallout(canvas, adjustedPos, stat, accent);
      }
    }
  }

  void _drawLiveStatCallout(
    Canvas canvas,
    Offset pin,
    GlobeLiveStat stat,
    Color accent,
  ) {
    final labelStyle = TextStyle(
      color: accent,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );
    final valueStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );

    final labelTp = TextPainter(
      text: TextSpan(text: stat.label.toUpperCase(), style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final valueTp = TextPainter(
      text: TextSpan(text: stat.value, style: valueStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final boxWidth = math.max(labelTp.width, valueTp.width) + 16;
    final boxHeight = labelTp.height + valueTp.height + 10;
    final boxOrigin = Offset(pin.dx + 10, pin.dy - boxHeight - 6);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxOrigin.dx, boxOrigin.dy, boxWidth, boxHeight),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFF0A0212).withOpacity(0.85),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = accent.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    labelTp.paint(canvas, Offset(boxOrigin.dx + 8, boxOrigin.dy + 5));
    valueTp.paint(
      canvas,
      Offset(boxOrigin.dx + 8, boxOrigin.dy + 5 + labelTp.height + 2),
    );

    canvas.drawLine(
      pin,
      boxOrigin + Offset(0, boxHeight),
      Paint()
        ..color = accent.withOpacity(0.4)
        ..strokeWidth = 1,
    );
    labelTp.dispose();
    valueTp.dispose();
  }

  @override
  bool shouldRepaint(covariant _GlobeDynamicPainter oldDelegate) =>
      oldDelegate.ready != ready ||
      oldDelegate.accent != accent ||
      oldDelegate.rotationProgress != rotationProgress ||
      oldDelegate.landColor != landColor ||
      oldDelegate.pulseT != pulseT ||
      oldDelegate.liveStat != liveStat;
}

// ============================================================
// TEMPERATURE
// ============================================================
class _TempGauge extends StatefulWidget {
  final int temp;
  final Color color;
  final bool isWarning;
  const _TempGauge({
    required this.temp,
    required this.color,
    this.isWarning = false,
  });

  @override
  State<_TempGauge> createState() => _TempGaugeState();
}

class _TempGaugeState extends State<_TempGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isWarning) _blinkController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TempGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWarning && !oldWidget.isWarning) {
      _blinkController.repeat(reverse: true);
    } else if (!widget.isWarning && oldWidget.isWarning) {
      _blinkController.stop();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final opacity = widget.isWarning ? _blinkController.value : 1.0;
        final displayColor = widget.isWarning ? Colors.redAccent : widget.color;
        return Opacity(
          opacity: widget.isWarning ? (0.3 + 0.7 * opacity) : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.thermostat_rounded,
                      color: displayColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                  Text(
                    '${widget.temp}',
                    style: TextStyle(
                      color: widget.isWarning ? Colors.redAccent : Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    '°C',
                    style: TextStyle(
                      color: displayColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'TEMPERATURA',
                style: TextStyle(
                  color: widget.isWarning
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// VOLTAGE
// ============================================================
class _VoltageDisplay extends StatelessWidget {
  final double voltage;
  final Color color;
  const _VoltageDisplay({required this.voltage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.bolt_rounded, color: color.withOpacity(0.7), size: 24),
        const SizedBox(width: 4),
        Text(
          voltage.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'V',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SPEEDOMETER
// ============================================================
class _NeonSpeedometer extends StatefulWidget {
  final int speed;
  final Color color;
  final bool isWarning;
  const _NeonSpeedometer({
    required this.speed,
    required this.color,
    this.isWarning = false,
  });

  @override
  State<_NeonSpeedometer> createState() => _NeonSpeedometerState();
}

class _NeonSpeedometerState extends State<_NeonSpeedometer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isWarning) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _NeonSpeedometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWarning && !oldWidget.isWarning) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isWarning && oldWidget.isWarning) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = widget.isWarning ? Colors.redAccent : widget.color;
    final maximum = speedUnitOf(context).toUpperCase() == 'MPH' ? 160 : 240;
    final double scale = widget.isWarning ? 1.15 : 1.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = widget.isWarning ? _pulseController.value : 0.0;
        return AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: scale,
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isWarning)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(
                            0.2 * glowIntensity,
                          ),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _SpeedoPainter(
                    speed: widget.speed,
                    maximum: maximum,
                    color: displayColor,
                    glowPulse: glowIntensity,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.speed}',
                      style: TextStyle(
                        color: widget.isWarning
                            ? Colors.redAccent
                            : Colors.white,
                        fontSize: widget.isWarning ? 94 : 84,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SpeedUnitLabel(
                      style: TextStyle(
                        color: displayColor.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpeedoPainter extends CustomPainter {
  final int speed;
  final int maximum;
  final Color color;
  final double glowPulse;
  _SpeedoPainter({
    required this.speed,
    required this.maximum,
    required this.color,
    this.glowPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final progress = (speed / maximum).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 + (glowPulse * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + (glowPulse * 4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + (glowPulse * 5));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedoPainter oldDelegate) =>
      oldDelegate.speed != speed ||
      oldDelegate.maximum != maximum ||
      oldDelegate.glowPulse != glowPulse ||
      oldDelegate.color != color;
}

// ============================================================
// INDICATORS
// ============================================================
class _IndicatorIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IndicatorIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Icon(icon, color: color, size: 18);
}
