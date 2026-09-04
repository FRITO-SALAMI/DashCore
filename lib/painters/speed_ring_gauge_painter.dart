import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedRingGaugePainter extends CustomPainter {
  final double speedKmh;
  final Color color;

  SpeedRingGaugePainter({required this.speedKmh, this.color = Colors.greenAccent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.46;

    // Background track with ticks
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    const startAngle = -math.pi * 0.4;
    const sweepAngle = math.pi * 1.8;

    // Outer faint ring
    canvas.drawCircle(center, radius + 5, Paint()..color = Colors.white.withOpacity(0.01)..style = PaintingStyle.stroke..strokeWidth = 1);

    // Active progress (inner glowy ring)
    final progress = (speedKmh / 240).clamp(0.0, 1.0);

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // Active arc
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant SpeedRingGaugePainter oldDelegate) =>
    oldDelegate.speedKmh != speedKmh || oldDelegate.color != color;
}
