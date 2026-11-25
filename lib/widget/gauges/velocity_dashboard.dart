import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../compatible_vehicle_model.dart';
import '../dashboard_background.dart';
import '../tutorial/tutorial_keys.dart';
import '../vehicle_stage.dart';

class VelocityDashboard extends StatelessWidget {
  const VelocityDashboard({
    super.key,
    required this.style,
    required this.settings,
    required this.data,
    required this.sourceLabel,
    this.engineAvailable = true,
    this.preview = false,
    this.onGarage,
  });

  factory VelocityDashboard.preview(
    DashboardStyle style,
    DashSettingsProvider settings,
  ) => VelocityDashboard(
    style: style,
    settings: settings,
    data: const ObdData(
      speed: 86,
      rpm: 2800,
      engineTemp: 91,
      voltage: 13.8,
      fuelLevel: 72,
    ),
    sourceLabel: 'VISTA PREVIA',
    preview: true,
  );

  final DashboardStyle style;
  final DashSettingsProvider settings;
  final ObdData data;
  final String sourceLabel;
  final bool engineAvailable;
  final bool preview;
  final VoidCallback? onGarage;

  bool get _carbon => style == DashboardStyle.carbonPulse;

  @override
  Widget build(BuildContext context) {
    final unit = settings.speedUnitLabel;
    final speed = settings.displaySpeed(data.speed).round();
    final limit = unit.toUpperCase() == 'MPH' ? 160 : 260;
    final accent = settings.accentColor;
    final secondary = _carbon
        ? const Color(0xFFB5E276)
        : const Color(0xFF7B9CFF);
    final motion =
        !preview &&
        !settings.reduceMotion &&
        MediaQuery.maybeOf(context)?.disableAnimations != true;
    final vehicle = settings.selectedVehicle;
    final thumbnail = catalogVehiclePreview(vehicle?.modelUrl ?? '');
    final vehicleImage = thumbnail != null && !preview
        ? Image.asset(thumbnail, fit: BoxFit.contain, cacheWidth: 520)
        : VehiclePhoto(
            artwork: preview ? null : vehicle?.artworkPath,
            demo: preview || vehicle == null,
            reduceMotion: !motion,
          );

    final artwork = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [secondary.withValues(alpha: .18), Colors.transparent],
            center: const Alignment(0, .5),
          ),
        ),
        child: vehicleImage,
      ),
    );
    final speedDial = _Instrument(
      key: preview ? null : TutorialKeys.speedGaugeKey,
      value: speed.toDouble(),
      max: limit.toDouble(),
      valueLabel: '$speed',
      unit: unit,
      label: 'VELOCIDAD',
      color: accent,
      motion: motion,
      needle: _carbon,
    );
    final rpmDial = _Instrument(
      value: engineAvailable ? data.rpm / 1000 : 0,
      max: 8,
      valueLabel: engineAvailable ? (data.rpm / 1000).toStringAsFixed(1) : '—',
      unit: '×1000 RPM',
      label: 'MOTOR',
      color: data.rpm >= 6500 && engineAvailable
          ? const Color(0xFFFF7060)
          : secondary,
      motion: motion,
      mirrored: !_carbon,
    );
    final fuel = settings.useSimulatedFuel
        ? settings.simulatedFuelLevel.round()
        : data.fuelLevel;
    final temperature = settings.convertTemp(data.engineTemp).round();
    final tempUnit = settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F';
    return Semantics(
      label: _carbon ? 'Carbon Pulse' : 'Apex GT',
      child: ColoredBox(
        color: const Color(0xFF080D14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!preview)
              DashboardBackground(
                backgroundImage: settings.backgroundImage,
                isAssetBackground: settings.isAssetBackground,
              ),
            FittedBox(
              child: SizedBox(
                width: 1000,
                height: 410,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.25,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(width: 3, height: 26, color: accent),
                            const SizedBox(width: 13),
                            Text(
                              _carbon ? 'CARBON PULSE' : 'APEX GT',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Color(0xFFECF5FC),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                sourceLabel,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB9CFDE),
                                ),
                              ),
                            ),
                            if (onGarage != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  color: accent,
                                  onPressed: onGarage,
                                  tooltip: 'Mi vehículo',
                                  icon: const Icon(
                                    Icons.directions_car_outlined,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFF253542)),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: _carbon ? 44 : 31,
                                child: speedDial,
                              ),
                              Expanded(flex: _carbon ? 34 : 38, child: artwork),
                              Expanded(flex: _carbon ? 22 : 31, child: rpmDial),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFF253542)),
                        const SizedBox(height: 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Readout(
                              Icons.thermostat_outlined,
                              'MOTOR',
                              engineAvailable ? '$temperature $tempUnit' : '—',
                              key: preview
                                  ? null
                                  : TutorialKeys.temperatureGaugeKey,
                            ),
                            _Readout(
                              Icons.bolt_outlined,
                              'BATERÍA',
                              engineAvailable
                                  ? '${data.voltage.toStringAsFixed(1)} V'
                                  : '—',
                              key: preview
                                  ? null
                                  : TutorialKeys.voltageGaugeKey,
                            ),
                            _Readout(
                              Icons.local_gas_station_outlined,
                              'COMBUSTIBLE',
                              engineAvailable || settings.useSimulatedFuel
                                  ? '$fuel%'
                                  : '—',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout(this.icon, this.label, this.value, {super.key});

  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 21, color: const Color(0xFFA2B9C9)),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFFA2B9C9)),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFFEEF8FE),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

