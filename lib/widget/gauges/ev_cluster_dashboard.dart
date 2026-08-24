import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class EvClusterThemeData {
  final double speedKmh;
  final double rpmThousands;
  final double batteryPercent;
  final double coolantTemp;
  final double voltage;
  final String gear;
  final String nowPlayingLabel;

  const EvClusterThemeData({
    required this.speedKmh,
    required this.rpmThousands,
    required this.batteryPercent,
    required this.coolantTemp,
    required this.voltage,
    required this.gear,
    required this.nowPlayingLabel,
  });
}

class EvClusterTheme extends StatefulWidget {
  final EvClusterThemeData data;
  final Color accentColor;
  final String modelPath;

  const EvClusterTheme({
    super.key,
    required this.data,
    required this.modelPath,
    this.accentColor = const Color(0xFF2E9BFF),
  });

  @override
  State<EvClusterTheme> createState() => _EvClusterThemeState();
}

class _EvClusterThemeState extends State<EvClusterTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cityController;

  static const Color _backgroundColor = Color(0xFF030509);

  @override
  void initState() {
    super.initState();

    _cityController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speedFactor =
        (widget.data.speedKmh / 100).clamp(0.1, 3.0);

    final durationMs = (10000 / speedFactor).round();

    _cityController.duration = Duration(
      milliseconds: durationMs,
    );

    return Container(
      color: _backgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 20,
              left: 30,
              child: _MusicHubSmall(
                title: widget.data.nowPlayingLabel,
                accentColor: widget.accentColor,
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _CircularGauge(
                            value: widget.data.speedKmh,
                            maxValue: 240,
                            label: 'km/h',
                            accentColor: widget.accentColor,
                            centerValue:
                                widget.data.speedKmh.round().toString(),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: AnimatedBuilder(
                            animation: _cityController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _RoadPainter(
                                  color: widget.accentColor,
                                  animationValue:
                                      _cityController.value,
                                  speedKmh: widget.data.speedKmh,
                                ),
                                child: _CenterDisplay(
                                  modelPath: widget.modelPath,
                                  batteryPercent:
                                      widget.data.batteryPercent,
                                  coolantTemp:
                                      widget.data.coolantTemp,
                                  voltage: widget.data.voltage,
                                  gear: widget.data.gear,
                                  accentColor:
                                      widget.accentColor,
                                  animationValue:
                                      _cityController.value,
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CircularGauge(
                                value: widget.data.rpmThousands,
                                maxValue: 8,
                                label: '1/minx1000',
                                accentColor: widget.accentColor,
                                centerValue:
                                    widget.data.rpmThousands.round().toString(),
                                isRpm: true,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SmallGadget(
                                    icon: Icons.thermostat_rounded,
                                    value: '${widget.data.coolantTemp.round()}°',
                                    label: 'THERMAL',
                                    color: widget.accentColor,
                                    scale: 1.0,
                                  ),
                                  const SizedBox(width: 10),
                                  _SmallGadget(
                                    icon: Icons.bolt_rounded,
                                    value:
                                        '${widget.data.voltage.toStringAsFixed(1)}V',
                                    label: 'ENERGY',
                                    color: widget.accentColor,
                                    scale: 1.0,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicHubSmall extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _MusicHubSmall({
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 160,
                ),
                child: Text(
                  title.isEmpty ? 'DashCore Audio' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterDisplay extends StatelessWidget {
  final String modelPath;
  final double batteryPercent;
  final double coolantTemp;
  final double voltage;
  final String gear;
  final Color accentColor;
  final double animationValue;

  const _CenterDisplay({
    required this.modelPath,
    required this.batteryPercent,
    required this.coolantTemp,
    required this.voltage,
    required this.gear,
    required this.accentColor,
    this.animationValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoadPainter(
                    color: accentColor,
                    animationValue: animationValue,
                    speedKmh: 0,
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: ModelViewer(
                  key: ValueKey(modelPath),
                  backgroundColor: Colors.transparent,
                  src: modelPath,
                  alt: 'Vehicle',
                  autoRotate: false,
                  cameraControls: false,
                  disableZoom: true,
                  disablePan: true,
                  cameraOrbit: '0deg 80deg 4m',
                  exposure: 1.0,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.battery_charging_full_rounded,
                    color: Colors.white24,
                    size: 14,
                  ),
                  Text(
                    '${batteryPercent.round()}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value:
                      (batteryPercent / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor:
                      Colors.white.withOpacity(0.05),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['P', 'R', 'N', 'D']
              .map(
                (g) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: g == gear
                          ? Colors.white
                          : Colors.white24,
                      fontSize: 18,
                      fontWeight: g == gear
                          ? FontWeight.w900
                          : FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SmallGadget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double scale;

  const _SmallGadget({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final Color accentColor;
  final String centerValue;
  final bool isRpm;

  const _CircularGauge({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.accentColor,
    required this.centerValue,
    this.isRpm = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (value / maxValue).clamp(0.0, 1.0);

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GaugeRingPainter(
              progress: progress,
              color: accentColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 70,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            child: Icon(
              isRpm
                  ? Icons.air_rounded
                  : Icons.local_gas_station_rounded,
              color: Colors.white10,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugeRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius =
        math.min(size.width, size.height) / 2 - 20;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        15,
      );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle * progress,
      false,
      glowPaint,
    );

    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          color.withOpacity(0.4),
          color,
          Colors.white,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _GaugeRingPainter old,
  ) {
    return old.progress != progress ||
        old.color != color;
  }
}

class _RoadPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final double speedKmh;

  _RoadPainter({
    required this.color,
    this.animationValue = 0,
    required this.speedKmh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final vanish = Offset(
      w / 2,
      h * 0.1,
    );

    final horizonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTRB(
          0,
          vanish.dy - 50,
          w,
          vanish.dy + 50,
        ),
      );

    canvas.drawRect(
      Rect.fromLTRB(
        0,
        vanish.dy - 50,
        w,
        vanish.dy + 50,
      ),
      horizonPaint,
    );

    _drawFuturisticCity(
      canvas,
      size,
      vanish,
    );

    final lanePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.4),
        ],
      ).createShader(
        Rect.fromLTRB(
          0,
          vanish.dy,
          w,
          h,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawLine(
      Offset(w * 0.1, h),
      vanish,
      lanePaint,
    );

    canvas.drawLine(
      Offset(w * 0.9, h),
      vanish,
      lanePaint,
    );

    final dashPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 3 carriles (2 líneas divisorias)
    for (final dx in [-0.1, 0.1]) {
      double distance = (animationValue * 150) % 80;

      const dashWidth = 40.0;
      const dashGap = 40.0;

      final start = Offset(
        w / 2 + dx * w,
        h,
      );

      final direction = vanish - start;
      final length = direction.distance;
      final unit = direction / length;

      while (distance < length) {
        final d1 = distance;
        final d2 =
            math.min(distance + dashWidth, length);

        final opacityFactor =
            (d1 / length).clamp(0.0, 1.0);

        dashPaint.color = color.withOpacity(
          0.4 * opacityFactor,
        );

        canvas.drawLine(
          start + unit * d1,
          start + unit * d2,
          dashPaint,
        );

        distance += dashWidth + dashGap;
      }
    }

    for (var i = 1; i <= 12; i++) {
      final t = i / 12;

      final y = vanish.dy +
          (h - vanish.dy) *
              math.pow(t, 1.5);

      final widthFactor =
          math.pow(t, 0.5) * 1.5;

      final opacity = 0.2 * t;

      final gridPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + (t * 2);

      canvas.drawLine(
        Offset(
          w / 2 - w * widthFactor,
          y,
        ),
        Offset(
          w / 2 + w * widthFactor,
          y,
        ),
        gridPaint,
      );
    }
  }

  void _drawFuturisticCity(
    Canvas canvas,
    Size size,
    Offset vanish,
  ) {
    final w = size.width;
    final h = size.height;

    // Framed city effect
    final frameRect = Rect.fromLTRB(w * 0.05, vanish.dy - 120, w * 0.95, h * 0.75);
    canvas.save();
    canvas.clipRect(frameRect);

    const int count = 30;

    for (int i = 0; i < count; i++) {
      final t = (animationValue + (i / count)) % 1.0;
      final progress = math.pow(t, 2.8).toDouble();

      for (final side in [-1.0, 1.0]) {
        final spread = 2.0 + (i % 6 * 0.3); 
        final targetX = w / 2 + (side * w * spread);
        final targetY = h * 1.6;

        final x = vanish.dx + (targetX - vanish.dx) * progress;
        final y = vanish.dy + (targetY - vanish.dy) * progress;

        final bWidth = 160 * progress;
        final bHeight = (300 + (math.sin(i * 9) * 200).abs()) * progress;

        final opacity = (1.0 - progress).clamp(0.0, 0.8);

        final buildingPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(opacity * 0.6), color.withOpacity(opacity * 0.1)],
          ).createShader(Rect.fromLTWH(x - bWidth / 2, y - bHeight, bWidth, bHeight));

        final neonAccent = Paint()
          ..color = color.withOpacity(opacity * 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * progress;

        final r = Rect.fromLTWH(x - bWidth / 2, y - bHeight, bWidth, bHeight);
        
        canvas.drawRect(r, buildingPaint);
        canvas.drawRect(r, neonAccent);
        
        // Window lights grid
        if (progress > 0.3) {
           for (int j = 1; j < 6; j++) {
             for (int k = 0; k < 3; k++) {
               canvas.drawRect(
                 Rect.fromLTWH(r.left + 5 + (k * (bWidth/4)), r.top + (j * 15 * progress), 2 * progress, 2 * progress), 
                 Paint()..color = color.withOpacity(opacity * 0.7)
               );
             }
           }
        }
      }
    }
    canvas.restore();
    
    // Aesthetic frame
    canvas.drawRect(frameRect, Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 2);
    // Draw horizon light
    canvas.drawLine(Offset(frameRect.left, vanish.dy), Offset(frameRect.right, vanish.dy), Paint()..color = color.withOpacity(0.2)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(
    covariant _RoadPainter oldDelegate,
  ) {
    return oldDelegate.animationValue !=
            animationValue ||
        oldDelegate.color != color ||
        oldDelegate.speedKmh != speedKmh;
  }
}