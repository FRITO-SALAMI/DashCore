import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlowRedDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final String tempUnit;

  const GlowRedDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.tempUnit = '°C',
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day}.${now.month}.${now.year}';

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Background Glow Path
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPathPainter(),
            ),
          ),
          
          // Top Header: Time and Date
          Positioned(
            top: 20,
            right: 40,
            child: Row(
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Central Boost Meter at the top
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: _BoostMeter(value: (rpm / 8000)),
          ),

          // Main Gauges
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Gauge: RPM
                  _GlowCircularGauge(
                    value: rpm,
                    maxValue: 8000,
                    label: 'RPM',
                    unit: '',
                  ),

                  // Right Gauge: Speed
                  _GlowCircularGauge(
                    value: speed,
                    maxValue: 260,
                    label: 'KM/H',
                    unit: '',
                  ),
                ],
              ),
            ),
          ),

          // Bottom Gear Indicator (Removed as requested by design or consolidated)
        ],
      ),
    );
  }
}

class _GlowCircularGauge extends StatelessWidget {
  final int value;
  final int maxValue;
  final String label;
  final String unit;

  const _GlowCircularGauge({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(320, 320),
            painter: _GlowGaugePainter(
              progress: progress,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowGaugePainter extends CustomPainter {
  final double progress;

  _GlowGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const redColor = Color(0xFFFF0000);

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    // Outer thin ring (arc)
    final outerPaint = Paint()
      ..color = redColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      startAngle,
      sweepAngle,
      false,
      outerPaint,
    );

    // Main glowing ring (arc)
    final glowPaint = Paint()
      ..color = redColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 15),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    final solidPaint = Paint()
      ..color = redColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 15),
      startAngle,
      sweepAngle,
      false,
      solidPaint,
    );

    // Needle
    final needleAngle = startAngle + progress * sweepAngle;
    final needlePaint = Paint()
      ..color = redColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final needleLength = radius - 30;
    final needleStartRadius = radius - 70;
    
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * needleLength,
      center.dy + math.sin(needleAngle) * needleLength,
    );
    final needleStart = Offset(
      center.dx + math.cos(needleAngle) * needleStartRadius,
      center.dy + math.sin(needleAngle) * needleStartRadius,
    );
    canvas.drawLine(needleStart, needleEnd, needlePaint);
    
    // Needle head glow
    final headGlow = Paint()
      ..color = redColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(needleEnd, 5, headGlow);
  }

  @override
  bool shouldRepaint(covariant _GlowGaugePainter oldDelegate) => oldDelegate.progress != progress;
}

class _BoostMeter extends StatelessWidget {
  final double value;
  const _BoostMeter({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('-', style: TextStyle(color: Colors.white54, fontSize: 16)),
              const Text(
                'BOOST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const Text('+', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 300,
          height: 30,
          child: CustomPaint(
            painter: _BoostPainter(progress: value),
          ),
        ),
      ],
    );
  }
}

class _BoostPainter extends CustomPainter {
  final double progress;
  _BoostPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const tickCount = 31;
    final spacing = size.width / (tickCount - 1);
    final mid = (tickCount - 1) / 2;

    for (int i = 0; i < tickCount; i++) {
      final x = i * spacing;
      final distFromMid = (i - mid).abs();
      
      // Hide ticks in the center to make room for the label above
      if (distFromMid < 3) continue;

      final height = (distFromMid % 5 == 0) ? size.height * 0.8 : size.height * 0.4;
      
      final active = (i / tickCount) <= progress;
      paint.color = active ? Colors.red : Colors.white24;

      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoostPainter oldDelegate) => oldDelegate.progress != progress;
}

class _BackgroundPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    // A shape that connects the two circles, similar to the one in the image
    final w = size.width;
    final h = size.height;
    
    path.moveTo(w * 0.2, h * 0.3);
    path.quadraticBezierTo(w * 0.5, h * 0.25, w * 0.8, h * 0.3);
    path.lineTo(w * 0.8, h * 0.7);
    path.quadraticBezierTo(w * 0.5, h * 0.75, w * 0.2, h * 0.7);
    path.close();

    canvas.drawPath(path, paint);
    
    // Add a subtle border to the path
    final borderPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
