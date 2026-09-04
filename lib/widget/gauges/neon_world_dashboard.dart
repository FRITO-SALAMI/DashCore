import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../music_hub.dart';
import '../../providers/music_provider.dart';
import '../../providers/dash_settings_provider.dart';
import '../dashboard_background.dart';

// ============================================================
// VIEWBOX DEL SVG (world_map.svg) — NO CAMBIAR
// ============================================================
const double _kMapViewBoxWidth = 2000;
const double _kMapViewBoxHeight = 857;
const String _kMapAssetPath = 'assets/world_map.svg';

// ============================================================
// AJUSTES DE RENDIMIENTO
// Bajalos más si el dispositivo sigue lento.
// ============================================================
const int _kTargetFps = 24;           // antes: 15fps
const double _kDotStep =
    _kMapViewBoxWidth / 90;           // antes: /140 -> menos dots
const double _kActiveNodeChance = 0.985; // igual, pero sobre menos dots
const bool _kDrawDotGlow = false;     // el blur por-dot es lo más caro

class NeonWorldDashboard extends StatefulWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;

  const NeonWorldDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
  });

  @override
  State<NeonWorldDashboard> createState() => _NeonWorldDashboardState();
}

class _NeonWorldDashboardState extends State<NeonWorldDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late _ThrottledListenable _throttled;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // En vez de escuchar el controller directo (que notifica en cada
    // vsync tick, ~60/seg), lo envolvemos para que solo dispare
    // repaint a _kTargetFps. El pulso sigue viéndose suave.
    _throttled = _ThrottledListenable(_controller, _kTargetFps);

    if (!_WorldMapData.isReady) {
      _WorldMapData.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _throttled.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final music = context.watch<MusicProvider>();

    final accentColor = settings.accentColor;
    final mapColor = accentColor;
    final isGifBackground = settings.backgroundImage?.endsWith('.gif') ?? false;

    // Warning states
    final bool isTempWarning = settings.tempWarningEnabled && widget.coolantTemp >= settings.tempAlertThreshold;
    final bool isSpeedWarning = settings.speedWarningEnabled && widget.speed >= settings.speedAlertThreshold;

    return Container(
      color: const Color(0xFF05000A),
      child: Stack(
        children: [
          if (settings.backgroundImage != null)
            DashboardBackground(
              backgroundImage: settings.backgroundImage,
              isAssetBackground: settings.isAssetBackground,
              opacity: isGifBackground ? 0.4 : 0.1,
            ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _NeonGridPainter(
                  color: mapColor.withOpacity(0.04),
                ),
              ),
            ),
          ),

          // WORLD MAP
          Center(
            child: AspectRatio(
              aspectRatio: _kMapViewBoxWidth / _kMapViewBoxHeight,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: _CachedWorldMap(
                  color: accentColor,
                  animation: _throttled,
                ),
              ),
            ),
          ),

          Positioned(
            top: 30,
            left: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TempGauge(
                  temp: widget.coolantTemp,
                  color: accentColor,
                  isWarning: isTempWarning,
                ),
                const SizedBox(height: 20),
                _VoltageDisplay(voltage: widget.voltage, color: accentColor),
              ],
            ),
          ),

          Positioned(
            bottom: 40,
            left: 30,
            child: MusicHub(accentColor: accentColor, width: 260, compact: true),
          ),

          Positioned(
            bottom: 40,
            right: 40,
            child: _NeonSpeedometer(
              speed: widget.speed,
              color: accentColor,
              isWarning: isSpeedWarning,
            ),
          ),

          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IndicatorIcon(icon: Icons.light_mode_outlined, color: Colors.white12),
                const SizedBox(width: 25),
                _IndicatorIcon(icon: Icons.battery_std_rounded, color: Colors.white12),
                const SizedBox(width: 25),
                _IndicatorIcon(icon: Icons.oil_barrel_outlined, color: Colors.white12),
                const SizedBox(width: 25),
                _IndicatorIcon(icon: Icons.airline_seat_recline_normal_rounded, color: Colors.white12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// THROTTLE: reduce la frecuencia de repaint sin tocar la duración
// de la animación (el pulso se ve igual de suave a ~15fps).
// ============================================================
class _ThrottledListenable extends ChangeNotifier {
  final Animation<double> source;
  final int fps;
  Timer? _timer;
  double _value = 0;

  _ThrottledListenable(this.source, this.fps) {
    _value = source.value;
    _timer = Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (_) {
      _value = source.value;
      notifyListeners();
    });
  }

  double get value => _value;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ============================================================
// BACKGROUND GRID
// ============================================================
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

// ============================================================
// DATOS DEL MAPA (se parsean/generan una sola vez)
// ============================================================
class _MapRegion {
  final Path path;
  final double density;
  const _MapRegion({required this.path, required this.density});
}

class _MapDot {
  final Offset position;
  final double phase;
  final bool active;
  const _MapDot({required this.position, required this.phase, required this.active});
}

class _WorldMapData {
  static List<_MapRegion>? regions;
  static List<_MapDot>? dots;
  static bool get isReady => regions != null && dots != null;

  static Future<void> load() async {
    if (isReady) return;
    final raw = await rootBundle.loadString(_kMapAssetPath);
    final parsedRegions = _parseSvg(raw);
    regions = parsedRegions;
    dots = _generateDots(parsedRegions);
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
      final name = _nameAttrRe.firstMatch(attrs)?.group(1) ??
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
    final tokens = RegExp(r'[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?|[MmLlZz]')
        .allMatches(d)
        .map((m) => m.group(0)!)
        .toList();

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
    'United States', 'China', 'India', 'Japan', 'Republic of Korea',
    'Dem. Rep. Korea', 'United Kingdom', 'Germany', 'France', 'Italy',
    'Spain', 'Netherlands', 'Belgium', 'Nigeria', 'Indonesia', 'Brazil',
    'Mexico', 'Philippines', 'Vietnam', 'Bangladesh', 'Pakistan',
    'Thailand', 'Taiwan', 'Poland', 'Turkey', 'Egypt', 'Colombia',
  };

  static const _lowDensity = {
    'Greenland', 'Canada', 'Russian Federation', 'Australia', 'Mongolia',
    'Kazakhstan', 'Algeria', 'Libya', 'Chad', 'Niger', 'Mali',
    'Mauritania', 'Sudan', 'South Sudan', 'Namibia', 'Botswana',
    'Western Sahara', 'Saudi Arabia', 'Oman', 'Iceland', 'Suriname',
    'French Guiana', 'Guyana', 'Papua New Guinea',
  };

  static double _densityFor(String country) {
    if (_highDensity.contains(country)) return 0.95;
    if (_lowDensity.contains(country)) return 0.32;
    return 0.72;
  }

  // step más grande = menos dots = menos costo por frame
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
          result.add(_MapDot(
            position: point,
            phase: random.nextDouble() * math.pi * 2,
            active: random.nextDouble() > _kActiveNodeChance,
          ));
        }
      }
    }
    return result;
  }
}

