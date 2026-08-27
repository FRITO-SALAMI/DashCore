import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/rpm_warning_animation.dart';
import '../dashboard_background.dart';

class ModernDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
  final Color needleColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String tempUnit;

  const ModernDashboard({
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
    final bool isExtreme = rpm > 6000;
    final Color currentColor = isExtreme ? Colors.redAccent : accentColor;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF010204),
      ),
      child: Stack(
        children: [
          // Dynamic Hex Grid
          Positioned.fill(child: _DynamicHexGrid(color: accentColor, rpm: rpm)),

          DashboardBackground(
            backgroundImage: backgroundImage,
            isAssetBackground: isAssetBackground,
            opacity: 0.1,
          ),
          
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // LEFT: THERMAL GADGET
                _TechGadget(
                  label: 'THERMAL CORE', 
                  value: '$coolantTemp', 
                  unit: tempUnit, 
                  icon: Icons.thermostat_auto_rounded, 
                  color: accentColor,
                  progress: (coolantTemp / 120).clamp(0.0, 1.0),
                ),
                
                // CENTER: QUANTUM SPEEDO
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _FuturisticSpeedo(speed: speed, color: currentColor),
                    
                    // RPM Small Circle next to speed
                    Positioned(
                      right: -80,
                      bottom: 40,
                      child: RpmWarningAnimation(
                        rpm: rpm,
                        child: _RpmCircle(rpm: rpm, color: currentColor),
                      ),
                    ),
                  ],
                ),
                
                // RIGHT: ENERGY GADGET
                _TechGadget(
                  label: 'ENERGY FLOW', 
                  value: voltage.toStringAsFixed(1), 
                  unit: 'V', 
                  icon: Icons.bolt_rounded, 
                  color: accentColor,
                  progress: ((voltage - 9) / 7).clamp(0.0, 1.0),
                  isRight: true,
                  hideProgress: true,
                ),
              ],
            ),
          ),
          
          // Scanning Line
          _ScanningLine(color: accentColor),

          // Glow Decoration
          Positioned(
            bottom: -100, left: 0, right: 0, height: 200,
            child: Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [accentColor.withOpacity(0.2), Colors.transparent], radius: 1.5))),
          ),
        ],
      ),
    );
  }
}

class _DynamicHexGrid extends StatefulWidget {
  final Color color;
  final int rpm;
  const _DynamicHexGrid({required this.color, required this.rpm});
  @override
  State<_DynamicHexGrid> createState() => _DynamicHexGridState();
}

class _DynamicHexGridState extends State<_DynamicHexGrid> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
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
      builder: (context, _) => CustomPaint(
        painter: _HexGridPainter(color: widget.color, offset: _controller.value, pulse: widget.rpm / 8000),
      ),
    );
  }
}

class _TechGadget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double progress;
  final bool isRight;
  final bool hideProgress;

  const _TechGadget({
    required this.label, 
    required this.value, 
    required this.unit, 
    required this.icon, 
    required this.color,
    required this.progress,
    this.isRight = false,
    this.hideProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(width: 8),
            if (isRight) Icon(icon, color: color, size: 20),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w100)),
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        if (!hideProgress) ...[
          const SizedBox(height: 15),
          Container(
            width: 180,
            height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(2)),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final Color color;
  const _ScanningLine({required this.color});
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
      builder: (context, _) => Positioned(
        top: MediaQuery.of(context).size.height * _controller.value,
        left: 0, right: 0, height: 2,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, widget.color.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  final Color color;
  final double offset;
  final double pulse;
  _HexGridPainter({required this.color, this.offset = 0, this.pulse = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.02 + (pulse * 0.05))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const double radius = 40;
    final double hexWidth = math.sqrt(3) * radius;
    final double hexHeight = 2 * radius;

    canvas.save();
    canvas.translate(0, offset * 100);

    for (double y = -hexHeight; y < size.height + hexHeight; y += hexHeight * 0.75) {
      double offsetX = ( (y / (hexHeight * 0.75)).round() % 2 == 0) ? 0 : hexWidth / 2;
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth) {
        _drawHex(canvas, Offset(x + offsetX, y), radius, paint);
      }
    }
    canvas.restore();
  }

  void _drawHex(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (math.pi / 3) * i + (math.pi / 6);
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) => true;
}

class _FuturisticSpeedo extends StatelessWidget {
  final int speed;
  final Color color;
  const _FuturisticSpeedo({required this.speed, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450, height: 450,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quantum Rings
          _QuantumRing(radius: 200, color: color.withOpacity(0.1), speed: 2),
          _QuantumRing(radius: 180, color: color.withOpacity(0.2), speed: -3),
          
          // Outer Glow Circle
          Container(
            width: 380, height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.05), width: 2),
            ),
          ),

          // Speed Center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$speed',
                style: const TextStyle(color: Colors.white, fontSize: 160, fontWeight: FontWeight.w900, letterSpacing: -10, height: 1.0),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VELOCITY',
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RpmCircle extends StatelessWidget {
  final int rpm;
  final Color color;

  const _RpmCircle({required this.rpm, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Quantum Ring for RPM
            _QuantumRing(radius: 75, color: color.withOpacity(0.15), speed: 1.5),
            _QuantumRing(radius: 68, color: color.withOpacity(0.1), speed: -2),

            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: (rpm / 8000).clamp(0.0, 1.0),
                strokeWidth: 8,
                color: color,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (rpm / 1000).toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                Text(
                  'K-RPM',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _QuantumRing extends StatefulWidget {
  final double radius;
  final Color color;
  final double speed;
  const _QuantumRing({required this.radius, required this.color, required this.speed});
  @override
  State<_QuantumRing> createState() => _QuantumRingState();
}

class _QuantumRingState extends State<_QuantumRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
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
      builder: (context, _) => Transform.rotate(
        angle: _controller.value * 2 * math.pi * widget.speed,
        child: Container(
          width: widget.radius * 2, height: widget.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2, style: BorderStyle.solid),
          ),
          child: Stack(
            children: [
              Positioned(top: 0, left: widget.radius - 5, width: 10, height: 10, child: Container(decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle))),
            ],
          ),
        ),
      ),
    );
  }
}
