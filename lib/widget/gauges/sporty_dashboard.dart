import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../dashboard_background.dart';

class SportyDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
  final Color needleColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String tempUnit;

  const SportyDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    required this.accentColor,
    this.needleColor = Colors.redAccent,
    this.backgroundImage,
    this.isAssetBackground = true,
    this.tempUnit = '°C',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompetitive = rpm > 5000;
          final mainGaugeSize = constraints.maxHeight * 0.85;
          final sideGaugeSize = constraints.maxHeight * 0.6;

          return Stack(
            alignment: Alignment.center,
            children: [
              DashboardBackground(
                backgroundImage: backgroundImage,
                isAssetBackground: isAssetBackground,
              ),

              // Left Gauge (Coolant)
              Positioned(
                left: -sideGaugeSize * 0.2,
                child: Opacity(
                  opacity: 0.8,
                  child: _CircularSideGauge(
                    size: sideGaugeSize,
                    value: coolantTemp.toDouble(),
                    maxValue: tempUnit == '°C' ? 130 : 250,
                    label: 'TEMP',
                    unit: tempUnit,
                    accentColor: Colors.cyanAccent,
                    icon: Icons.thermostat,
                  ),
                ),
              ),

              // Right Gauge (Battery)
              Positioned(
                right: -sideGaugeSize * 0.2,
                child: Opacity(
                  opacity: 0.8,
                  child: _CircularSideGauge(
                    size: sideGaugeSize,
                    value: voltage,
                    maxValue: 16,
                    minValue: 9,
                    label: 'VOLT',
                    unit: 'V',
                    accentColor: Colors.orangeAccent,
                    icon: Icons.bolt,
                  ),
                ),
              ),

              // Main Gauge (Speed & RPM)
              Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isCompetitive ? 1.05 : 1.0,
                  child: SizedBox(
                    width: mainGaugeSize,
                    height: mainGaugeSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(mainGaugeSize),
                          painter: _RealDashRpmPainter(
                            rpm: rpm,
                            accentColor: isCompetitive ? Colors.redAccent : accentColor,
                            needleColor: needleColor,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$speed',
                              style: TextStyle(
                                color: isCompetitive ? Colors.redAccent : Colors.white,
                                fontSize: mainGaugeSize * 0.28,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: isCompetitive ? Colors.red : Colors.blueAccent.withOpacity(0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'KM/H',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: mainGaugeSize * 0.04,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _calculateGear(speed, rpm),
                              style: TextStyle(
                                color: isCompetitive ? Colors.redAccent : accentColor,
                                fontSize: mainGaugeSize * 0.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Warnings
              Positioned(
                top: 20,
                child: Row(
                  children: [
                    _WarningIcon(icon: Icons.light_mode, color: Colors.green, isActive: speed > 0, size: 30),
                    const SizedBox(width: 30),
                    _WarningIcon(icon: Icons.oil_barrel, color: Colors.red, isActive: rpm > 7000, size: 30),
                    const SizedBox(width: 30),
                    _WarningIcon(icon: Icons.warning_amber_rounded, color: Colors.yellow, isActive: coolantTemp > 105, size: 30),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _calculateGear(int speed, int rpm) {
    if (rpm < 500) return 'P';
    if (speed == 0) return 'N';
    return 'D';
  }
}

class _CircularSideGauge extends StatelessWidget {
  final double size;
  final double value;
  final double maxValue;
  final double minValue;
  final String label;
  final String unit;
  final Color accentColor;
  final IconData icon;

  const _CircularSideGauge({
    required this.size,
    required this.value,
    required this.maxValue,
    this.minValue = 0,
    required this.label,
    required this.unit,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SideArcPainter(progress: progress, color: accentColor),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor.withOpacity(0.5), size: size * 0.08),
              Text(
                value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                style: TextStyle(color: Colors.white, fontSize: size * 0.15, fontWeight: FontWeight.w900),
              ),
              Text(
                unit,
                style: TextStyle(color: Colors.white38, fontSize: size * 0.05, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SideArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 0.8 * math.pi;
    const sweepAngle = 1.4 * math.pi;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WarningIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isActive;
  final double size;

  const _WarningIcon({
    required this.icon,
    required this.color,
    required this.isActive,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: isActive ? color : Colors.white.withOpacity(0.05),
      size: size,
    );
  }
}

class _RealDashRpmPainter extends CustomPainter {
  final int rpm;
  final Color accentColor;
  final Color needleColor;

  _RealDashRpmPainter({
    required this.rpm,
    required this.accentColor,
    required this.needleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = 0.7 * math.pi;
    const sweepAngle = 1.6 * math.pi;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 15), startAngle, sweepAngle, false, bgPaint);

    final rpmProgress = (rpm / 8000).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    if (rpmProgress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 15), startAngle, sweepAngle * rpmProgress, false, activePaint);
    }

    final tickPaint = Paint()..color = Colors.white.withOpacity(0.1)..strokeWidth = 3;
    for (int i = 0; i <= 8; i++) {
      final angle = startAngle + (sweepAngle * (i / 8));
      canvas.drawLine(
        center + Offset(math.cos(angle) * (radius - 45), math.sin(angle) * (radius - 45)),
        center + Offset(math.cos(angle) * (radius - 25), math.sin(angle) * (radius - 25)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RealDashRpmPainter oldDelegate) => true;
}
