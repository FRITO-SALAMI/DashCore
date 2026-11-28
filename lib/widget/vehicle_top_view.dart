import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle_model.dart';
import '../providers/dash_settings_provider.dart';

class VehicleTopView extends StatefulWidget {
  const VehicleTopView({
    super.key,
    required this.colorHex,
    this.vehicle,
    this.source = '',
    this.hoodOpen = false,
  });
  final String colorHex;
  final Vehicle? vehicle;
  final String source;
  final bool hoodOpen;

  @override
  State<VehicleTopView> createState() => _VehicleTopViewState();
}

class _VehicleTopViewState extends State<VehicleTopView>
    with WidgetsBindingObserver {
  Timer? _transition;
  bool _night = false;
  bool _foreground = true;
  int _on = 19 * 60, _off = 7 * 60;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<DashSettingsProvider?>();
    _on = settings?.vehicleLightsOn ?? 19 * 60;
    _off = settings?.vehicleLightsOff ?? 7 * 60;
    _updateNight();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateNight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateNight();
  }

  void _updateNight() {
    _transition?.cancel();
    if (!_foreground) return;
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    final night = _on < _off
        ? minute >= _on && minute < _off
        : minute >= _on || minute < _off;
    DateTime boundary(int minutes) {
      var date = DateTime(
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!date.isAfter(now))
        date = DateTime(
          now.year,
          now.month,
          now.day + 1,
          minutes ~/ 60,
          minutes % 60,
        );
      return date;
    }

    final on = boundary(_on), off = boundary(_off);
    final next = on.isBefore(off) ? on : off;
    if (_night != night) setState(() => _night = night);
    _transition = Timer(next.difference(now), _updateNight);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transition?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = int.tryParse(
      widget.colorHex.replaceFirst('#', ''),
      radix: 16,
    );
    final color = value == null
        ? const Color(0xFFC2C8D3)
        : Color(0xFF000000 | value);
    final vehicle = widget.vehicle;
    final silhouette = _Silhouette.forVehicle(vehicle, widget.source);
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.of(context) ||
        context.select<DashSettingsProvider?, bool>(
          (settings) => settings?.reduceMotion ?? false,
        );

    return Semantics(
      image: true,
      label: [
        if (vehicle != null) vehicle.name,
        'Vista superior',
        if (_night) 'Luces nocturnas',
      ].join(' · '),
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _night ? 1 : 0),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          child: const SizedBox.expand(),
          builder: (context, lighting, child) => CustomPaint(
            painter: _TopViewPainter(
              color,
              silhouette,
              lighting,
              widget.hoodOpen,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum _Silhouette {
  // Width, length, glass positions and the sweep of each light assembly.
  k5(36, 84, -32, 32, 12, 10),
  optima(37, 84, -33, 30, 9, 14),
  civic(34, 78, -28, 35, 9, 16),
  sonataLf(37, 86, -35, 32, 11, 13),
  sonataN(38, 86, -30, 37, 21, 20),
  sonataY(35, 82, -34, 35, 8, 11),
  h1(40, 92, -49, 54, 7, 6),
  sedan(35, 81, -32, 31, 12, 13);

  const _Silhouette(
    this.width,
    this.length,
    this.frontGlass,
    this.rearGlass,
    this.headSweep,
    this.tailSweep,
  );
  final double width, length, frontGlass, rearGlass, headSweep, tailSweep;

  static _Silhouette forVehicle(Vehicle? vehicle, String source) {
    final details = [
      vehicle?.brand,
      vehicle?.name,
      vehicle?.year,
      vehicle?.modelUrl,
      source,
    ].whereType<String>().join(' ').toLowerCase();
    if (details.contains('civic')) return civic;
    if (details.contains('nissan') || details.contains('h1')) return h1;
    if (details.contains('k5') || details.contains('2012')) return k5;
    if (details.contains('optima')) return optima;
    if (details.contains('sonata')) {
      if (details.contains('n line') ||
          details.contains('nline') ||
          details.contains('nrise'))
        return sonataN;
      if (details.contains('y20')) return sonataY;
      return sonataLf;
    }
    return sedan;
  }
}

class _TopViewPainter extends CustomPainter {
  const _TopViewPainter(this.color, this.model, this.lighting, this.hoodOpen);
  final bool hoodOpen;
  final Color color;
  final _Silhouette model;
  final double lighting;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(size.width / 136, size.height / 282);
    final w = model.width;
    final l = model.length;
    final hood = model.frontGlass;
    final deck = model.rearGlass;
    final bodyBounds = Rect.fromLTRB(-w - 5, -l, w + 5, l);
    final paint = Paint();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + scale * 10);
    canvas.scale(scale);

    final drop = Rect.fromCenter(
      center: const Offset(0, 3),
      width: w * 2.7,
      height: l * 2.2,
    );
    canvas.drawOval(
      drop,
      paint
        ..shader = const RadialGradient(
          colors: [Color(0xE9000000), Color(0xA3000000), Colors.transparent],
          stops: [0, .63, 1],
        ).createShader(drop),
    );
    paint.shader = null;

    for (final side in [-1.0, 1.0]) {
      final head = Offset(side * (w - 9), -l + 10);
      final tail = Offset(side * (w - 10), l - 9);
      if (lighting > 0) {
        _castLight(canvas, head, side, front: true);
        _castLight(canvas, tail, side, front: false);
      }
      for (final y in [-l * .61, l * .61]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(side * (w - 1), y),
              width: 14,
              height: 28,
            ),
            const Radius.circular(4),
          ),
          paint..color = const Color(0xFF080C11),
        );
      }
      final mirror = Rect.fromCenter(
        center: Offset(side * (w + 2), hood + 15),
        width: 17,
        height: 7,
      );
      canvas.drawOval(
        mirror,
        paint..color = Color.lerp(color, const Color(0xFFE3E8ED), .22)!,
      );
    }

    final shoulder = model == _Silhouette.h1 ? .87 : .62;
    final body = Path()
      ..moveTo(0, -l)
      ..cubicTo(w * shoulder, -l, w - 2, -l + 4, w, -l + 26)
      ..cubicTo(w + 2, -l + 47, w - 4, deck, w, l - 26)
      ..quadraticBezierTo(w + 1, l - 3, w * shoulder, l - 1)
      ..quadraticBezierTo(0, l + 2, -w * shoulder, l - 1)
      ..quadraticBezierTo(-w - 1, l - 3, -w, l - 26)
      ..cubicTo(-w + 4, deck, -w - 2, -l + 47, -w, -l + 26)
      ..cubicTo(-w + 2, -l + 4, -w * shoulder, -l, 0, -l)
      ..close();
    canvas.drawPath(
      body,
      paint
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.black, .35)!,
            Color.lerp(color, const Color(0xFFF0F4FF), .48)!,
            color,
            Color.lerp(color, Colors.black, .45)!,
            Color.lerp(color, const Color(0xFFBCD4F0), .28)!,
          ],
          stops: const [0, .12, .43, .84, 1],
        ).createShader(bodyBounds),
    );
    paint
      ..shader = null
      ..color = const Color(0xAAB7C7D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75;
    canvas.drawPath(body, paint);

    // Stamped hood creases and a recessed grille retain depth at radio sizes.
    paint.style = PaintingStyle.stroke;
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(side * w * .42, -l + 12)
          ..quadraticBezierTo(
            side * w * .62,
            -l + 27,
            side * w * .64,
            hood - 9,
          ),
        paint
          ..color = const Color(0x88707D8F)
          ..strokeWidth = .8,
      );
      canvas.drawPath(
        Path()
          ..moveTo(side * (w - 3), hood + 18)
          ..lineTo(side * (w - 4), deck + 5),
        paint
          ..color = const Color(0x885A6B80)
          ..strokeWidth = .7,
      );
      for (final y in [hood + 28, deck - 8]) {
        canvas.drawLine(
          Offset(side * (w - 5), y),
          Offset(side * (w - 5), y + 6),
          paint
            ..color = const Color(0xFFCFD9E4)
            ..strokeWidth = 1.4,
        );
      }
    }
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-w * .42, -l + 3, w * .42, -l + 8),
        const Radius.circular(3),
      ),
      paint..color = const Color(0xFF111B26),
    );
    if (hoodOpen) {
      final bay = Rect.fromLTRB(-w * .72, -l + 17, w * .72, hood - 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bay, const Radius.circular(7)),
        paint..color = const Color(0xFF060B10),
      );
      final engine = Rect.fromCenter(
        center: bay.center,
        width: bay.width * .57,
        height: bay.height * .62,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(engine, const Radius.circular(4)),
        paint
          ..shader = const LinearGradient(
            colors: [Color(0xFF637286), Color(0xFF1E2D3B), Color(0xFF425468)],
          ).createShader(engine),
      );
      paint.shader = null;
      for (var i = 0; i < 4; i++) {
        final y = engine.top + 4 + i * (engine.height - 8) / 4;
        canvas.drawLine(
          Offset(engine.left + 3, y),
          Offset(engine.right - 3, y),
          paint
            ..color = const Color(0xFF91A1B0)
            ..strokeWidth = 1,
        );
      }
      canvas.drawCircle(
        Offset(bay.right - 5, bay.top + 6),
        3,
        paint..color = const Color(0xFFFFC04F),
      );
      canvas.drawRect(
        Rect.fromLTWH(bay.left + 3, bay.top + 4, 8, 11),
        paint..color = const Color(0xFF3E5565),
      );
      canvas.drawCircle(
        Offset(bay.left + 6, bay.top + 5),
        1.5,
        paint..color = const Color(0xFFF36662),
      );
    }

    final cabin = Path()
      ..moveTo(-w * .77, hood)
      ..quadraticBezierTo(0, hood - 17, w * .77, hood)
      ..cubicTo(w * .86, hood + 19, w * .61, deck - 13, w * .66, deck + 8)
      ..quadraticBezierTo(0, deck + 22, -w * .66, deck + 8)
      ..cubicTo(-w * .61, deck - 13, -w * .86, hood + 19, -w * .77, hood)
      ..close();
    paint.style = PaintingStyle.fill;
    canvas.drawPath(
      cabin,
      paint
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF416078),
            Color(0xFF131D29),
            Color(0xFF243243),
            Color(0xFF090F17),
          ],
          stops: [0, .34, .55, 1],
        ).createShader(bodyBounds),
    );
    paint.shader = null;
    final roof = Path()
      ..moveTo(-w * .56, hood + 26)
      ..quadraticBezierTo(0, hood + 18, w * .56, hood + 26)
      ..lineTo(w * .53, deck - 10)
      ..quadraticBezierTo(0, deck - 4, -w * .53, deck - 10)
      ..close();
    canvas.drawPath(
      roof,
      paint
        ..shader = const LinearGradient(
          colors: [Color(0xFF151A22), Color(0xFF293240), Color(0xFF10161F)],
        ).createShader(bodyBounds),
    );
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = const Color(0x88647688);
    canvas.drawPath(roof, paint);

    for (final side in [-1.0, 1.0]) {
      final seam = Path()
        ..moveTo(side * w * .45, -l + 10)
        ..quadraticBezierTo(
          side * w * .68,
          hood - 11,
          side * w * .72,
          hood + 4,
        );
      canvas.drawPath(seam, paint..color = const Color(0x77535E6D));
      final x = side * (w - 9);
      final head = Path()
        ..moveTo(x * .72, -l + 6)
        ..quadraticBezierTo(
          x,
          -l + 6,
          side * (w - 3),
          -l + model.headSweep + 6,
        );
      final tail = Path()
        ..moveTo(x * .61, l - 6)
        ..quadraticBezierTo(
          x * 1.12,
          l - 6,
          side * (w - 4),
          l - model.tailSweep - 5,
        );
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 4.5;
      canvas.drawPath(head, paint..color = const Color(0xFF182332));
      canvas.drawPath(tail, paint..color = const Color(0xFF391522));
      paint.strokeWidth = 1.8 + lighting;
      canvas.drawPath(
        head,
        paint
          ..color = Color.lerp(
            const Color(0xFF7C9BB0),
            const Color(0xFFE5FAFF),
            lighting,
          )!,
      );
      canvas.drawPath(
        tail,
        paint
          ..color = Color.lerp(
            const Color(0xFFA74652),
            const Color(0xFFFF563D),
            lighting,
          )!,
      );
    }
    canvas.restore();
  }

  void _castLight(
    Canvas canvas,
    Offset light,
    double side, {
    required bool front,
  }) {
    final distance = front ? 42.0 : 18.0;
    final direction = front ? -1 : 1;
    final end = light.translate(side * (front ? 10 : 4), direction * distance);
    final path = Path()
      ..moveTo(light.dx - 3, light.dy)
      ..quadraticBezierTo(
        light.dx - 7,
        (light.dy + end.dy) / 2,
        end.dx - (front ? 14 : 10),
        end.dy,
      )
      ..lineTo(end.dx + (front ? 14 : 10), end.dy)
      ..quadraticBezierTo(
        light.dx + 7,
        (light.dy + end.dy) / 2,
        light.dx + 3,
        light.dy,
      )
      ..close();
    final tint = front ? const Color(0xFFB5DEFF) : const Color(0xFFFF3630);
    final bounds = Rect.fromCircle(center: light, radius: distance);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tint.withValues(alpha: lighting * .78),
            tint.withValues(alpha: lighting * .23),
            Colors.transparent,
          ],
          stops: const [0, .42, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _TopViewPainter oldDelegate) =>
      color != oldDelegate.color ||
      model != oldDelegate.model ||
      lighting != oldDelegate.lighting ||
      hoodOpen != oldDelegate.hoodOpen;
}
