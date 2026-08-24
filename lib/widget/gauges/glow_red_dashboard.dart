import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../dashboard_background.dart';

class GlowRedDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final String tempUnit;
  final Color accentColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String? trackTitle;
  final String? artistName;

  const GlowRedDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.tempUnit = '°C',
    this.accentColor = const Color(0xFFFF0000), // Default to Red
    this.backgroundImage,
    this.isAssetBackground = true,
    this.trackTitle,
    this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final isCompetitive = rpm > 5000;
    // Force red if the provided accentColor is the general cyan default
    final effectiveColor = accentColor.value == 0xFF00E5FF ? const Color(0xFFFF0000) : accentColor;
    final currentAccent = isCompetitive ? const Color(0xFFFF1111) : effectiveColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isCompetitive ? Colors.red.withOpacity(0.08) : Colors.black,
      child: Stack(
        children: [
          DashboardBackground(
            backgroundImage: backgroundImage,
            isAssetBackground: isAssetBackground,
            opacity: 0.4,
          ),

          // Background Glow Path
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPathPainter(color: currentAccent),
            ),
          ),
          
          // Top Header: Stats
          Positioned(
            top: 30,
            right: 60,
            child: Row(
              children: [
                _HeaderStat(label: 'MOTOR DATA', value: (rpm/1000).toStringAsFixed(1), unit: 'K-RPM', color: currentAccent),
              ],
            ),
          ),

          // Central Boost Meter
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: _BoostMeter(value: (rpm / 8000), color: currentAccent),
          ),

          // Main Gauges (Central 4-Circle Cluster - SEPARATED)
          Center(
            child: SizedBox(
              width: 700, height: 450,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Circles: RPM and Speed (Left and Right)
                  Positioned(
                    left: 20,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isCompetitive ? 1.05 : 1.0,
                      child: _GlowCircularGauge(
                        value: rpm,
                        maxValue: 8000,
                        label: 'RPM',
                        color: currentAccent,
                        size: 300,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    child: _GlowCircularGauge(
                      value: speed,
                      maxValue: 260,
                      label: 'KM/H',
                      color: currentAccent,
                      size: 300,
                    ),
                  ),

                  // Inner Circles: Temp and Volt (Center-ish, but separated)
                  Positioned(
                    left: 240,
                    child: _GlowCircularGauge(
                      value: coolantTemp,
                      maxValue: 130,
                      label: 'TEMP',
                      color: Colors.cyanAccent,
                      size: 110,
                    ),
                  ),
                  Positioned(
                    right: 240,
                    child: _GlowCircularGauge(
                      value: voltage.toInt(),
                      maxValue: 16,
                      label: 'VOLT',
                      color: Colors.orangeAccent,
                      size: 110,
                      isVolt: true,
                      voltValue: voltage,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Music Hub (Small & far bottom left)
          Positioned(
            left: 20,
            bottom: 15,
            child: _GlowMusicHub(
              color: currentAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowMusicHub extends StatelessWidget {
  final Color color;
  const _GlowMusicHub({required this.color});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return Container(
      width: 280, // Less long
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  music.trackTitle, 
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  music.artistName.toUpperCase(), 
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          _GlowMusicButton(
            icon: music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
            onTap: music.playPause, 
            color: color
          ),
          _GlowMusicButton(icon: Icons.skip_next_rounded, onTap: music.next, color: color),
        ],
      ),
    );
  }
}

class _GlowMusicButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isLarge;

  const _GlowMusicButton({required this.icon, required this.onTap, required this.color, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: isLarge ? 28 : 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(icon, color: Colors.white),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _HeaderStat({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _GlowCircularGauge extends StatelessWidget {
  final int value;
  final int maxValue;
  final String label;
  final Color color;
  final double size;
  final double fontSize;
  final bool isVolt;
  final double? voltValue;

  const _GlowCircularGauge({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.size = 360,
    this.fontSize = 100,
    this.isVolt = false,
    this.voltValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GlowGaugePainter(
              progress: progress,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVolt ? voltValue!.toStringAsFixed(1) : '$value',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: size * 0.06,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GlowGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final accentColor = color;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final outerPaint = Paint()
      ..color = accentColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 5), startAngle, sweepAngle, false, outerPaint);

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20), startAngle, sweepAngle, false, glowPaint);

    final solidPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20), startAngle, sweepAngle * progress, false, solidPaint);

    final needleAngle = startAngle + progress * sweepAngle;
    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(center.dx + math.cos(needleAngle) * (radius - 15), center.dy + math.sin(needleAngle) * (radius - 15));
    final needleStart = Offset(center.dx + math.cos(needleAngle) * (radius - 60), center.dy + math.sin(needleAngle) * (radius - 60));
    canvas.drawLine(needleStart, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _GlowGaugePainter oldDelegate) => true;
}

class _BoostMeter extends StatelessWidget {
  final double value;
  final Color color;
  const _BoostMeter({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 400,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MIN', style: TextStyle(color: color.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
              const Text(
                'TURBO BOOST PRESSURE',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              Text('MAX', style: TextStyle(color: color.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 400,
          height: 40,
          child: CustomPaint(
            painter: _BoostPainter(progress: value, color: color),
          ),
        ),
      ],
    );
  }
}

class _BoostPainter extends CustomPainter {
  final double progress;
  final Color color;
  _BoostPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    const tickCount = 41;
    final spacing = size.width / (tickCount - 1);

    for (int i = 0; i < tickCount; i++) {
      final x = i * spacing;
      final height = (i % 5 == 0) ? size.height : size.height * 0.5;
      final active = (i / tickCount) <= progress;
      paint.color = active ? color : Colors.white.withOpacity(0.1);
      paint.strokeWidth = (i % 5 == 0) ? 3 : 1.5;

      canvas.drawLine(Offset(x, (size.height - height) / 2), Offset(x, (size.height + height) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoostPainter oldDelegate) => true;
}

class _BackgroundPathPainter extends CustomPainter {
  final Color color;
  _BackgroundPathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.05)..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    path.moveTo(w * 0.1, h * 0.5);
    path.lineTo(w * 0.2, h * 0.3);
    path.lineTo(w * 0.8, h * 0.3);
    path.lineTo(w * 0.9, h * 0.5);
    path.lineTo(w * 0.8, h * 0.7);
    path.lineTo(w * 0.2, h * 0.7);
    path.close();

    canvas.drawPath(path, paint);
    final borderPaint = Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