// ============================================================
// CAPA ESTÁTICA CACHEADA COMO IMAGEN
//
// Todo lo que NO cambia entre frames (grid oceánico, atmósfera,
// relleno de continentes, glow de costa, coastline nítido) se
// dibuja UNA sola vez con un PictureRecorder y se convierte a un
// ui.Image. Cada frame después solo hace canvas.drawImage(), que
// es un blit — órdenes de magnitud más barato que repintar 414
// paths con blur cada vez.
// ============================================================
class _StaticMapCache {
  static ui.Image? image;
  static Size? forSize;
  static Color? forColor;
  static Future<ui.Image>? _pending;

  static Future<ui.Image> get(Size size, Color color) {
    if (image != null && forSize == size && forColor == color) {
      return Future.value(image!);
    }
    return _pending ??= _build(size, color).then((img) {
      image = img;
      forSize = size;
      forColor = color;
      _pending = null;
      return img;
    });
  }

  static Future<ui.Image> _build(Size size, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = size.width / _kMapViewBoxWidth;
    canvas.scale(scale, scale);

    _paintStatic(canvas, color, scale);

    final picture = recorder.endRecording();
    return picture.toImage(size.width.ceil(), size.height.ceil());
  }

  static void _paintStatic(Canvas canvas, Color color, double scale) {
    final regions = _WorldMapData.regions!;

    _drawOceanGrid(canvas, color, scale);

    // Atmósfera: como ahora se "hornea" una sola vez, el blur ya
    // no cuesta nada en runtime — se puede dejar tal cual.
    final atmosphere = Paint()
      ..color = color.withOpacity(0.02)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 / scale);
    canvas.drawRect(
      Rect.fromLTWH(
        _kMapViewBoxWidth * 0.015,
        _kMapViewBoxHeight * 0.07,
        _kMapViewBoxWidth * 0.97,
        _kMapViewBoxHeight * 0.86,
      ),
      atmosphere,
    );

