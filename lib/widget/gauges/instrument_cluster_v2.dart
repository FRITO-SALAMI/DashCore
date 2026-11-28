import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../dashboard_brand_mark.dart';
import '../dashboard_background.dart';
import '../tutorial/tutorial_keys.dart';
import '../vehicle_stage.dart';

enum ClusterDesign {
  sport,
  modern,
  racing,
  glow,
  hellish,
  retro,
  classic,
  electric,
  purple,
  hud,
}

/// The standard instruments use native paint and text only: no WebView,
/// shaders, network, timers, or continuous animation controllers.
class InstrumentClusterV2 extends StatelessWidget {
  const InstrumentClusterV2({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.design = ClusterDesign.sport,
    this.accent = const Color(0xFF00C8FF),
    this.speedUnit = 'KM/H',
    this.tempUnit = '°C',
    this.backgroundImage,
    this.isAssetBackground = true,
    this.engineAvailable = true,
    this.sourceLabel,
    this.registerTutorialTargets = true,
    this.reduceMotion = true,
    this.rearArtwork,
  });
  final int speed, rpm, coolantTemp;
  final double voltage;
  final ClusterDesign design;
  final Color accent;
  final String speedUnit, tempUnit;
  final String? backgroundImage;
  final String? sourceLabel;
  final bool isAssetBackground, engineAvailable;
  final bool registerTutorialTargets;
  final bool reduceMotion;
  final String? rearArtwork;

  int get _dialLimit => speedUnit.toUpperCase() == 'MPH' ? 160 : 240;
  double get _dialProgress => speed.clamp(0, _dialLimit) / _dialLimit;

  Color get _color => switch (design) {
    ClusterDesign.glow => const Color(0xFFFF4966),
    ClusterDesign.hellish => const Color(0xFFFF733D),
    ClusterDesign.retro => const Color(0xFFEBC26B),
    ClusterDesign.purple => const Color(0xFFB7A1FF),
    ClusterDesign.electric => const Color(0xFF60E6C0),
    _ => accent,
  };
  String get _name => switch (design) {
    ClusterDesign.sport => 'SPORT',
    ClusterDesign.modern => 'MODERN',
    ClusterDesign.racing => 'RACING',
    ClusterDesign.glow => 'GLOW RED',
    ClusterDesign.hellish => 'HELLISH',
    ClusterDesign.retro => 'RETRO LCD',
    ClusterDesign.classic => 'CLASSIC SPORT',
    ClusterDesign.electric => 'EV CLUSTER',
    ClusterDesign.purple => 'PURPLE DRIVE',
    ClusterDesign.hud => 'RACING HUD',
  };

