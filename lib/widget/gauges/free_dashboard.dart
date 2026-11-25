import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../display_units.dart';
import '../compatible_vehicle_model.dart';
import '../dashboard_background.dart';

class FreeDashboard extends StatelessWidget {
  final ObdData data;
  final DashSettingsProvider settings;
  final String modelPath;

  const FreeDashboard({
    super.key,
    required this.data,
    required this.settings,
    required this.modelPath,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double sideWidth = screenWidth * 0.28;

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          DashboardBackground(
            backgroundImage: settings.backgroundImage,
            isAssetBackground: settings.isAssetBackground,
            opacity: .34,
          ),
          // Background (Light effect based on accent color)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: .58,
                  colors: [
                    settings.accentColor.withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Column: Logo, Clock and 3D Model
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _VehicleHeader(
                  brand: settings.selectedVehicle?.brand ?? 'DASHCORE',
                  accentColor: settings.accentColor,
                  logoPath: settings.vehicleLogoPath,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: CompatibleVehicleModel(
                    key: ValueKey(modelPath),
                    backgroundColor: Colors.transparent,
                    src: modelPath,
                    alt: "Vehicle 3D Model",
                    ar: false,
                    autoRotate: false,
                    cameraControls: true,
                    disableZoom: false,
                    disablePan: true,
                    cameraOrbit: '0deg 75deg 4.5m',
                    shadowIntensity: 0.1,
                    exposure: 1.0,
                    loading: Loading.eager,
                    defaultZoom: 2.05,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Left Panel: RPM and Temperature
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            width: sideWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NeedleGauge(
                  size: sideWidth * 0.9,
                  value: data.rpm.toDouble(),
                  maxValue: 8000,
                  label: 'RPM',
                  unit: 'r/min',
                  accentColor: settings.accentColor,
                  needleColor: settings.needleColor,
                  divisions: 8,
                ),
                const SizedBox(height: 20),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _CircularInfoGadget(
                    label: 'TEMP',
                    value: settings
                        .convertTemp(data.engineTemp)
                        .toStringAsFixed(0),
                    unit: settings.tempUnit == TemperatureUnit.celsius
                        ? '°C'
                        : '°F',
                    icon: Icons.thermostat_rounded,
                    color: Colors.cyanAccent,
                    progress: (data.engineTemp / 120).clamp(0.0, 1.0),
                  ),
                ),
              ],
            ),
          ),

          // Right Panel: Speedometer and Battery
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            width: sideWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NeedleGauge(
                  size: sideWidth * 0.9,
                  value: settings.displaySpeed(data.speed).toDouble(),
                  maxValue: 240,
                  label: 'SPEED',
                  unit: settings.speedUnitLabel,
                  accentColor: settings.accentColor,
                  needleColor: settings.needleColor,
                  divisions: 10,
                  centerValue: settings
                      .displaySpeed(data.speed)
                      .round()
                      .toString(),
                ),
                const SizedBox(height: 20),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _CircularInfoGadget(
                    label: 'BATT',
                    value: data.voltage.toStringAsFixed(1),
                    unit: 'V',
                    icon: Icons.bolt_rounded,
                    color: Colors.orangeAccent,
                    progress: ((data.voltage - 9) / 7).clamp(0.0, 1.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final String brand;
  final Color accentColor;
  final String? logoPath;

  const _VehicleHeader({
    required this.brand,
    required this.accentColor,
    this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Placeholder for Dynamic Logo
        Container(
          width: 45,
          height: 45,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: ClipOval(
            child: Center(
              child: logoPath != null
                  ? Image.file(File(logoPath!), fit: BoxFit.cover)
                  : Text(
                      brand.substring(0, 1),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        DashboardClock(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _NeedleGauge extends StatelessWidget {
  final double size;
  final double value;
  final double maxValue;
  final String label;
  final String unit;
  final Color accentColor;
  final Color needleColor;
  final int divisions;
  final String? centerValue;

  const _NeedleGauge({
    required this.size,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.unit,
    required this.accentColor,
    required this.needleColor,
    required this.divisions,
    this.centerValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.1);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ticks and Background
          CustomPaint(
            size: Size(size, size),
            painter: _GaugeBasePainter(
              accentColor: accentColor,
              divisions: divisions,
              maxValue: maxValue,
            ),
          ),

          // Center Info (if provided, for speedometer)
          if (centerValue != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerValue!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

          // Needle
          CustomPaint(
            size: Size(size, size),
            painter: _NeedlePainter(
              progress: progress,
              needleColor: needleColor,
            ),
          ),

          // Bottom Label (for RPM)
          if (centerValue == null)
            Positioned(
              bottom: size * 0.2,
              child: Column(
                children: [
                  Text(
                    (value / 1000).toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GaugeBasePainter extends CustomPainter {
  final Color accentColor;
  final int divisions;
  final double maxValue;

  _GaugeBasePainter({
    required this.accentColor,
    required this.divisions,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Draw ticks
    final tickPaint = Paint()..strokeWidth = 2;
    for (int i = 0; i <= divisions * 4; i++) {
      final isMajor = i % 4 == 0;
      final angle = startAngle + (sweepAngle * (i / (divisions * 4)));

      tickPaint.color = isMajor ? accentColor.withOpacity(0.5) : Colors.white24;
      final tickLength = isMajor ? 12.0 : 6.0;

      canvas.drawLine(
        center +
            Offset(
              math.cos(angle) * (radius - 5),
              math.sin(angle) * (radius - 5),
            ),
        center +
            Offset(
              math.cos(angle) * (radius - 5 - tickLength),
              math.sin(angle) * (radius - 5 - tickLength),
            ),
        tickPaint,
      );

      if (isMajor) {
        final val = (i / 4).toInt();
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$val',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: size.width * 0.08,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRadius = radius - 30;
        final labelOffset =
            center +
            Offset(
              math.cos(angle) * labelRadius - textPainter.width / 2,
              math.sin(angle) * labelRadius - textPainter.height / 2,
            );
        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {
  final double progress;
  final Color needleColor;

  _NeedlePainter({required this.progress, required this.needleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final angle = startAngle + (sweepAngle * progress);
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center + Offset(math.cos(angle) * 10, math.sin(angle) * 10),
      center +
          Offset(
            math.cos(angle) * (radius - 15),
            math.sin(angle) * (radius - 15),
          ),
      needlePaint,
    );

    // Center cap
    canvas.drawCircle(center, 8, Paint()..color = Colors.black);
    canvas.drawCircle(center, 5, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CircularInfoGadget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double progress;

  const _CircularInfoGadget({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
