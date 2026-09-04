import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import '../rpm_warning_animation.dart';

class HellishRedDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final String tempUnit;
  final String? backgroundImage;
  final bool isAssetBackground;

  const HellishRedDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.tempUnit = '°C',
    this.backgroundImage,
    this.isAssetBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompetitive = rpm > 5000;

    ImageProvider bgImage;
    if (backgroundImage != null) {
      bgImage = isAssetBackground
          ? AssetImage(backgroundImage!)
          : FileImage(File(backgroundImage!)) as ImageProvider;
    } else {
      bgImage = const AssetImage('assets/images/png/car1.png');
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isCompetitive ? const Color(0xFF500000) : Colors.black,
        image: DecorationImage(
          image: bgImage,
          fit: BoxFit.cover,
          opacity: 0.9,
        ),
      ),
      child: Stack(
        children: [
          // Hellish RPM Gauge (Background)
          Positioned.fill(
            child: RpmWarningAnimation(
              rpm: rpm,
              child: CustomPaint(
                painter: _HellishRpmPainter(rpm: rpm),
              ),
            ),
          ),

          // Robust Speed Display
          Positioned(
            left: 60,
            bottom: 120,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isCompetitive ? 1.15 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$speed',
                    style: TextStyle(
                      color: isCompetitive ? const Color(0xFFFF1111) : Colors.white,
                      fontSize: 160,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      height: 0.9,
                      shadows: [
                        Shadow(color: Colors.red.withOpacity(0.8), blurRadius: isCompetitive ? 50 : 20),
                        const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(5, 5)),
                      ],
                    ),
                  ),
                  const Text(
                    'KM/H',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Robust Battery Info
          Positioned(
            right: 80,
            bottom: 260,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFF1111), size: 60),
                  const SizedBox(width: 15),
                  Text(
                    voltage.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 70,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Robust Coolant Info
          Positioned(
            right: 80,
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thermostat_rounded, color: Color(0xFFFF1111), size: 60),
                  const SizedBox(width: 15),
                  Text(
                    '$coolantTemp',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 70,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tempUnit,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Header Decoration
          Positioned(
            top: 40,
            left: 60,
            child: Row(
              children: [
                const Icon(Icons.whatshot_rounded, color: Colors.red, size: 40),
                const SizedBox(width: 15),
                const Text(
                  'HELLISH MODE ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // Red overlay for that "hellish" look
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.withOpacity(isCompetitive ? 0.2 : 0.05),
                    Colors.transparent,
                  ],
                  radius: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HellishRpmPainter extends CustomPainter {
  final int rpm;
  _HellishRpmPainter({required this.rpm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.45;
    final progress = (rpm / 8000).clamp(0.0, 1.0);

    final bgPaint = Paint()
      ..color = Colors.red.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.7, math.pi * 1.6, false, bgPaint);

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF500000), Color(0xFFFF0000), Color(0xFFFF5500)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 50;

    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.7, math.pi * 1.6 * progress, false, activePaint);
    }

    // Aggressive Ticks
    final tickPaint = Paint()..color = Colors.red.withOpacity(0.3)..strokeWidth = 3;
    for (int i = 0; i <= 16; i++) {
       final angle = math.pi * 0.7 + (math.pi * 1.6 * (i / 16));
       final start = center + Offset(math.cos(angle) * (radius - 40), math.sin(angle) * (radius - 40));
       final end = center + Offset(math.cos(angle) * (radius + 40), math.sin(angle) * (radius + 40));
       canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
