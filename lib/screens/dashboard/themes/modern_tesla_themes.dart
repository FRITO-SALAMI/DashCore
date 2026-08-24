import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../../models/obd_data.dart';
import '../../../providers/music_provider.dart';

class ModernTeslaRoadTheme extends StatefulWidget {
  final ObdData data;
  final String modelPath;
  final String nowPlayingTitle;
  final Color accentColor;

  const ModernTeslaRoadTheme({
    super.key,
    required this.data,
    required this.modelPath,
    required this.nowPlayingTitle,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Road and Perspective
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _roadController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TeslaRoadPainter(
                    animationValue: _roadController.value,
                    speed: widget.data.speed.toDouble(),
                  ),
                );
              },
            ),
          ),

          // 3D Model in center of road
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            height: 250,
            child: IgnorePointer(
              child: ModelViewer(
                key: ValueKey(widget.modelPath),
                src: widget.modelPath,
                backgroundColor: Colors.transparent,
                autoRotate: false,
                cameraControls: false,
                disableZoom: true,
                disablePan: true,
                cameraOrbit: '180deg 80deg 2.5m',
                exposure: 1.0,
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
                Text(
                  widget.data.speed.round().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 140, // Increased
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'KM/H',
                  style: TextStyle(
                    color: Colors.white54,
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
                  accentColor: widget.accentColor,
                ),
                const SizedBox(height: 20),
                _TeslaStat(
                  label: 'VOLT',
                  value: '${widget.data.voltage.toStringAsFixed(1)}V',
                  accentColor: widget.accentColor,
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
            child: _ModernMusicHub(
              accentColor: widget.accentColor,
              maxWidth: 220, // More compact
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
  final String nowPlayingTitle;
  final Color accentColor;

  const ModernTeslaModelTheme({
    super.key,
    required this.data,
    required this.modelPath,
    required this.nowPlayingTitle,
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5), // Light background as in image 2
      body: Stack(
        children: [
          // Large 3D Model
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
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
                shadowIntensity: 1.0,
              ),
            ),
          ),

          // Speed on the Left
          Positioned(
            left: 80,
            top: MediaQuery.of(context).size.height * 0.15, // Higher up
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.speed.round().toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 160, // Increased
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'KM/H',
                  style: TextStyle(
                    color: Colors.black54,
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
                  accentColor: Colors.black,
                  isLight: true,
                ),
                const SizedBox(height: 15),
                _TeslaStat(
                  label: 'VOLT',
                  value: '${data.voltage.toStringAsFixed(1)}V',
                  accentColor: Colors.black,
                  isLight: true,
                ),
              ],
            ),
          ),

          // Music Hub (Bottom Left corner)
          Positioned(
            bottom: 40,
            left: 40,
            child: _ModernMusicHub(
              accentColor: Colors.black,
              isLight: true,
              maxWidth: 220,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeslaStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final bool isLight;

  const _TeslaStat({
    required this.label,
    required this.value,
    required this.accentColor,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isLight ? Colors.black38 : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isLight ? Colors.black : Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        Container(
          width: 60,
          height: 3,
          color: accentColor,
        ),
      ],
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

  _TeslaRoadPainter({required this.animationValue, required this.speed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final vanishPoint = Offset(w / 2, h * 0.4);

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w * 0.35, h)
      ..lineTo(vanishPoint.dx - 20, vanishPoint.dy)
      ..lineTo(vanishPoint.dx + 20, vanishPoint.dy)
      ..lineTo(w * 0.65, h)
      ..close();

    canvas.drawPath(path, roadPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw lanes
    for (var dx in [w * 0.35, w * 0.65]) {
       canvas.drawLine(Offset(dx, h), vanishPoint, linePaint);
    }

    // Dashed lines
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3;

    double moveOffset = (animationValue * 100) % 60;
    
    final startLeft = Offset(w * 0.45, h);
    final startRight = Offset(w * 0.55, h);

    _drawDashedLine(canvas, startLeft, vanishPoint, moveOffset, dashPaint);
    _drawDashedLine(canvas, startRight, vanishPoint, moveOffset, dashPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, double offset, Paint paint) {
    final direction = end - start;
    final distance = direction.distance;
    final unitVector = direction / distance;

    double d = offset;
    while (d < distance) {
      final p1 = start + unitVector * d;
      final p2 = start + unitVector * (math.min(d + 20, distance));
      canvas.drawLine(p1, p2, paint);
      d += 40;
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
