import 'package:flutter/material.dart';
import '../../../models/obd_data.dart';

class RaceClusterThemeScreen extends StatelessWidget {
  const RaceClusterThemeScreen({
    super.key,
    required this.data,
    this.maxSpeedKmh = 240,
    this.maxRpm = 8000,
    this.redlineRpm = 6500,
    this.accentColor = const Color(0xFFFF2FA0),
    this.backgroundImage,
    this.fuelLevel = 0,
  });

  final ObdData data;
  final double maxSpeedKmh;
  final double maxRpm;
  final double redlineRpm;
  final Color accentColor;
  final String? backgroundImage;
  final double fuelLevel;

  static const _bg = Color(0xFF020105);
  static const _red = Color(0xFFFF0000);

  @override
  Widget build(BuildContext context) {
    final isCompetitive = data.rpm > 5000;

    return Container(
      color: _bg,
      child: Stack(
        children: [
          // Speed Lines Animation
          if (isCompetitive) Positioned.fill(child: _SpeedLines(color: accentColor)),

          if (backgroundImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(backgroundImage!, fit: BoxFit.cover),
              ),
            ),
            
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // Top Shift Bar
                      _TopShiftBar(rpm: data.rpm, color: isCompetitive ? _red : accentColor),
                      
                      const SizedBox(height: 20),

                      Expanded(
                        child: Row(
                          children: [
                            // LEFT PANEL
                            _VerticalRaceStats(
                              label: 'ENGINE',
                              value: '${data.engineTemp}',
                              unit: '°C',
                              progress: (data.engineTemp / 120).clamp(0.0, 1.0),
                              color: Colors.cyanAccent,
                            ),
                            
                            const SizedBox(width: 20),

                            // CENTER: SPEED
                            Expanded(
                              flex: 6,
                              child: _MainRaceGauge(
                                speed: data.speed,
                                rpm: data.rpm,
                                maxRpm: maxRpm,
                                color: isCompetitive ? _red : accentColor,
                              ),
                            ),

                            const SizedBox(width: 20),

                            // RIGHT PANEL
                            _VerticalRaceStats(
                              label: 'BATTERY',
                              value: data.voltage.toStringAsFixed(1),
                              unit: 'V',
                              progress: ((data.voltage - 9) / 7).clamp(0.0, 1.0),
                              color: Colors.orangeAccent,
                              alignRight: true,
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Info
                      _RaceBottomBar(odometer: data.odometer, fuel: fuelLevel.round(), color: accentColor),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopShiftBar extends StatelessWidget {
  final int rpm;
  final Color color;
  const _TopShiftBar({required this.rpm, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: List.generate(20, (i) {
            final isActive = (rpm / 8000 * 20) > i;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _getShiftColor(i, color) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive ? [BoxShadow(color: _getShiftColor(i, color).withOpacity(0.6), blurRadius: 10)] : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _getShiftColor(int i, Color base) {
    if (i < 10) return Colors.greenAccent;
    if (i < 16) return Colors.yellowAccent;
    return Colors.redAccent;
  }
}

class _MainRaceGauge extends StatelessWidget {
  final int speed;
  final int rpm;
  final double maxRpm;
  final Color color;
  const _MainRaceGauge({required this.speed, required this.rpm, required this.maxRpm, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Digital RPM Ring
        Container(
          width: 380, height: 380,
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            value: (rpm / maxRpm).clamp(0.0, 1.0),
            strokeWidth: 20,
            color: color,
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
        ),
        
        // Speed Display
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 140,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
                fontStyle: FontStyle.italic,
                height: 0.9,
                shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 40)],
              ),
            ),
            Text(
              'KM/H',
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 10),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'GEAR D',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalRaceStats extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;
  final bool alignRight;

  const _VerticalRaceStats({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: 80, height: 6,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
            widthFactor: progress,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ],
    );
  }
}

class _RaceBottomBar extends StatelessWidget {
  final int odometer;
  final int fuel;
  final Color color;
  const _RaceBottomBar({required this.odometer, required this.fuel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomItem(icon: Icons.map_rounded, label: 'DISTANCE', value: '$odometer', unit: 'KM'),
          _BottomItem(icon: Icons.local_gas_station_rounded, label: 'FUEL LEVEL', value: '$fuel', unit: '%', color: fuel < 20 ? Colors.red : Colors.greenAccent),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const _BottomItem({required this.icon, required this.label, required this.value, required this.unit, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white38, size: 24),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeedLines extends StatefulWidget {
  final Color color;
  const _SpeedLines({required this.color});
  @override
  State<_SpeedLines> createState() => _SpeedLinesState();
}

class _SpeedLinesState extends State<_SpeedLines> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _LinesPainter(progress: _controller.value, color: widget.color)),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final double progress;
  final Color color;
  _LinesPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.1)..strokeWidth = 2;
    for (int i = 0; i < 20; i++) {
      final x = (i * 100 + (progress * 100)) % size.width;
      canvas.drawLine(Offset(x, 0), Offset(x + 50, 0), paint);
      canvas.drawLine(Offset(size.width - x, size.height), Offset(size.width - x - 50, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) => true;
}
