import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/rpm_warning_animation.dart';
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
          const Positioned(
            top: 30,
            right: 60,
            child: Row(
              children: [],
            ),
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
                      child: RpmWarningAnimation(
                        rpm: rpm,
                        child: _GlowCircularGauge(
                          value: rpm,
                          maxValue: 8000,
                          label: 'RPM',
                          color: currentAccent,
                          size: 300,
                        ),
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

                  // Inner Circles: Temp and Volt (Closer and lower)
                  Positioned(
                    left: 255,
                    bottom: 110,
                    child: _GlowCircularGauge(
                      value: coolantTemp,
                      maxValue: 130,
                      label: 'TEMP',
                      color: currentAccent,
                      size: 90,
                    ),
                  ),
                  Positioned(
                    right: 255,
                    bottom: 110,
                    child: _GlowCircularGauge(
                      value: voltage.toInt(),
                      maxValue: 16,
                      label: 'VOLT',
                      color: currentAccent,
                      size: 90,
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
  }

  @override
  bool shouldRepaint(covariant _GlowGaugePainter oldDelegate) => true;
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