    for (final region in regions) {
      final fill = Paint()
        ..color = color.withOpacity(0.025)
        ..style = PaintingStyle.fill;
      canvas.drawPath(region.path, fill);
    }

    for (final region in regions) {
      final glow = Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 / scale);
      canvas.drawPath(region.path, glow);
    }

    for (final region in regions) {
      final outline = Paint()
        ..color = color.withOpacity(0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(region.path, outline);
    }
  }

  static void _drawOceanGrid(Canvas canvas, Color color, double scale) {
    final grid = Paint()
      ..color = color.withOpacity(0.032)
      ..strokeWidth = 0.42 / scale
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      final y = _kMapViewBoxHeight * 0.12 + i * _kMapViewBoxHeight * 0.085;
      canvas.drawLine(
        Offset(_kMapViewBoxWidth * 0.015, y),
        Offset(_kMapViewBoxWidth * 0.985, y),
        grid,
      );
    }
    for (int i = -12; i <= 12; i++) {
      final x = _kMapViewBoxWidth / 2 + i * _kMapViewBoxWidth * 0.045;
      canvas.drawLine(
        Offset(x, _kMapViewBoxHeight * 0.06),
        Offset(x, _kMapViewBoxHeight * 0.94),
        grid,
      );
    }

    final floorPaint = Paint()
      ..color = color.withOpacity(0.025)
      ..strokeWidth = 0.4 / scale;
    final horizon = _kMapViewBoxHeight * 0.78;
    for (int i = 0; i < 9; i++) {
      final t = i / 9;
      final y = horizon + math.pow(t, 1.8).toDouble() * _kMapViewBoxHeight * 0.18;
      canvas.drawLine(Offset(0, y), Offset(_kMapViewBoxWidth, y), floorPaint);
    }
  }
}

// ============================================================
// WIDGET QUE ARMA capa estática (imagen cacheada) + capa dinámica
// ============================================================
class _CachedWorldMap extends StatefulWidget {
  final Color color;
  final _ThrottledListenable animation;

  const _CachedWorldMap({required this.color, required this.animation});

  @override
  State<_CachedWorldMap> createState() => _CachedWorldMapState();
}

class _CachedWorldMapState extends State<_CachedWorldMap> {
  ui.Image? _cachedImage;
  Size? _requestedSize;

  @override
  void didUpdateWidget(covariant _CachedWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _cachedImage = null; // Invalidate cache on color change
      if (_requestedSize != null) _ensureImage(_requestedSize!);
    }
  }

  void _ensureImage(Size size) {
    if (_WorldMapData.regions == null) return;
    if (_requestedSize == size && _cachedImage != null) return;
    _requestedSize = size;
    _StaticMapCache.get(size, widget.color).then((img) {
      if (mounted && _requestedSize == size) {
        setState(() => _cachedImage = img);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width > 0 && size.height > 0) {
          _ensureImage(size);
        }
        return CustomPaint(
          painter: _DynamicMapPainter(
            color: widget.color,
            staticImage: _cachedImage,
            animation: widget.animation,
          ),
        );
      },
    );
  }
}

