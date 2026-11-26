import 'dart:math' as math;

import 'package:flutter/material.dart';

enum IgnitionProfile {
  dashCore('DashCore', Color(0xFF83DEEF), 0),
  honda('Honda', Color(0xFFFF696F), 1),
  hyundai('Hyundai', Color(0xFF83B9FF), 2),
  kia('Kia', Color(0xFFE8F3FC), 3),
  nissan('Nissan', Color(0xFFFFAE76), 4);

  const IgnitionProfile(this.label, this.light, this.pattern);

  final String label;
  final Color light;
  final int pattern;

  static IgnitionProfile forBrand(String? brand) {
    final name = brand?.trim().toLowerCase() ?? '';
    return values.firstWhere(
      (profile) => name.startsWith(profile.label.toLowerCase()),
      orElse: () => dashCore,
    );
  }
}

class AnimatedStartupSplash extends StatefulWidget {
  const AnimatedStartupSplash({
    super.key,
    required this.child,
    this.ready = true,
    this.dashboardReady = true,
    this.profile = IgnitionProfile.dashCore,
    this.enabled = true,
    this.accSleeping = false,
    this.compact = false,
  });

  final Widget child;
  final bool ready, dashboardReady, enabled, accSleeping, compact;
  final IgnitionProfile profile;

  @override
  State<AnimatedStartupSplash> createState() => _AnimatedStartupSplashState();
}

class _AnimatedStartupSplashState extends State<AnimatedStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ignition = AnimationController(vsync: this);
  bool _visible = true;
  bool _started = false;
  late IgnitionProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _ignition.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant AnimatedStartupSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accSleeping && !widget.accSleeping) {
      _ignition.stop();
      _started = false;
      _visible = true;
      _profile = widget.profile;
      _ignition.value = 0;
    }
    _update();
  }

  void _update() {
    // Before preferences load, draw the first dark frame. Start with the saved
    // brand as soon as initialization finishes.
    if (!_visible || !widget.ready) return;
    if (!widget.enabled ||
        widget.accSleeping ||
        MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _ignition.stop();
      _visible = false;
      return;
    }
    if (_started) return;
    _started = true;
    _profile = widget.profile;
    _ignition.duration = widget.compact
        ? const Duration(milliseconds: 540)
        : const Duration(milliseconds: 940);
    _ignition.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _visible = false);
  }

  @override
  void dispose() {
    _ignition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible || !widget.dashboardReady;
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !visible,
          child: Offstage(offstage: visible, child: widget.child),
        ),
        if (visible)
          Semantics(
            label: widget.ready
                ? 'Encendido de ${_profile.label}'
                : 'Cargando DashCore',
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _IgnitionPainter(_ignition, _profile),
                child: const SizedBox.expand(),
              ),
            ),
          ),
      ],
    );
  }
}

class _IgnitionPainter extends CustomPainter {
  _IgnitionPainter(this.animation, this.profile) : super(repaint: animation);

  final Animation<double> animation;
  final IgnitionProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = animation.value;
    final rise = Curves.easeOutCubic.transform(
      ((phase - .07) / .36).clamp(0.0, 1.0),
    );
    final sweep = Curves.easeInOutCubic.transform(
      ((phase - .23) / .60).clamp(0.0, 1.0),
    );
    final intensity = rise * (1 - .28 * sweep);
    final scale = math.min(size.width / 900, size.height / 450);
    final center = Offset(size.width / 2, size.height / 2);
    final light = profile.light;
    final paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xFF070B11));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    const housing = Rect.fromLTWH(-400, -155, 800, 304);
    final surround = RRect.fromRectAndRadius(
      housing,
      const Radius.circular(86),
    );
    canvas.drawRRect(
      surround,
      paint
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2C3A), Color(0xFF080D14), Color(0xFF0D1722)],
          stops: [0, .40, 1],
        ).createShader(housing),
    );
    canvas.drawRRect(
      surround,
      paint
        ..shader = null
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF273341),
    );
    paint.style = PaintingStyle.fill;
    if (intensity > 0) {
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.scale(side, 1);
        _drawInstrument(canvas, paint, light, intensity, sweep);
        canvas.restore();
      }
    }
    final labelOpacity =
        .18 +
        .82 * Curves.easeOut.transform(((phase - .17) / .26).clamp(0.0, 1.0));
    if (labelOpacity > 0) {
      final text = TextPainter(
        text: TextSpan(
          text: profile.label.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFFEAF3FA).withValues(alpha: labelOpacity),
            fontFamily: 'Inter',
            fontSize: 34,
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2 + 4));
      text.dispose();
    }
    canvas.restore();
  }

  void _drawInstrument(
    Canvas canvas,
    Paint paint,
    Color light,
    double power,
    double progress,
  ) {
    const eye = Rect.fromLTWH(164, -82, 194, 164);
    paint
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          light.withValues(alpha: power * .20),
          light.withValues(alpha: 0),
        ],
      ).createShader(eye);
    canvas.drawOval(eye, paint);
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = light.withValues(alpha: power);
    switch (profile.pattern) {
      case 1:
        final angle = -2.35 + progress * 3.8;
        canvas.drawArc(eye, -2.35, 3.8 * progress, false, paint);
        final tip = Offset(
          eye.center.dx + 71 * math.cos(angle),
          56 * math.sin(angle),
        );
        canvas.drawLine(
          eye.center,
          tip,
          paint..color = light.withValues(alpha: power * .68),
        );
      case 2:
        for (var i = 0; i < 12; i++) {
          final opacity = ((progress * 13 - i) / 2).clamp(.10, 1.0) * power;
          final x = 172 + i * 15.0;
          canvas.drawLine(
            Offset(x, -45 + i * 4),
            Offset(x + 4, -37 + i * 4),
            paint..color = light.withValues(alpha: opacity),
          );
        }
      case 3:
        final x = 174 + 178 * progress;
        canvas.drawPath(
          Path()
            ..moveTo(174, 30)
            ..lineTo(216, 30)
            ..lineTo(245, -22)
            ..lineTo(x.clamp(245.0, 352.0), -22),
          paint,
        );
        canvas.drawLine(
          Offset(174 + (1 - progress) * 58, 44),
          Offset(x.clamp(235.0, 352.0), 44),
          paint..color = light.withValues(alpha: power * .38),
        );
      case 4:
        canvas.drawArc(eye.deflate(7), -1.55, 2.9 * progress, false, paint);
        canvas.drawArc(
          eye.deflate(16),
          -.95,
          2.0 * progress,
          false,
          paint..color = light.withValues(alpha: power * .42),
        );
      default:
        canvas.drawArc(eye, -1.87, 3.35 * progress, false, paint);
        canvas.drawLine(
          Offset(177 + 48 * (1 - progress), 69),
          Offset(325 + 24 * progress, 69),
          paint..color = light.withValues(alpha: power * .50),
        );
    }
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _IgnitionPainter oldDelegate) =>
      profile != oldDelegate.profile || animation != oldDelegate.animation;
}
