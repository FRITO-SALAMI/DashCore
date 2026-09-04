import 'dart:math' as math;
import 'package:flutter/material.dart';

class RpmGaugePainter extends CustomPainter {
  final double rpmValue;
  final Color color;
  final bool showNumbers;
  final bool isSolid;

  RpmGaugePainter({
    required this.rpmValue,
    required this.color,
    this.showNumbers = true,
    this.isSolid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10), startAngle, sweepAngle, false, basePaint);

    final tickPaint = Paint()..strokeWidth = 1.5;
    for (int i = 0; i <= 80; i++) {
      final angle = startAngle + (sweepAngle * (i / 80));
      final isMajor = i % 10 == 0;
      final isReached = (rpmValue * 10) >= i;

      tickPaint.color = isReached ? color : Colors.white.withOpacity(0.1);
      final tickLength = isMajor ? 15.0 : 8.0;

      canvas.drawLine(
        center + Offset(math.cos(angle) * (radius - 10), math.sin(angle) * (radius - 10)),
        center + Offset(math.cos(angle) * (radius - 10 - tickLength), math.sin(angle) * (radius - 10 - tickLength)),
        tickPaint,
      );

      if (isMajor && showNumbers) {
        final textPainter = TextPainter(
          text: TextSpan(text: '${i ~/ 10}', style: TextStyle(color: isReached ? Colors.white : Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelAngle = angle;
        final labelRadius = radius - 45;
        textPainter.paint(canvas, center + Offset(math.cos(labelAngle) * labelRadius - textPainter.width / 2, math.sin(labelAngle) * labelRadius - textPainter.height / 2));
      }
    }

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSolid ? 20 : 4
      ..strokeCap = isSolid ? StrokeCap.butt : StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius - (isSolid ? 15 : 5));
    canvas.drawArc(arcRect, startAngle, sweepAngle * (rpmValue / 8).clamp(0.0, 1.0), false, progressPaint);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSolid ? 24 : 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(arcRect, startAngle, sweepAngle * (rpmValue / 8).clamp(0.0, 1.0), false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant RpmGaugePainter oldDelegate) => oldDelegate.rpmValue != rpmValue || oldDelegate.color != color;
}
