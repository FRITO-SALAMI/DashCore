import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import '../dashboard_brand_mark.dart';

import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../display_units.dart';
import '../music_hub.dart';
import '../tutorial/tutorial_keys.dart';
import '../dashboard_vehicle.dart';

class NightDriveDashboard extends StatelessWidget {
  const NightDriveDashboard({
    super.key,
    required this.data,
    required this.settings,
    required this.sourceLabel,
    this.preview = false,
  });

  final ObdData data;
  final DashSettingsProvider settings;
  final String sourceLabel;
  final bool preview;
  static const cyan = Color(0xFF28D6F7);

  @override
  Widget build(BuildContext context) {
    final speed = settings.displaySpeed(data.speed).round();
    final mph = settings.distanceUnit == DistanceUnit.miles;
    return ColoredBox(
      color: const Color(0xFF040B11),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1120,
            height: 500,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, .13),
                  radius: .8,
                  colors: [
                    Color(0xFF112D3A),
                    Color(0xFF071721),
                    Color(0xFF040B11),
                  ],
                  stops: [0, .49, 1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 11, 28, 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const DashboardBrandMark(width: 56),
                        const Spacer(),
                        Text(
                          sourceLabel,
                          style: const TextStyle(
                            color: Color(0xFFB8CEDA),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(width: 24),
                        if (preview)
                          const Text('08:45', style: _clockStyle)
                        else
                          const DashboardClock(style: _clockStyle),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF26BFD6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SizedBox(width: double.infinity, height: 1),
                    ),
                    const SizedBox(height: 9),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _SportDial(
                                    value: data.rpm / 1000,
                                    max: 8,
                                    divisions: 8,
                                    tachometer: true,
                                    digital: (data.rpm / 1000).toStringAsFixed(
                                      1,
                                    ),
                                    unit: 'RPM ×1000',
                                  ),
                                ),
                                KeyedSubtree(
                                  key: preview
                                      ? null
                                      : TutorialKeys.temperatureGaugeKey,
                                  child: _metric(
                                    Icons.thermostat_rounded,
                                    'Temp. motor',
                                    '${settings.convertTemp(data.engineTemp).round()}',
                                    settings.tempUnit == TemperatureUnit.celsius
                                        ? '°C'
                                        : '°F',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF0B1C25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: DashboardVehicle(
                                preview: preview,
                                colorHex: preview
                                    ? '#D5DDE9'
                                    : settings.vehicleColorHex,
                                vehicle: preview
                                    ? null
                                    : settings.selectedVehicle,
                                source: preview
                                    ? 'optima2012_lite.glb'
                                    : settings.modelPath,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Expanded(
                                  child: KeyedSubtree(
                                    key: preview
                                        ? null
                                        : TutorialKeys.speedGaugeKey,
                                    child: _SportDial(
                                      value: speed.toDouble(),
                                      max: mph ? 140 : 220,
                                      divisions: mph ? 7 : 11,
                                      digital: '$speed',
                                      unit: settings.speedUnitLabel,
                                    ),
                                  ),
                                ),
                                KeyedSubtree(
                                  key: preview
                                      ? null
                                      : TutorialKeys.voltageGaugeKey,
                                  child: _metric(
                                    Icons.battery_charging_full_rounded,
                                    'Voltaje batería',
                                    data.voltage.toStringAsFixed(1),
                                    'V',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const MusicHub(accentColor: Color(0xFF9BB6C5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _clockStyle = TextStyle(
    color: Colors.white,
    fontSize: 27,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  Widget _metric(IconData icon, String label, String value, String unit) {
    return Container(
      height: 67,
      width: 255,
      decoration: BoxDecoration(
        color: const Color(0xFF091922),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF2B5364)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cyan, size: 26),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFFB8CEDB), fontSize: 12),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFF9DCAD9),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportDial extends StatelessWidget {
  const _SportDial({
    required this.value,
    required this.max,
    required this.divisions,
    required this.digital,
    required this.unit,
    this.tachometer = false,
  });
  final double value;
  final int max, divisions;
  final String digital, unit;
  final bool tachometer;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: 1.06,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _DialFace(max, divisions, tachometer)),
          ),
          RepaintBoundary(
            child: CustomPaint(painter: _DialNeedle((value / max).clamp(0, 1))),
          ),
          FractionallySizedBox(
            widthFactor: .56,
            heightFactor: .45,
            alignment: const Alignment(0, .16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    digital,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: tachometer ? 62 : 87,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: NightDriveDashboard.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _start = math.pi * .76;
const _sweep = math.pi * 1.48;
Offset _dialPoint(Offset center, double radius, double angle) =>
    center + Offset(math.cos(angle), math.sin(angle)) * radius;

class _DialFace extends CustomPainter {
  const _DialFace(this.max, this.divisions, this.tachometer);
  final int max, divisions;
  final bool tachometer;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .45;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFF153845);
    canvas.drawArc(bounds, _start, _sweep, false, paint);
    paint
      ..strokeWidth = 3
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5DEEFF), Color(0xFF29A8C5), Color(0xFF1A566C)],
      ).createShader(bounds);
    canvas.drawArc(bounds, _start, _sweep, false, paint);
    paint.shader = null;
    if (tachometer) {
      canvas.drawArc(
        bounds,
        _start + _sweep * .8,
        _sweep * .2,
        false,
        paint..color = const Color(0xFFFF505C),
      );
    }
    for (var i = 0; i <= divisions * 4; i++) {
      final major = i % 4 == 0;
      final angle = _start + _sweep * i / (divisions * 4);
      canvas.drawLine(
        _dialPoint(center, radius - (major ? 15 : 10), angle),
        _dialPoint(center, radius - 4, angle),
        paint
          ..color = major ? const Color(0xFFD2E8EF) : const Color(0xFF4F7488)
          ..strokeWidth = major ? 2 : 1,
      );
      if (!major) continue;
      final label = TextPainter(
        text: TextSpan(
          text: '${(i * max / (divisions * 4)).round()}',
          style: const TextStyle(
            color: Color(0xFFDEEDF2),
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        _dialPoint(center, radius - 26, angle) - label.size.center(Offset.zero),
      );
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _DialFace oldDelegate) =>
      max != oldDelegate.max ||
      divisions != oldDelegate.divisions ||
      tachometer != oldDelegate.tachometer;
}

class _DialNeedle extends CustomPainter {
  const _DialNeedle(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .45;
    final angle = _start + _sweep * progress;
    canvas.drawLine(
      _dialPoint(center, radius - 41, angle),
      _dialPoint(center, radius + 1, angle),
      Paint()
        ..color = NightDriveDashboard.cyan
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DialNeedle oldDelegate) =>
      progress != oldDelegate.progress;
}

class NightDrivePreview extends StatelessWidget {
  const NightDrivePreview({super.key, required this.settings});
  final DashSettingsProvider settings;

  @override
  Widget build(BuildContext context) => NightDriveDashboard(
    data: const ObdData(speed: 78, rpm: 2850, engineTemp: 86, voltage: 13.8),
    settings: settings,
    sourceLabel: 'OBD II',
    preview: true,
  );
}
