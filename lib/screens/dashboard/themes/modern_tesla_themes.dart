import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../../widget/music_hub.dart';
import '../../../models/obd_data.dart';
import '../../../providers/music_provider.dart';
import '../../../providers/dash_settings_provider.dart';
import 'package:dashcore/widget/dashboard_background.dart';

class ModernTeslaRoadTheme extends StatefulWidget {
  final ObdData data;
  final String modelPath;
  final Color accentColor;

  const ModernTeslaRoadTheme({
    super.key,
    required this.data,
    required this.modelPath,
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  State<ModernTeslaRoadTheme> createState() => _ModernTeslaRoadThemeState();
}

class _ModernTeslaRoadThemeState extends State<ModernTeslaRoadTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roadController;

  @override
  void initState() {
    super.initState();
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final isGifBackground = settings.backgroundImage?.endsWith('.gif') ?? false;

    // Warning states
    final bool isTempWarning = settings.tempWarningEnabled && widget.data.engineTemp >= settings.tempAlertThreshold;
    final bool isSpeedWarning = settings.speedWarningEnabled && widget.data.speed >= settings.speedAlertThreshold;
    final Color displayAccent = isSpeedWarning ? Colors.redAccent : widget.accentColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ... (DashboardBackground)
          if (settings.backgroundImage != null)
            DashboardBackground(
              backgroundImage: settings.backgroundImage,
              isAssetBackground: settings.isAssetBackground,
              opacity: isGifBackground ? 0.3 : 0.1,
            ),
          // Road and Perspective
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _roadController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TeslaRoadPainter(
                    animationValue: _roadController.value,
                    speed: widget.data.speed.toDouble(),
                    color: displayAccent,
                  ),
                );
              },
            ),
          ),

          // 3D Model
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            height: 180,
            child: IgnorePointer(
              child: ModelViewer(
                key: ValueKey(widget.modelPath),
                src: widget.modelPath,
                backgroundColor: Colors.transparent,
                autoRotate: false,
                cameraControls: false,
                disableZoom: true,
                disablePan: true,
                cameraOrbit: '180deg 65deg 5m',
                exposure: 1.2,
                loading: Loading.eager,
                shadowIntensity: 0.1,
              ),
            ),
          ),

          // Speed on the Left
          Positioned(
            left: 60,
            top: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isSpeedWarning ? Colors.redAccent : Colors.white,
                    fontSize: isSpeedWarning ? 160 : 140,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                  child: Text(widget.data.speed.round().toString()),
                ),
                Text(
                  'KM/H',
                  style: TextStyle(
                    color: isSpeedWarning ? Colors.redAccent.withOpacity(0.5) : Colors.white54,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // Stats on the Right (Temp & Volt)
          Positioned(
            right: 60,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TeslaStat(
                  label: 'TEMP',
                  value: '${widget.data.engineTemp}°C',
                  accentColor: isTempWarning ? Colors.redAccent : widget.accentColor,
                  isWarning: isTempWarning,
                ),
                const SizedBox(height: 20),
                _TeslaStat(
                  label: 'VOLT',
                  value: '${widget.data.voltage.toStringAsFixed(1)}V',
                  accentColor: displayAccent,
                ),
              ],
            ),
          ),

          // Gear Indicator Right
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              children: ['P', 'D', 'R', 'N'].map((g) {
                final active = g == widget.data.gear;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white24,
                      fontSize: active ? 22 : 18,
                      fontWeight: active ? FontWeight.w900 : FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Music Hub Bottom Left
          Positioned(
            bottom: 20,
            left: 20,
            child: MusicHub(
              accentColor: widget.accentColor,
              width: 220,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class ModernTeslaModelTheme extends StatelessWidget {
  final ObdData data;
  final String modelPath;
  final Color accentColor;
  final String? backgroundImage;
  final bool isAssetBackground;

  const ModernTeslaModelTheme({
    super.key,
    required this.data,
    required this.modelPath,
    this.accentColor = const Color(0xFF00E5FF),
    this.backgroundImage,
    this.isAssetBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = backgroundImage == 'COLOR_BLACK' || backgroundImage == null || !isAssetBackground;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    final settings = context.watch<DashSettingsProvider>();
    final bool isTempWarning = settings.tempWarningEnabled && data.engineTemp >= settings.tempAlertThreshold;
    final bool isSpeedWarning = settings.speedWarningEnabled && data.speed >= settings.speedAlertThreshold;
    final Color displayAccent = isSpeedWarning ? Colors.redAccent : accentColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF1F3F5), 
      body: Stack(
        children: [
          // ... (DashboardBackground)
          if (backgroundImage != null && backgroundImage != 'COLOR_BLACK')
            DashboardBackground(
              backgroundImage: backgroundImage,
              isAssetBackground: isAssetBackground,
              opacity: 0.3,
            ),
          // Large 3D Model
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.6,
              child: ModelViewer(
                key: ValueKey(modelPath),
                src: modelPath,
                backgroundColor: Colors.transparent,
                autoRotate: false,
                cameraControls: true,
                disableZoom: true,
                disablePan: true,
                cameraOrbit: '45deg 75deg 3.5m',
                exposure: 1.0,
                shadowIntensity: 0.1,
                loading: Loading.eager,
              ),
            ),
          ),

          // Speed on the Left
          Positioned(
            left: 80,
            top: MediaQuery.of(context).size.height * 0.15, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isSpeedWarning ? Colors.redAccent : textColor,
                    fontSize: isSpeedWarning ? 180 : 160,
                    fontWeight: FontWeight.w900,
                  ),
                  child: Text(data.speed.round().toString()),
                ),
                Text(
                  'KM/H',
                  style: TextStyle(
                    color: isSpeedWarning ? Colors.redAccent.withOpacity(0.5) : subTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // Stats on the Right (Temp & Volt)
          Positioned(
            right: 40,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TeslaStat(
                  label: 'TEMP',
                  value: '${data.engineTemp}°C',
                  accentColor: isTempWarning ? Colors.redAccent : accentColor,
                  isLight: !isDark,
                  isWarning: isTempWarning,
                ),
                const SizedBox(height: 15),
                _TeslaStat(
                  label: 'VOLT',
                  value: '${data.voltage.toStringAsFixed(1)}V',
                  accentColor: displayAccent,
                  isLight: !isDark,
                ),
              ],
            ),
          ),

          // Music Hub (Bottom Left corner)
          Positioned(
            bottom: 40,
            left: 40,
            child: MusicHub(
              accentColor: accentColor,
              width: 220,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeslaStat extends StatefulWidget {
  final String label;
  final String value;
  final Color accentColor;
  final bool isLight;
  final bool isWarning;

  const _TeslaStat({
    required this.label,
    required this.value,
    required this.accentColor,
    this.isLight = false,
    this.isWarning = false,
  });

  @override
  State<_TeslaStat> createState() => _TeslaStatState();
}

class _TeslaStatState extends State<_TeslaStat> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.isWarning) _blinkController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TeslaStat oldWidget) {
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
        final Color textColor = widget.isWarning ? Colors.redAccent : (widget.isLight ? Colors.black : Colors.white);
        final Color displayAccent = widget.isWarning ? Colors.redAccent : widget.accentColor;

        return Opacity(
          opacity: widget.isWarning ? (0.4 + 0.6 * opacity) : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isLight ? Colors.black38 : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                widget.value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                width: 60,
                height: 3,
                color: displayAccent,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModernMusicHub extends StatelessWidget {
  final Color accentColor;
  final bool isLight;
  final double maxWidth;

  const _ModernMusicHub({
    required this.accentColor,
    this.isLight = false,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withOpacity(0.95) : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? Colors.black12 : Colors.white10),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, color: isLight ? Colors.black : accentColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    music.trackTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    music.artistName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (isLight ? Colors.black : Colors.white).withOpacity(0.4),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: music.previous,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.skip_previous_rounded, color: isLight ? Colors.black : Colors.white),
            ),
            const SizedBox(width: 5),
            IconButton(
              onPressed: music.playPause,
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isLight ? Colors.black : Colors.white
              ),
            ),
            const SizedBox(width: 5),
            IconButton(
              onPressed: music.next,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.skip_next_rounded, color: isLight ? Colors.black : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeslaRoadPainter extends CustomPainter {
  final double animationValue;
  final double speed;
  final Color color;

  _TeslaRoadPainter({required this.animationValue, required this.speed, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final vanishPoint = Offset(w / 2, h * 0.4);

    // Draw Horizon/Sky Gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.05), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, w, vanishPoint.dy));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, vanishPoint.dy), skyPaint);

    final roadPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w * -0.2, h)
      ..lineTo(vanishPoint.dx - 40, vanishPoint.dy)
      ..lineTo(vanishPoint.dx + 40, vanishPoint.dy)
      ..lineTo(w * 1.2, h)
      ..close();

    canvas.drawPath(path, roadPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw solid edges
    canvas.drawLine(Offset(w * -0.2, h), vanishPoint, linePaint);
    canvas.drawLine(Offset(w * 1.2, h), vanishPoint, linePaint);

    // Dashed lines with proper perspective
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2;

    double moveOffset = (animationValue * 100) % 50;
    
    // 4 dividers
    for (double factor in [0.1, 0.35, 0.65, 0.9]) {
       final startX = w * factor;
       final start = Offset(startX, h);
       _drawDashedLine(canvas, start, vanishPoint, moveOffset, dashPaint);
    }

    // Draw Trees Silhouettes
    _drawTrees(canvas, size, vanishPoint);
  }

  void _drawTrees(Canvas canvas, Size size, Offset vanish) {
    final w = size.width;
    final h = size.height;
    
    final treePaint = Paint()..color = Colors.white.withOpacity(0.15);
    
    for (int i = 0; i < 6; i++) {
      double t = (animationValue + (i / 6)) % 1.0;
      double perspectiveScale = math.pow(t, 3).toDouble();
      
      for (double side in [-1, 1]) {
        double x = vanish.dx + (side * w * 0.8 * perspectiveScale);
        double y = vanish.dy + (h - vanish.dy) * perspectiveScale;
        
        double treeHeight = 150 * perspectiveScale;
        double treeWidth = 60 * perspectiveScale;
        
        if (perspectiveScale > 0.05) {
          final treePath = Path()
            ..moveTo(x, y)
            ..lineTo(x - treeWidth / 2, y)
            ..lineTo(x, y - treeHeight)
            ..lineTo(x + treeWidth / 2, y)
            ..close();
          canvas.drawPath(treePath, treePaint);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, double offset, Paint paint) {
    final direction = end - start;
    final distance = direction.distance;
    final unitVector = direction / distance;

    double d = offset;
    while (d < distance) {
      final p1 = start + unitVector * d;
      // Perspective shortening: further dashes are shorter
      double ratio = 1 - (d / distance);
      double dashLen = 30 * math.max(0.2, ratio);
      
      final p2 = start + unitVector * (math.min(d + dashLen, distance));
      
      paint.color = Colors.white.withOpacity(0.6 * math.max(0.1, ratio));
      canvas.drawLine(p1, p2, paint);
      d += dashLen * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _TeslaRoadPainter oldDelegate) => true;
}

class _SimpleGraphPainter extends CustomPainter {
  final Color color;
  _SimpleGraphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.75);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