// ============================================================
// CAPA DINÁMICA: dibuja la imagen estática (blit barato) + solo
// los dots pulsantes y los nodos de ciudades mayores, que sí
// cambian cada frame. Sin blur salvo en los pocos nodos activos.
// ============================================================
class _DynamicMapPainter extends CustomPainter {
  final Color color;
  final ui.Image? staticImage;
  final _ThrottledListenable animation;

  _DynamicMapPainter({
    required this.color,
    required this.staticImage,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (staticImage != null) {
      // Dibuja la imagen estática principal
      canvas.drawImage(staticImage!, Offset.zero, Paint());

      // Capa de Brillo Suave (Neon Glow Loop)
      final t = animation.value;
      final glowOpacity = (0.05 + (math.sin(t * math.pi * 2) + 1) / 2 * 0.1).clamp(0.0, 1.0);

      canvas.drawImage(
        staticImage!,
        Offset.zero,
        Paint()
          ..colorFilter = ColorFilter.mode(
            color.withOpacity(glowOpacity),
            BlendMode.srcATop,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    final dots = _WorldMapData.dots;
    if (dots == null) return;

    final scale = size.width / _kMapViewBoxWidth;
    canvas.save();
    canvas.scale(scale, scale);

    _drawDataDots(canvas, dots, scale);
    _drawMajorNodes(canvas, scale);

    canvas.restore();
  }

  void _drawDataDots(Canvas canvas, List<_MapDot> dots, double scale) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final t = animation.value;

    for (final dot in dots) {
      final wave = math.sin(
        t * math.pi * 2 + dot.phase + dot.position.dx / _kMapViewBoxWidth * 2.7,
      );
      final pulse = 0.15 + ((wave + 1) / 2) * 0.45;
      dotPaint.color = color.withOpacity(pulse.clamp(0.07, 0.62));
      canvas.drawCircle(dot.position, dot.active ? 0.95 : 0.52, dotPaint);

      if (dot.active && _kDrawDotGlow) {
        final glow = Paint()
          ..color = color.withOpacity(0.18 + ((wave + 1) / 2) * 0.22)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 / scale);
        canvas.drawCircle(dot.position, 2.8, glow);

        final ring = Paint()
          ..color = color.withOpacity(0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.45 / scale;
        canvas.drawCircle(dot.position, 2.1, ring);
      }
    }
  }

  void _drawMajorNodes(Canvas canvas, double scale) {
    final nodes = <Offset>[
      _p(18.5, 28), _p(22.0, 31), _p(25.0, 34), _p(27.0, 38),
      _p(33.0, 55), _p(35.0, 61), _p(34.0, 68), _p(31.5, 73),
      _p(49.0, 29), _p(52.0, 27), _p(55.0, 29), _p(58.0, 30),
      _p(51.0, 43), _p(54.0, 48), _p(53.0, 56), _p(50.0, 63),
      _p(62.0, 28), _p(67.0, 25), _p(72.0, 27), _p(77.0, 29),
      _p(82.0, 31), _p(87.0, 32),
      _p(71.0, 42),
      _p(88.5, 35),
      _p(82.0, 65), _p(87.0, 66), _p(91.0, 69),
    ];

    final t = animation.value;
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final pulse = (math.sin(t * math.pi * 2 + i * 0.57) + 1) / 2;

      // Nodos mayores: pocos (24), así que sí se pueden dar el lujo
      // de un glow pequeño sin matar el framerate.
      final glow = Paint()
        ..color = color.withOpacity(0.10 + pulse * 0.18)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 / scale);
      canvas.drawCircle(node, 3.0 + pulse * 2.0, glow);

      final point = Paint()
        ..color = color.withOpacity(0.52 + pulse * 0.42)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node, 1.0 + pulse * 0.55, point);
    }
  }

