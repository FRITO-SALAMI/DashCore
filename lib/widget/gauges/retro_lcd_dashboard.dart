import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/dash_settings_provider.dart';

class RetroLcdThemeData {
  final double speed;
  final int rpm;
  final double coolantPercent;
  final double fuelLevel;
  final String trip;
  final String engineTime;

  const RetroLcdThemeData({
    required this.speed,
    required this.rpm,
    required this.coolantPercent,
    required this.fuelLevel,
    required this.trip,
    required this.engineTime,
  });
}

class RetroLcdTheme extends StatelessWidget {
  final RetroLcdThemeData data;
  final Color accentColor;

  const RetroLcdTheme({
    super.key,
    required this.data,
    this.accentColor = const Color(0xFFFFA000), // Nostalgic Amber
  });

  static const _bg = Color(0xFF1A1A1A);
  static const _panelBg = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _panelBg,
              border: Border.all(color: Colors.white10, width: 1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Stack(
              children: [
                // Brushed Metal Texture Overlay (Simulated)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.03,
                    child: Image.network(
                      'https://www.transparenttextures.com/patterns/brushed-alum.png',
                      repeat: ImageRepeat.repeat,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
                
                Column(
                  children: [
                    // TOP: HEADER WITH CHROME ACCENT
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: const Border(bottom: BorderSide(color: Colors.white24, width: 0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DASHCORE VINTAGE SERIES', style: TextStyle(color: accentColor.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          Row(
                            children: [
                              _StatusIndicator(label: 'READY', isActive: true, color: Colors.greenAccent),
                              const SizedBox(width: 15),
                              _StatusIndicator(label: 'BEAM', isActive: false, color: Colors.blueAccent),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Row(
                        children: [
                          // LEFT PANEL: ANALOG-STYLE INDICATORS
                          _RetroAnalogPanel(data: data, color: accentColor),
                          
                          // CENTER: 3D VIEW & SPEED
                          Expanded(
                            flex: 3,
                            child: _RetroCenterConsole(data: data, color: accentColor),
                          ),
                          
                          // RIGHT PANEL: RPM & MISC
                          _RetroRightPanel(data: data, color: accentColor),
                        ],
                      ),
                    ),

                    // BOTTOM: CONTROLS & TRIPS
                    Container(
                      height: 60,
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white24, width: 0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RetroInfoBox(label: 'TRIP DISTANCE', value: '${data.trip} KM', color: accentColor),
                          _RetroInfoBox(label: 'ENGINE UPTIME', value: data.engineTime, color: accentColor),
                          _RetroInfoBox(label: 'BATTERY VOLT', value: '14.2V', color: accentColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  const _StatusIndicator({required this.label, required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.white10,
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isActive ? Colors.white70 : Colors.white10, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _RetroAnalogPanel extends StatelessWidget {
  final RetroLcdThemeData data;
  final Color color;
  const _RetroAnalogPanel({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RetroCircularIndicator(label: 'COOLANT', value: data.coolantPercent, color: color, unit: '%'),
          _RetroCircularIndicator(label: 'FUEL', value: data.fuelLevel / 100, color: color, unit: '%'),
        ],
      ),
    );
  }
}

class _RetroCircularIndicator extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String unit;

  const _RetroCircularIndicator({required this.label, required this.value, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70, height: 70,
              child: CustomPaint(
                painter: _CircularRetroPainter(progress: value, color: color),
              ),
            ),
            Text('${(value * 100).round()}', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }
}

class _RetroCenterConsole extends StatelessWidget {
  final RetroLcdThemeData data;
  final Color color;
  const _RetroCenterConsole({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Perspective Grid Background
        Positioned.fill(
          child: Opacity(
            opacity: 0.1,
            child: CustomPaint(painter: _RetroPerspectiveGrid(color: color)),
          ),
        ),
        
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<DashSettingsProvider>(
                builder: (context, settings, _) {
                  return ModelViewer(
                    backgroundColor: Colors.transparent,
                    src: settings.modelPath,
                    alt: "Vehicle",
                    autoRotate: false,
                    cameraControls: false,
                    disableZoom: true,
                    disablePan: true,
                    cameraOrbit: '180deg 80deg 4.5m',
                    exposure: 1.2,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  data.speed.round().toString(),
                  style: TextStyle(color: color, fontSize: 80, fontWeight: FontWeight.bold, fontFamily: 'monospace', height: 0.9),
                ),
                const SizedBox(width: 8),
                Text('KM/H', style: TextStyle(color: color.withOpacity(0.5), fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}

class _RetroRightPanel extends StatelessWidget {
  final RetroLcdThemeData data;
  final Color color;
  const _RetroRightPanel({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('RPM ENGINE', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 15),
          Expanded(
            child: _RetroVerticalVuMeter(value: data.rpm / 8000, color: color),
          ),
          const SizedBox(height: 15),
          Text(data.rpm.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _RetroVerticalVuMeter extends StatelessWidget {
  final double value;
  final Color color;
  const _RetroVerticalVuMeter({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(20, (i) {
            final double threshold = (20 - i) / 20;
            final bool isActive = value >= threshold;
            return Container(
              width: 30,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(1),
                boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 2)] : null,
              ),
            );
          }),
        );
      }
    );
  }
}

class _RetroInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RetroInfoBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}

class _CircularRetroPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CircularRetroPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    
    final bgPaint = Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);
    
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;
      
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    
    // Ticks
    final tickPaint = Paint()..color = Colors.white24..strokeWidth = 1;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      canvas.drawLine(Offset(center.dx + (radius - 5) * math.cos(angle), center.dy + (radius - 5) * math.sin(angle)), Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RetroPerspectiveGrid extends CustomPainter {
  final Color color;
  _RetroPerspectiveGrid({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.3)..strokeWidth = 0.5;
    final w = size.width, h = size.height;
    
    // Vanish point
    final vanish = Offset(w / 2, h * 0.2);
    
    // Vertical lines
    for (int i = 0; i <= 20; i++) {
      final x = w * (i / 20);
      canvas.drawLine(Offset(x, h), vanish, paint);
    }
    
    // Horizontal lines
    for (int i = 0; i < 10; i++) {
      final double y = h * (0.2 + 0.8 * math.pow(i / 10, 2));
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
