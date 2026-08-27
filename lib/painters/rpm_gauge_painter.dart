import 'dart:math' as math;
import 'package:flutter/material.dart';

class RpmGaugePainter extends CustomPainter {
  final double rpmValue;
  final Color color;

  RpmGaugePainter({required this.rpmValue, this.color = Colors.blueAccent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = math.min(size.width, size.height) * 0.42;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Red zone (7 to 8)
    final redZonePaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final redZoneStart = startAngle + (sweepAngle * (7 / 8));
    final redZoneSweep = sweepAngle * (1 / 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      redZoneStart,
      redZoneSweep,
      false,
      redZonePaint,
    );

    // Active progress arc
    final bool isWarning = rpmValue > 4.5;
    final Color activeColor = isWarning ? Colors.redAccent : color;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    final progress = (rpmValue / 8.0).clamp(0.0, 1.0);

    // Gradient for the active arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    activePaint.shader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [activeColor.withOpacity(0.2), activeColor, activeColor],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, glowPaint);

    // Draw Numbers
    _drawNumbers(canvas, center, radius, startAngle, sweepAngle, activeColor);

    // Needle
    final needleAngle = startAngle + progress * sweepAngle;
    final needlePaint = Paint()
      ..color = isWarning ? Colors.red : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    final Path needlePath = Path();
    final double needleLen = radius - 15;

    // Physical needle shape (triangle-ish)
    needlePath.moveTo(
      center.dx + 10 * math.cos(needleAngle + math.pi/2),
      center.dy + 10 * math.sin(needleAngle + math.pi/2),
    );
    needlePath.lineTo(
      center.dx + needleLen * math.cos(needleAngle),
      center.dy + needleLen * math.sin(needleAngle),
    );
    needlePath.lineTo(
      center.dx + 10 * math.cos(needleAngle - math.pi/2),
      center.dy + 10 * math.sin(needleAngle - math.pi/2),
    );
    needlePath.close();

    canvas.drawPath(needlePath, needlePaint);

    // Needle border for contrast
    canvas.drawPath(needlePath, Paint()..color = Colors.black.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1);

    // Center pivot
    canvas.drawCircle(center, 10, Paint()..color = activeColor);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);

    // Outer glow for needle pivot
    canvas.drawCircle(center, 12, Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawNumbers(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, Color activeColor) {
    for (int i = 0; i <= 8; i++) {
      final double angle = startAngle + (i / 8.0) * sweepAngle;
      final double numRadius = radius - 35;

      final Offset pos = Offset(
        center.dx + numRadius * math.cos(angle),
        center.dy + numRadius * math.sin(angle),
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: i > 4 ? Colors.redAccent.withOpacity(0.8) : Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

      // Ticks
      final tickPaint = Paint()
        ..color = i > 4 ? Colors.redAccent.withOpacity(0.5) : Colors.white24
        ..strokeWidth = 2;

      final p1 = center + Offset(math.cos(angle) * (radius - 5), math.sin(angle) * (radius - 5));
      final p2 = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RpmGaugePainter oldDelegate) =>
    oldDelegate.rpmValue != rpmValue || oldDelegate.color != color;
}
