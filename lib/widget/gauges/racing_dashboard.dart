import 'package:flutter/material.dart';
import '../rpm_warning_animation.dart';
import '../dashboard_background.dart';
import '../tutorial/tutorial_keys.dart';

class RacingDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
  final Color needleColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String tempUnit;

  const RacingDashboard({
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
    final isCompetitive = rpm > 5000;
    final isMax = rpm > 7500;
    final isExtreme = rpm > 7000; // Define isExtreme
    final currentAccent = isCompetitive ? const Color(0xFFFF1111) : accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isExtreme ? Colors.red.withOpacity(0.2) : (isCompetitive ? Colors.red.withOpacity(0.1) : Colors.black),
      child: Stack(
        children: [
          DashboardBackground(
            backgroundImage: backgroundImage,
            isAssetBackground: isAssetBackground,
            opacity: 0.1,
          ),
          
          // Racing Grid with Perspective
          Positioned.fill(child: CustomPaint(painter: _RacingPerspectivePainter(color: currentAccent))),

          Column(
            children: [
              // TOP: CIVIC TYPE-R STYLE RPM BAR
              RpmWarningAnimation(
                rpm: rpm,
                child: _CivicTypeRRpmBar(rpm: rpm, color: currentAccent),
              ),

              Expanded(
                child: Row(
                  children: [
                    // LEFT: ENGINE DATA HUD
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyedSubtree(key: TutorialKeys.temperatureGaugeKey, child: _RacingHudGadget(label: 'OIL TEMP', value: '$coolantTemp', unit: tempUnit, color: Colors.cyanAccent)),
                            const SizedBox(height: 40),
                            _RacingHudGadget(label: 'BOOST', value: '1.2', unit: 'BAR', color: Colors.amberAccent), // Mock boost
                          ],
                        ),
                      ),
                    ),
                    
                    // CENTER: AGGRESSIVE SPEED
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: KeyedSubtree(key: TutorialKeys.speedGaugeKey, child: _RacingSpeedCenter(speed: speed, isCompetitive: isCompetitive, color: currentAccent)),
                      ),
                    ),
                    
                    // RIGHT: TELEMETRY HUD
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            KeyedSubtree(key: TutorialKeys.voltageGaugeKey, child: _RacingHudGadget(label: 'VOLTS', value: voltage.toStringAsFixed(1), unit: 'V', color: Colors.orangeAccent, isRight: true)),
                            const SizedBox(height: 40),
                            _RacingHudGadget(label: 'GEAR', value: speed == 0 ? 'N' : 'D', unit: 'SEQ', color: needleColor, isRight: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Side Corner Accents
          _RacingCornerAccents(color: currentAccent),
        ],
      ),
    );
  }
}

class _CivicTypeRRpmBar extends StatelessWidget {
  final int rpm;
  final Color color;
  const _CivicTypeRRpmBar({required this.rpm, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(40, 20, 40, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (i) => Text('${i + 1}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: (rpm / 8000).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.5), color],
                        ),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15)],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RacingHudGadget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isRight;

  const _RacingHudGadget({required this.label, required this.value, required this.unit, required this.color, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
            const SizedBox(width: 5),
            Text(unit, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          width: 80, height: 2,
          color: color.withOpacity(0.4),
        ),
      ],
    );
  }
}

class _RacingSpeedCenter extends StatelessWidget {
  final int speed;
  final bool isCompetitive;
  final Color color;
  const _RacingSpeedCenter({required this.speed, required this.isCompetitive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: isCompetitive ? 1.1 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$speed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 220,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
              height: 0.8,
              shadows: [
                if (isCompetitive) Shadow(color: color.withOpacity(0.8), blurRadius: 40),
                const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(5, 5)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'KM/H',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 8),
          ),
        ],
      ),
    );
  }
}

class _RacingCornerAccents extends StatelessWidget {
  final Color color;
  const _RacingCornerAccents({required this.color});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.1), width: 10),
          ),
        ),
      ),
    );
  }
}

class _ShiftLightBar extends StatelessWidget {
  final int rpm;
  const _ShiftLightBar({required this.rpm});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(10, (i) {
          final threshold = 3000 + (i * 500);
          final isActive = rpm > threshold;
          Color color = Colors.green;
          if (i > 4) color = Colors.yellow;
          if (i > 7) color = Colors.red;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)] : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RacingStatGauge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _RacingStatGauge({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
        Text(unit, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _GearCircle extends StatelessWidget {
  final int speed;
  final int rpm;
  final Color color;
  const _GearCircle({required this.speed, required this.rpm, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = (rpm / 8000).clamp(0.0, 1.0);
    return SizedBox(
      width: 220, height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 12,
            color: color,
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speed == 0 ? 'N' : 'D',
                style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.w900),
              ),
              Text(
                'GEAR',
                style: TextStyle(color: color.withOpacity(0.6), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RacingPerspectivePainter extends CustomPainter {
  final Color color;
  _RacingPerspectivePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.03)..strokeWidth = 1;
    final w = size.width;
    final h = size.height;
    
    for (double i = 0; i <= w; i += 60) {
      canvas.drawLine(Offset(w / 2, h / 2), Offset(i, h), paint);
      canvas.drawLine(Offset(w / 2, h / 2), Offset(i, 0), paint);
    }
    for (double i = 0; i <= h; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(w, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
