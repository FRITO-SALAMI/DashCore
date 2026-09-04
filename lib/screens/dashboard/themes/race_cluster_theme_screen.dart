import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/obd_data.dart';
import '../../../providers/dash_settings_provider.dart';
import '../../../providers/music_provider.dart';
import '../../../widget/music_hub.dart';

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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final isCompetitive = data.rpm > 5000;

    final bool isTempWarning = settings.tempWarningEnabled && data.engineTemp >= settings.tempAlertThreshold;
    final bool isSpeedWarning = settings.speedWarningEnabled && data.speed >= settings.speedAlertThreshold;

    final Color displayAccent = isSpeedWarning ? Colors.redAccent : accentColor;
    final Color mainColor = (isCompetitive || isSpeedWarning) ? Colors.redAccent : displayAccent;

    return Container(
      color: _bg,
      child: Stack(
        children: [
          if (isCompetitive || isSpeedWarning) Positioned.fill(child: _SpeedLines(color: mainColor)),

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
                      _TopShiftBar(rpm: data.rpm, color: mainColor),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Row(
                          children: [
                            _VerticalRaceStats(
                              label: 'ENGINE', value: '${data.engineTemp}', unit: '°C',
                              progress: (data.engineTemp / 120).clamp(0.0, 1.0),
                              color: isTempWarning ? Colors.redAccent : Colors.cyanAccent,
                              isWarning: isTempWarning,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: _MainRaceGauge(
                                speed: data.speed, rpm: data.rpm, maxRpm: maxRpm,
                                color: mainColor, isWarning: isSpeedWarning,
                              ),
                            ),
                            const SizedBox(width: 20),
                            _VerticalRaceStats(
                              label: 'BATTERY', value: data.voltage.toStringAsFixed(1), unit: 'V',
                              progress: ((data.voltage - 9) / 7).clamp(0.0, 1.0),
                              color: Colors.orangeAccent, alignRight: true,
                            ),
                          ],
                        ),
                      ),
                      _RaceBottomBar(odometer: data.odometer, fuel: fuelLevel.round(), color: displayAccent),
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

class _RaceMusicHub extends StatelessWidget {
  const _RaceMusicHub();

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: Colors.white38, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  music.trackTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  music.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(music.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white70, size: 20),
            onPressed: music.playPause,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white70, size: 20),
            onPressed: music.next,
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: List.generate(20, (i) {
            final isActive = (rpm / 8000 * 20) > i;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                decoration: BoxDecoration(color: isActive ? _getShiftColor(i, color) : Colors.transparent, borderRadius: BorderRadius.circular(2), boxShadow: isActive ? [BoxShadow(color: _getShiftColor(i, color).withOpacity(0.6), blurRadius: 10)] : null),
              ),
            );
          }),
        ),
      ),
    );
  }
  Color _getShiftColor(int i, Color base) { if (i < 10) return Colors.greenAccent; if (i < 16) return Colors.yellowAccent; return Colors.redAccent; }
}

class _MainRaceGauge extends StatelessWidget {
  final int speed, rpm;
  final double maxRpm;
  final Color color;
  final bool isWarning;
  const _MainRaceGauge({required this.speed, required this.rpm, required this.maxRpm, required this.color, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isWarning ? 1.15 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // AESTHETIC SPORTS BACKGROUND CIRCLE
          Container(
            width: 320, height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.1), width: 1),
              gradient: RadialGradient(colors: [color.withOpacity(0.05), Colors.transparent]),
            ),
          ),

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

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$speed', style: TextStyle(color: isWarning ? Colors.redAccent : Colors.white, fontSize: 140, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -2, fontStyle: FontStyle.italic, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 40)])),
              Text('KM/H', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 10)),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(10)), child: const Text('GEAR D', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalRaceStats extends StatefulWidget {
  final String label, value, unit;
  final double progress;
  final Color color;
  final bool alignRight, isWarning;
  const _VerticalRaceStats({required this.label, required this.value, required this.unit, required this.progress, required this.color, this.alignRight = false, this.isWarning = false});
  @override State<_VerticalRaceStats> createState() => _VerticalRaceStatsState();
}
class _VerticalRaceStatsState extends State<_VerticalRaceStats> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); if (widget.isWarning) _c.repeat(reverse: true); }
  @override void didUpdateWidget(covariant _VerticalRaceStats old) { super.didUpdateWidget(old); if (widget.isWarning && !old.isWarning) _c.repeat(reverse: true); else if (!widget.isWarning && old.isWarning) _c.stop(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _c, builder: (context, child) { final op = widget.isWarning ? _c.value : 1.0; return Opacity(opacity: widget.isWarning ? (0.4 + 0.6 * op) : 1.0, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: widget.alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [Text(widget.label, style: TextStyle(color: widget.color.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(height: 10), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(widget.value, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)), const SizedBox(width: 4), Text(widget.unit, style: TextStyle(color: widget.color, fontSize: 16, fontWeight: FontWeight.bold))]), const SizedBox(height: 15), Container(width: 80, height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)), child: FractionallySizedBox(alignment: widget.alignRight ? Alignment.centerRight : Alignment.centerLeft, widthFactor: widget.progress, child: Container(decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(3)))))])); }); }
}

class _RaceBottomBar extends StatelessWidget {
  final num odometer;
  final int fuel;
  final Color color;
  const _RaceBottomBar({required this.odometer, required this.fuel, required this.color});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_Item(icon: Icons.map_rounded, label: 'DISTANCE', value: '${odometer.toInt()}', unit: 'KM'), _Item(icon: Icons.local_gas_station_rounded, label: 'FUEL LEVEL', value: '$fuel', unit: '%', color: fuel < 20 ? Colors.red : Colors.greenAccent)]));
}
class _Item extends StatelessWidget {
  final IconData icon; final String label, value, unit; final Color? color;
  const _Item({required this.icon, required this.label, required this.value, required this.unit, this.color});
  @override Widget build(BuildContext context) => Row(children: [Icon(icon, color: color ?? Colors.white38, size: 24), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)), Row(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(width: 4), Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 12))])])]);
}

class _SpeedLines extends StatefulWidget {
  final Color color; const _SpeedLines({required this.color});
  @override State<_SpeedLines> createState() => _SpeedLinesState();
}
class _SpeedLinesState extends State<_SpeedLines> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (context, _) => CustomPaint(painter: _LPainter(progress: _c.value, color: widget.color)));
}
class _LPainter extends CustomPainter {
  final double progress; final Color color;
  _LPainter({required this.progress, required this.color});
  @override void paint(Canvas canvas, Size size) { final p = Paint()..color = color.withOpacity(0.1)..strokeWidth = 2; for (int i = 0; i < 20; i++) { final x = (i * 100 + (progress * 100)) % size.width; canvas.drawLine(Offset(x, 0), Offset(x + 50, 0), p); canvas.drawLine(Offset(size.width - x, size.height), Offset(size.width - x - 50, size.height), p); } }
  @override bool shouldRepaint(covariant _LPainter oldDelegate) => true;
}
