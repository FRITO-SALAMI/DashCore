import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/obd_provider.dart';
import '../../providers/dash_settings_provider.dart';
import '../rpm_warning_animation.dart';

class RacingHudDashboard extends StatelessWidget {
  const RacingHudDashboard({super.key});

  static const Color _background = Color(0xFF020304);
  static const Color _surface = Color(0xFF080B0D);
  static const Color _surface2 = Color(0xFF0C1012);
  static const Color _white = Color(0xFFF2F4F5);
  static const Color _muted = Color(0xFF697378);

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<ObdProvider>();
    final settings = context.watch<DashSettingsProvider>();
    final data = obd.data;
    final isConnected = obd.isDeviceConnected;

    final speed = data.speed.toDouble();
    final coolant = settings.convertTemp(data.engineTemp);
    final voltage = data.voltage;
    final speedUnit = settings.language == Language.english ? 'mph' : 'km/h';
    final accentColor = settings.accentColor;

    return Container(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const _Background(),
              _TopStatus(connected: isConnected, accentColor: accentColor),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth * .025,
                    constraints.maxHeight * .075,
                    constraints.maxWidth * .025,
                    constraints.maxHeight * .035,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 65,
                        child: _MainCluster(
                          speed: speed,
                          speedUnit: speedUnit,
                          fuelPercent: 60,
                          modelPath: settings.modelPath,
                          accentColor: accentColor,
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth * .02),
                      Expanded(
                        flex: 27,
                        child: _InfoPanel(
                          coolant: coolant,
                          voltage: voltage,
                          rpm: data.rpm.toDouble(),
                          connected: isConnected,
                          accentColor: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _Vignette(),
            ],
          );
        },
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackgroundPainter());
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, 1.2),
        radius: 1.15,
        colors: [Color(0xFF160408), Color(0xFF07090A), Color(0xFF020304)],
        stops: [0, .42, 1],
      ).createShader(rect);
    canvas.drawRect(rect, background);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopStatus extends StatelessWidget {
  final bool connected;
  final Color accentColor;
  const _TopStatus({required this.connected, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10, left: 24, right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('DASH', style: TextStyle(color: RacingHudDashboard._white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 4)),
              Text('CORE', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 4, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
            ],
          ),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: connected ? accentColor : Colors.white24, shape: BoxShape.circle, boxShadow: connected ? [BoxShadow(color: accentColor, blurRadius: 8)] : null)),
              const SizedBox(width: 7),
              Text(connected ? 'OBD CONNECTED' : 'NO SIGNAL', style: const TextStyle(color: RacingHudDashboard._muted, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainCluster extends StatelessWidget {
  final double speed;
  final String speedUnit;
  final int fuelPercent;
  final String modelPath;
  final Color accentColor;
  const _MainCluster({required this.speed, required this.speedUnit, required this.fuelPercent, required this.modelPath, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: RacingHudDashboard._surface.withOpacity(.56),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(constraints.maxWidth * .16),
              topRight: Radius.circular(constraints.maxWidth * .12),
              bottomLeft: Radius.circular(constraints.maxWidth * .14),
              bottomRight: Radius.circular(constraints.maxWidth * .18),
            ),
            border: Border.all(color: accentColor.withOpacity(.27), width: 1.2),
            boxShadow: [BoxShadow(color: accentColor.withOpacity(.055), blurRadius: 30, spreadRadius: 2), const BoxShadow(color: Colors.black54, blurRadius: 30)],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: constraints.maxHeight * .035, left: constraints.maxWidth * .05, right: constraints.maxWidth * .05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallLabel(icon: Icons.navigation_outlined, text: 'PERFORMANCE', accentColor: accentColor),
                    _SmallLabel(icon: Icons.speed, text: speedUnit.toUpperCase(), accentColor: accentColor),
                  ],
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: constraints.maxHeight * .08),
                  child: CustomPaint(
                    painter: _SpeedGaugePainter(speed: speed, maxSpeed: speedUnit == 'mph' ? 160 : 240, accentColor: accentColor),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(top: constraints.maxHeight * .28, left: 0, right: 0, child: _SpeedNumber(speed: speed, unit: speedUnit, accentColor: accentColor)),
                        Positioned(bottom: constraints.maxHeight * .075, left: constraints.maxWidth * .28, right: constraints.maxWidth * .28, child: _FuelIndicator(percent: fuelPercent, accentColor: accentColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accentColor;
  const _SmallLabel({required this.icon, required this.text, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: accentColor),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: RacingHudDashboard._muted, fontSize: 7, letterSpacing: 1.7, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SpeedNumber extends StatelessWidget {
  final double speed;
  final String unit;
  final Color accentColor;
  const _SpeedNumber({required this.speed, required this.unit, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(speed.round().toString(), textAlign: TextAlign.center, style: const TextStyle(color: RacingHudDashboard._white, fontSize: 130, height: .85, fontWeight: FontWeight.w300, letterSpacing: 3, fontFeatures: [FontFeature.tabularFigures()], shadows: [Shadow(color: Colors.white24, blurRadius: 8), Shadow(color: Colors.white10, blurRadius: 24)])),
        const SizedBox(height: 12),
        Text(unit.toUpperCase(), style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 6, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
      ],
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color accentColor;
  const _SpeedGaugePainter({required this.speed, required this.maxSpeed, required this.accentColor});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .43);
    final radius = math.min(size.width * .39, size.height * .38);
    const startAngle = math.pi * 1.13;
    const sweepAngle = math.pi * .74;
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..color = Colors.white.withOpacity(.075);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, base);
    final active = Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..color = accentColor;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * (speed / maxSpeed).clamp(0.0, 1.0), false, active);
  }
  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) => oldDelegate.speed != speed;
}

class _FuelIndicator extends StatelessWidget {
  final int percent;
  final Color accentColor;
  const _FuelIndicator({required this.percent, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_gas_station_outlined, color: RacingHudDashboard._muted, size: 13),
        const SizedBox(width: 8),
        ...List.generate(8, (i) => Container(width: 12, height: 5, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: i < (percent / 100 * 8).round() ? accentColor : Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(1)))),
        const SizedBox(width: 5),
        Text('$percent%', style: const TextStyle(color: RacingHudDashboard._white, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final double coolant, voltage, rpm;
  final bool connected;
  final Color accentColor;
  const _InfoPanel({required this.coolant, required this.voltage, required this.rpm, required this.connected, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: RacingHudDashboard._surface2.withOpacity(.78), borderRadius: BorderRadius.circular(22), border: Border.all(color: accentColor.withOpacity(.28))),
      child: Column(
        children: [
          _InfoHeader(connected: connected, accentColor: accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PrimaryStats(coolant: coolant, voltage: voltage, accentColor: accentColor),
                  const SizedBox(height: 12),
                  RpmWarningAnimation(
                    rpm: rpm.toInt(),
                    child: _MetricCard(
                      label: 'ENGINE RPM',
                      value: rpm.toStringAsFixed(0),
                      unit: 'RPM',
                      progress: (rpm / 8000).clamp(0.0, 1.0),
                      accentColor: accentColor,
                    ),
                  ),
                  const Spacer(),
                  _DriveFooter(accentColor: accentColor)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final bool connected;
  final Color accentColor;
  const _InfoHeader({required this.connected, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Container(height: 54, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)), const SizedBox(width: 7), Text(connected ? 'LIVE DATA' : 'WAITING', style: const TextStyle(color: RacingHudDashboard._muted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 2))]), const Text('DASHCORE', style: TextStyle(color: RacingHudDashboard._white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.5))]));
  }
}

class _PrimaryStats extends StatelessWidget {
  final double coolant, voltage;
  final Color accentColor;
  const _PrimaryStats({required this.coolant, required this.voltage, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: _LargeStat(label: 'COOLANT', value: coolant.toStringAsFixed(0), unit: '°C', accentColor: accentColor)), const SizedBox(width: 10), Expanded(child: _LargeStat(label: 'BATTERY', value: voltage > 0 ? voltage.toStringAsFixed(1) : '--', unit: 'V', accentColor: accentColor))]);
  }
}

class _LargeStat extends StatelessWidget {
  final String label, value, unit;
  final Color accentColor;
  const _LargeStat({required this.label, required this.value, required this.unit, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.025), 
        border: Border.all(color: Colors.white10), 
        borderRadius: BorderRadius.circular(16)
      ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(label, style: const TextStyle(color: RacingHudDashboard._muted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.5)), 
          const SizedBox(height: 10), 
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w400, letterSpacing: -1)),
                ),
              ), 
              const SizedBox(width: 6), 
              Text(unit, style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w900))
            ]
          )
        ]
      )
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, unit;
  final double progress;
  final Color accentColor;
  const _MetricCard({required this.label, required this.value, required this.unit, required this.progress, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(.014), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white10)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: RacingHudDashboard._muted, fontSize: 7)), RichText(text: TextSpan(children: [TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 15)), TextSpan(text: ' $unit', style: TextStyle(color: accentColor, fontSize: 7, fontWeight: FontWeight.bold))]))]), const SizedBox(height: 8), LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(accentColor))]));
  }
}

class _DriveFooter extends StatelessWidget {
  final Color accentColor;
  const _DriveFooter({required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.directions_car_outlined, size: 12, color: accentColor), const SizedBox(width: 6), const Text('DRIVE MODE', style: TextStyle(color: RacingHudDashboard._muted, fontSize: 6))]), Text('SPORT', style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.bold))]);
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.05, colors: [Colors.transparent, Colors.black.withOpacity(.18), Colors.black.withOpacity(.72)], stops: const [0, .70, 1]))));
  }
}
