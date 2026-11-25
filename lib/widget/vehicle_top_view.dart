import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class VehicleTopView extends StatelessWidget {
  const VehicleTopView({super.key, required this.colorHex});
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final value = int.tryParse(colorHex.replaceFirst('#', ''), radix: 16);
    return Semantics(
      label: 'Vehículo visto desde arriba',
      child: CustomPaint(
        painter: _TopViewPainter(
          value == null ? AppColors.accent : Color(0xFF000000 | value),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TopViewPainter extends CustomPainter {
  const _TopViewPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 112, size.height / 212);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    final tire = Paint()..color = const Color(0xFF0A1119);
    for (final x in [-35.0, 35.0]) {
      for (final y in [-48.0, 49.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 15, height: 29),
            const Radius.circular(5),
          ),
          tire,
        );
      }
    }
    final body = Path()
      ..moveTo(0, -85)
      ..cubicTo(25, -85, 39, -75, 39, -54)
      ..lineTo(34, 61)
      ..quadraticBezierTo(34, 82, 11, 83)
      ..lineTo(-11, 83)
      ..quadraticBezierTo(-34, 82, -34, 61)
      ..lineTo(-39, -54)
      ..cubicTo(-39, -75, -25, -85, 0, -85)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, .36)!,
            color,
            Color.lerp(color, Colors.black, .30)!,
          ],
        ).createShader(const Rect.fromLTRB(-42, -85, 42, 83)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white38
        ..strokeWidth = 1,
    );
    final glass = Paint()..color = const Color(0xFF17283A);
    canvas.drawPath(
      Path()
        ..moveTo(-26, -40)
        ..quadraticBezierTo(0, -52, 26, -40)
        ..lineTo(19, -18)
        ..lineTo(-19, -18)
        ..close(),
      glass,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-18, 22)
        ..lineTo(18, 22)
        ..lineTo(24, 47)
        ..quadraticBezierTo(0, 57, -24, 47)
        ..close(),
      glass,
    );
    for (final x in [-25.0, 25.0]) {
      canvas.drawCircle(
        Offset(x, -66),
        5,
        Paint()..color = const Color(0xFFEAF9FF),
      );
      canvas.drawCircle(
        Offset(x, 69),
        4,
        Paint()..color = const Color(0xFFFF726C),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TopViewPainter oldDelegate) =>
      color != oldDelegate.color;
}