  Offset _p(double xPct, double yPct) {
    return Offset(xPct / 100 * _kMapViewBoxWidth, yPct / 100 * _kMapViewBoxHeight);
  }

  @override
  bool shouldRepaint(covariant _DynamicMapPainter oldDelegate) {
    return oldDelegate.staticImage != staticImage || oldDelegate.color != color;
  }
}

// ============================================================
// TEMPERATURE
// ============================================================
class _TempGauge extends StatefulWidget {
  final int temp;
  final Color color;
  final bool isWarning;
  const _TempGauge({required this.temp, required this.color, this.isWarning = false});

  @override
  State<_TempGauge> createState() => _TempGaugeState();
}

class _TempGaugeState extends State<_TempGauge> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
                    child: Icon(Icons.thermostat_rounded, color: displayColor.withOpacity(0.5), size: 18),
                  ),
                  Text('${widget.temp}',
                      style: TextStyle(
                          color: widget.isWarning ? Colors.redAccent : Colors.white,
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                  Text('°C', style: TextStyle(color: displayColor, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 2),
              Text('TEMPERATURA',
                  style: TextStyle(
                      color: widget.isWarning ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// MUSIC HUB
// ============================================================
class _SmallMusicHub extends StatelessWidget {
  final MusicProvider music;
  final Color color;
  const _SmallMusicHub({required this.music, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0212).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15)],
      ),
      child: Row(
        children: [
          _MusicDisk(isPlaying: music.isPlaying, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  music.trackTitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                Text(
                  music.artistName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MusicBtn(icon: Icons.skip_previous_rounded, onTap: music.previous),
                    const SizedBox(width: 10),
                    _MusicBtn(
                      icon: music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      onTap: music.playPause,
                      isMain: true,
                    ),
                    const SizedBox(width: 10),
                    _MusicBtn(icon: Icons.skip_next_rounded, onTap: music.next),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicDisk extends StatelessWidget {
  final bool isPlaying;
  final Color color;
  const _MusicDisk({required this.isPlaying, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Center(child: Icon(Icons.music_note_rounded, color: color, size: 24)),
    );
  }
}

class _MusicBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isMain;
  const _MusicBtn({required this.icon, required this.onTap, this.isMain = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isMain ? 6 : 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMain ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(icon, color: Colors.white, size: isMain ? 22 : 18),
      ),
    );
  }
}

// ============================================================
// VOLTAGE DISPLAY
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
        Text(voltage.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(width: 4),
        Text('V', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
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
  const _NeonSpeedometer({required this.speed, required this.color, this.isWarning = false});

  @override
  State<_NeonSpeedometer> createState() => _NeonSpeedometerState();
}

class _NeonSpeedometerState extends State<_NeonSpeedometer> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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
                // Brillo Loop extra cuando hay alerta
                if (widget.isWarning)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.2 * glowIntensity),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _SpeedoPainter(speed: widget.speed, color: displayColor, glowPulse: glowIntensity),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${widget.speed}',
                        style: TextStyle(
                            color: widget.isWarning ? Colors.redAccent : Colors.white,
                            fontSize: widget.isWarning ? 94 : 84,
                            fontWeight: FontWeight.w900,
                            height: 1)),
                    Text('KM/H',
                        style: TextStyle(
                            color: displayColor.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4)),
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
  final Color color;
  final double glowPulse;
  _SpeedoPainter({required this.speed, required this.color, this.glowPulse = 0.0});

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

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final progress = (speed / 240).clamp(0.0, 1.0);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, activePaint);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 + (glowPulse * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + (glowPulse * 4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + (glowPulse * 5));

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedoPainter oldDelegate) =>
      oldDelegate.speed != speed || oldDelegate.color != color;
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