class _Instrument extends StatelessWidget {
  const _Instrument({
    super.key,
    required this.value,
    required this.max,
    required this.valueLabel,
    required this.unit,
    required this.label,
    required this.color,
    required this.motion,
    this.needle = false,
    this.mirrored = false,
  });

  final double value, max;
  final String valueLabel, unit, label;
  final Color color;
  final bool motion, needle, mirrored;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        child: CustomPaint(painter: _Scale(color, needle, mirrored, null)),
      ),
      RepaintBoundary(
        child: motion
            ? TweenAnimationBuilder<double>(
                tween: Tween(end: (value / max).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 115),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => CustomPaint(
                  painter: _Scale(color, needle, mirrored, progress),
                ),
              )
            : CustomPaint(
                painter: _Scale(
                  color,
                  needle,
                  mirrored,
                  (value / max).clamp(0.0, 1.0),
                ),
              ),
      ),
      Center(
        child: FractionallySizedBox(
          widthFactor: .67,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Color(0xFFADC6D7),
                  ),
                ),
                Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: needle ? 100 : 81,
                    height: 1.08,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Scale extends CustomPainter {
  const _Scale(this.color, this.needle, this.mirrored, this.progress);

  final Color color;
  final bool needle, mirrored;
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .43;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * .79, sweep = math.pi * 1.42;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final value = progress;
    if (value != null) {
      paint
        ..color = color
        ..strokeWidth = needle ? 4 : 7;
      if (value > 0) {
        final visible = sweep * value;
        canvas.drawArc(
          rect,
          mirrored ? start + sweep - visible : start,
          visible,
          false,
          paint,
        );
      }
      if (needle) {
        final angle = start + sweep * value;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + direction * (radius - 25),
          center + direction * (radius + 8),
          paint
            ..color = const Color(0xFFFF755F)
            ..strokeWidth = 4,
        );
      }
      return;
    }
    if (needle) {
      canvas.drawCircle(
        center,
        radius + 9,
        paint
          ..color = const Color(0xFF284451)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        center,
        radius - 34,
        paint
          ..color = const Color(0xFF192B36)
          ..strokeWidth = 1,
      );
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius - 36)),
      );
      paint
        ..color = const Color(0xFF121F2A)
        ..strokeWidth = 1.5;
      for (double x = -2 * radius; x <= 2 * radius; x += 7) {
        canvas.drawLine(
          center + Offset(x, radius),
          center + Offset(x + radius, -radius),
          paint,
        );
      }
      canvas.restore();
    }
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      paint
        ..color = const Color(0xFF304956)
        ..strokeWidth = 6,
    );
    for (var tick = 0; tick <= 40; tick++) {
      final angle = start + sweep * tick / 40;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final major = tick % 5 == 0;
      canvas.drawLine(
        center + direction * (radius - 9),
        center + direction * (radius - (major ? 22 : 15)),
        paint
          ..color = major ? const Color(0xFFBCD3E0) : const Color(0xFF42606F)
          ..strokeWidth = major ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Scale oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.needle != needle ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.color != color;
}
