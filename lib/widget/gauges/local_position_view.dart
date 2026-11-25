import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Bounded, ephemeral trail. It is never persisted or passed to a backend.
class LocalTrail {
  final List<Position> _positions = [];
  List<Position> get positions => List.unmodifiable(_positions);
  void add(Position position) {
    if (!position.latitude.isFinite ||
        position.latitude.abs() > 90 ||
        !position.longitude.isFinite ||
        position.longitude.abs() > 180 ||
        !position.accuracy.isFinite ||
        position.accuracy < 0 ||
        position.accuracy > 50) {
      return;
    }
    if (_positions.isNotEmpty) {
      final previous = _positions.last;
      final seconds =
          position.timestamp.difference(previous.timestamp).inMilliseconds /
          1000;
      if (seconds <= 0) return;
      if (seconds >= 60) {
        // Start a fresh segment after the radio loses a fix or goes to sleep.
        _positions.clear();
      } else {
        final meters = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        );
        if (meters > seconds * 85 + previous.accuracy + position.accuracy)
          return;
      }
    }
    _positions.add(position);
    if (_positions.length > 180) _positions.removeAt(0);
  }

  void clear() => _positions.clear();
}

class LocalPositionView extends StatelessWidget {
  const LocalPositionView({
    super.key,
    required this.trail,
    this.northUp = true,
  });
  final List<Position> trail;
  final bool northUp;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Posición y recorrido local. Escala de 100 metros por cuadrícula.',
    child: CustomPaint(
      painter: _PositionPainter(trail, northUp),
      child: const SizedBox.expand(),
    ),
  );
}

class _PositionPainter extends CustomPainter {
  _PositionPainter(this.trail, this.northUp);
  final List<Position> trail;
  final bool northUp;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0C111D),
    );
    final center = Offset(size.width / 2, size.height / 2);
    const pixelsPerMeter = .35;
    const grid = 100 * pixelsPerMeter;
    final heading = trail.isEmpty || !trail.last.heading.isFinite
        ? 0.0
        : trail.last.heading;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!northUp) canvas.rotate(-heading * math.pi / 180);
    final extent = math.max(size.width, size.height);
    final gridPaint = Paint()
      ..color = const Color(0xFF1A263B)
      ..strokeWidth = 1;
    for (double n = -extent; n <= extent; n += grid) {
      canvas.drawLine(Offset(n, -extent), Offset(n, extent), gridPaint);
      canvas.drawLine(Offset(-extent, n), Offset(extent, n), gridPaint);
    }
    if (trail.isNotEmpty) {
      final latest = trail.last;
      final cosLat = math.cos(latest.latitude * math.pi / 180);
      final path = Path();
      for (var i = 0; i < trail.length; i++) {
        final p = trail[i];
        final longitudeDelta =
            (p.longitude - latest.longitude + 540) % 360 - 180;
        final x = longitudeDelta * cosLat * 111320 * pixelsPerMeter;
        final y = -(p.latitude - latest.latitude) * 111320 * pixelsPerMeter;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF9E8AFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset.zero,
        (latest.accuracy * pixelsPerMeter).clamp(8, 40),
        Paint()..color = const Color(0x228D80FF),
      );
    }
    canvas.restore();
    canvas.drawCircle(center, 19, Paint()..color = const Color(0xFF101A2A));
    canvas.drawCircle(
      center,
      17,
      Paint()
        ..color = const Color(0xFFB8A5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(northUp ? heading * math.pi / 180 : 0);
    canvas.drawPath(
      Path()
        ..moveTo(0, -11)
        ..lineTo(8, 9)
        ..lineTo(0, 5)
        ..lineTo(-8, 9)
        ..close(),
      Paint()..color = const Color(0xFFD6CDFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PositionPainter oldDelegate) =>
      trail != oldDelegate.trail || northUp != oldDelegate.northUp;
}
