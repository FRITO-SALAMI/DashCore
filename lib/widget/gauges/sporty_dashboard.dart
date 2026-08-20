import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';

class SportyDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
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
    this.backgroundImage,
    this.isAssetBackground = true,
    this.tempUnit = '°C',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        children: [
          if (backgroundImage != null)
            Opacity(
              opacity: 0.15,
              child: Center(
                child: isAssetBackground
                    ? Image.asset(
                        backgroundImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      )
                    : Image.file(
                        File(backgroundImage!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
              ),
            ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      height: 450,
                      child: CustomPaint(
                        painter: _RealDashRpmPainter(
                          rpm: rpm,
                          accentColor: accentColor,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$speed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                            fontStyle: FontStyle.italic,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.blueAccent,
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'KM/H',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _calculateGear(speed, rpm),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            left: 50,
            bottom: 60,
            child: _SideGauge(
              label: 'COOLANT',
              value: '$coolantTemp',
              unit: tempUnit,
              progress: (coolantTemp /
                      (tempUnit == '°C' ? 130 : 250))
                  .clamp(0.0, 1.0),
              color: Colors.cyanAccent,
              icon: Icons.thermostat_rounded,
            ),
          ),

          Positioned(
            right: 50,
            bottom: 60,
            child: _SideGauge(
              label: 'BATTERY',
              value: voltage.toStringAsFixed(1),
              unit: 'V',
              progress: ((voltage - 9) / (16 - 9)).clamp(0.0, 1.0),
              color: Colors.orangeAccent,
              icon: Icons.bolt_rounded,
            ),
          ),

          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WarningIcon(
                  icon: Icons.light_mode,
                  color: Colors.green,
                  isActive: speed > 0,
                ),
                const SizedBox(width: 20),
                _WarningIcon(
                  icon: Icons.oil_barrel,
                  color: Colors.red,
                  isActive: rpm > 7000,
                ),
                const SizedBox(width: 20),
                _WarningIcon(
                  icon: Icons.warning_amber_rounded,
                  color: Colors.yellow,
                  isActive: coolantTemp > 105,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateGear(int speed, int rpm) {
    if (rpm < 500) return 'P';
    if (speed == 0) return 'N';
    return 'D';
  }
}

class _RealDashRpmPainter extends CustomPainter {
  final int rpm;
  final Color accentColor;

  _RealDashRpmPainter({
    required this.rpm,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    const startAngle = 0.7 * math.pi;
    const sweepAngle = 1.6 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final progress = (rpm / 8000).clamp(0.0, 1.0);

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue,
          accentColor,
          Colors.orange,
          Colors.red,
        ],
        stops: const [0.0, 0.4, 0.7, 0.9],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    final tickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;

    for (int i = 0; i <= 80; i++) {
      final angle = startAngle + (sweepAngle * (i / 80));
      final isMajor = i % 10 == 0;
      final length = isMajor ? 15.0 : 8.0;

      final innerPoint = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );

      final outerPoint = Offset(
        center.dx +
            (radius - 15 + length) * math.cos(angle),
        center.dy +
            (radius - 15 + length) * math.sin(angle),
      );

      tickPaint.color =
          isMajor ? Colors.white54 : Colors.white10;

      canvas.drawLine(
        innerPoint,
        outerPoint,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _SideGauge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;
  final IconData icon;

  const _SideGauge({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 8,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FractionallySizedBox(
                heightFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarningIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isActive;

  const _WarningIcon({
    required this.icon,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: isActive
          ? color
          : Colors.white.withValues(alpha: 0.05),
      size: 24,
    );
  }
}