  @override
  Widget build(BuildContext context) {
    final color = rpm >= 6500 && engineAvailable
        ? const Color(0xFFFF6472)
        : _color;
    final digital = {
      ClusterDesign.modern,
      ClusterDesign.racing,
      ClusterDesign.retro,
      ClusterDesign.purple,
      ClusterDesign.hud,
    }.contains(design);
    final gauges = digital ? _digital(color) : _analog(color);
    return Semantics(
      label: 'DashCore $_name',
      child: ColoredBox(
        color: const Color(0xFF070B10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Preserve the instrument proportions on old 640x360/800x480 units.
            // The scale also fits short windows without overflowing a Column.
            return Stack(
              fit: StackFit.expand,
              children: [
                DashboardBackground(
                  backgroundImage: backgroundImage,
                  isAssetBackground: isAssetBackground,
                  opacity: .12,
                ),
                FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 960,
                    height: 400,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
                      child: Column(
                        children: [
                          _header(color),
                          const SizedBox(height: 20),
                          Expanded(
                            child: rearArtwork == null
                                ? gauges
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(flex: 8, child: gauges),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: RepaintBoundary(
                                          child: VehiclePhoto(
                                            artwork: rearArtwork,
                                            reduceMotion: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _footer(color),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(Color color) => Row(
    children: [
      Container(width: 4, height: 24, color: color),
      const SizedBox(width: 12),
      const DashboardBrandMark(width: 38),
    ],
  );

  Widget _analog(Color color) => Row(
    children: [
      SizedBox(
        width: 174,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KeyedSubtree(
              key: registerTutorialTargets
                  ? TutorialKeys.temperatureGaugeKey
                  : null,
              child: _metric(
                'COOLANT',
                engineAvailable ? '$coolantTemp' : '—',
                tempUnit,
                Icons.thermostat_rounded,
                color,
              ),
            ),
            const SizedBox(height: 16),
            _bar(
              engineAvailable
                  ? coolantTemp / (tempUnit == '°F' ? 260 : 130)
                  : 0,
              color,
            ),
          ],
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DialPainter(
                    color,
                    null,
                    design == ClusterDesign.classic,
                    _dialLimit,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: reduceMotion
                    ? CustomPaint(
                        painter: _DialPainter(
                          color,
                          _dialProgress,
                          design == ClusterDesign.classic,
                          _dialLimit,
                        ),
                      )
                    : TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: _dialProgress),
                        duration: const Duration(milliseconds: 115),
                        curve: Curves.easeOutCubic,
                        builder: (context, progress, child) => CustomPaint(
                          painter: _DialPainter(
                            color,
                            progress,
                            design == ClusterDesign.classic,
                            _dialLimit,
                          ),
                        ),
                      ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _speed(color, size: 100),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 20),
      SizedBox(
        width: 174,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KeyedSubtree(
              key: registerTutorialTargets
                  ? TutorialKeys.voltageGaugeKey
                  : null,
              child: _metric(
                'BATTERY',
                engineAvailable ? voltage.toStringAsFixed(1) : '—',
                'V',
                Icons.bolt_rounded,
                color,
              ),
            ),
            const SizedBox(height: 16),
            _bar(engineAvailable ? (voltage - 9) / 7 : 0, color),
          ],
        ),
      ),
    ],
  );

  Widget _digital(Color color) => Column(
    children: [
      if (design == ClusterDesign.racing || design == ClusterDesign.hud) ...[
        _rpm(color),
        const SizedBox(height: 12),
      ],
      Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _speed(color, size: 134),
              ),
            ),
            Container(width: 1, height: 150, color: const Color(0xFF23303D)),
            const SizedBox(width: 34),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KeyedSubtree(
                    key: registerTutorialTargets
                        ? TutorialKeys.temperatureGaugeKey
                        : null,
                    child: _metric(
                      'COOLANT',
                      engineAvailable ? '$coolantTemp' : '—',
                      tempUnit,
                      Icons.thermostat_rounded,
                      color,
                      horizontal: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  KeyedSubtree(
                    key: registerTutorialTargets
                        ? TutorialKeys.voltageGaugeKey
                        : null,
                    child: _metric(
                      'BATTERY',
                      engineAvailable ? voltage.toStringAsFixed(1) : '—',
                      'V',
                      Icons.bolt_rounded,
                      color,
                      horizontal: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _speed(Color color, {required double size}) => KeyedSubtree(
    key: registerTutorialTargets ? TutorialKeys.speedGaugeKey : null,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$speed',
          style: TextStyle(
            color: design == ClusterDesign.retro
                ? color
                : const Color(0xFFF1F5FA),
            fontFamily: design == ClusterDesign.retro ? 'monospace' : 'Inter',
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          speedUnit,
          style: const TextStyle(
            color: Color(0xFF92A2B5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
      ],
    ),
  );

  Widget _metric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color, {
    bool horizontal = false,
  }) {
    final reading = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFEDF2F8),
              fontSize: 38,
              fontWeight: FontWeight.w700,
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            unit,
            style: const TextStyle(color: Color(0xFF92A2B5), fontSize: 15),
          ),
        ],
      ),
    );
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.8,
            color: Color(0xFF92A2B5),
          ),
        ),
      ],
    );
    return horizontal
        ? Row(
            children: [
              Expanded(child: title),
              Flexible(child: reading),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [title, const SizedBox(height: 12), reading],
          );
  }

  Widget _bar(double value, Color color) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 3,
      backgroundColor: const Color(0xFF24303E),
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );

  Widget _rpm(Color color) => KeyedSubtree(
    key: registerTutorialTargets ? TutorialKeys.rpmGaugeKey : null,
    child: Row(
      children: [
        Text(
          engineAvailable ? '$rpm' : '—',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'RPM',
          style: TextStyle(
            color: Color(0xFF92A2B5),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: _bar(engineAvailable ? rpm / 8000 : 0, color)),
        const SizedBox(width: 12),
        const Text(
          '8',
          style: TextStyle(color: Color(0xFF92A2B5), fontSize: 12),
        ),
      ],
    ),
  );

  Widget _footer(Color color) => Column(
    children: [
      const Divider(color: Color(0xFF23303D), height: 1),
      const SizedBox(height: 14),
      Row(
        children: [
          Icon(
            engineAvailable ? Icons.sensors_rounded : Icons.gps_fixed_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            sourceLabel ??
                (engineAvailable ? 'VEHICLE INSTRUMENTS' : 'GPS · LOCAL'),
            style: const TextStyle(
              color: Color(0xFF92A2B5),
              fontSize: 10,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 36),
          if (design != ClusterDesign.racing && design != ClusterDesign.hud)
            Expanded(child: _rpm(color))
          else
            const Spacer(),
        ],
      ),
    ],
  );
}

class _DialPainter extends CustomPainter {
  const _DialPainter(this.color, this.progress, this.classic, this.limit);
  final Color color;
  final double? progress;
  final bool classic;
  final int limit;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .53);
    final radius = math.min(size.width / 2, size.height * .52) - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * .78, sweep = math.pi * 1.44;
    final value = progress;
    if (value != null) {
      if (value > 0)
        canvas.drawArc(
          rect,
          start,
          sweep * value,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = classic ? 4 : 9
            ..strokeCap = StrokeCap.round,
        );
      return;
    }
    final track = Paint()
      ..color = const Color(0xFF202C3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = classic ? 3 : 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);
    for (var i = 0; i <= 48; i++) {
      final angle = start + sweep * i / 48;
      final major = i % 6 == 0;
      final outer = radius - 13, inner = outer - (major ? 12 : 5);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        Paint()
          ..color = major ? const Color(0xFF91A2B8) : const Color(0xFF334252)
          ..strokeWidth = major ? 2 : 1,
      );
      if (classic && major) {
        final label = TextPainter(
          text: TextSpan(
            text: '${i * limit ~/ 48}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFA7B6C7)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * (inner - 13);
        label.paint(canvas, point - Offset(label.width / 2, label.height / 2));
        label.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      color != oldDelegate.color ||
      progress != oldDelegate.progress ||
      classic != oldDelegate.classic ||
      limit != oldDelegate.limit;
}
