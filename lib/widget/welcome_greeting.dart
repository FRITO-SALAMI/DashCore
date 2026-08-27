import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:dashcore/utils/app_localizations.dart';

class PremiumWelcomeOverlay extends StatefulWidget {
  final String username;
  final VoidCallback onFinished;
  final double durationSeconds;
  final int design;

  const PremiumWelcomeOverlay({
    super.key,
    required this.username,
    required this.onFinished,
    this.durationSeconds = 5.0,
    this.design = 0,
  });

  @override
  State<PremiumWelcomeOverlay> createState() => _PremiumWelcomeOverlayState();
}

class _PremiumWelcomeOverlayState extends State<PremiumWelcomeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _sweepAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textScaleAnimation;

  int _phase = 1;

  @override
  void initState() {
    super.initState();
    
    _sequenceController = AnimationController(
      duration: Duration(milliseconds: (widget.durationSeconds * 1000).round()),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.0, 0.3),
    ));

    _sweepAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.3, 0.6, curve: Curves.fastOutSlowIn),
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.6, 0.8),
    ));

    _textScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(0.6, 0.9, curve: Curves.elasticOut),
    ));

    _sequenceController.addListener(() {
      final val = _sequenceController.value;
      int nextPhase = 1;
      if (val > 0.6) {
        nextPhase = 3;
      } else if (val > 0.3) {
        nextPhase = 2;
      }
      
      if (nextPhase != _phase) {
        setState(() => _phase = nextPhase);
      }
    });

    _sequenceController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () => widget.onFinished());
    });
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    final loc = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: widget.design == 1 ? Colors.blue.withOpacity(0.9) : const Color(0xD9000000),
          ),
          if (widget.design == 2)
             Positioned.fill(child: _CyberGrid(color: themeColor.withOpacity(0.1))),

          if (_phase == 1)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: _buildStartButton(themeColor, loc),
                  );
                },
              ),
            ),

          if (_phase == 2)
            Center(
              child: AnimatedBuilder(
                animation: _sweepAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(600, 300),
                    painter: _DashSweepPainter(progress: _sweepAnimation.value, color: themeColor),
                  );
                },
              ),
            ),

          if (_phase == 3)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ScaleTransition(
                  scale: _textScaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 60),
                          ],
                        ),
                        child: const Icon(Icons.speed_rounded, color: themeColor, size: 100),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'SYSTEMS ONLINE', // Technical phrase usually in English
                        style: TextStyle(color: themeColor, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 12),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.translate('main_menu').toUpperCase() == 'AJUSTES' ? 'BIENVENIDO' : 'WELCOME', // Simplified for now or add to loc
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.username.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                      const SizedBox(height: 50),
                      Container(
                        width: 300, height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [themeColor.withOpacity(0), themeColor, themeColor.withOpacity(0)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Color color, AppLocalizations loc) {
    if (widget.design == 1) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: Text(
          loc.translate('lang') == 'IDIOMA' ? 'ENCENDIDO' : 'IGNITION', 
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 5)
        ),
      );
    }
    
    return Container(
      width: 150, height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 4),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.design == 2 ? Icons.bolt_rounded : Icons.power_settings_new_rounded, color: color, size: 50),
          const SizedBox(height: 10),
          Text(
            widget.design == 2 ? 'CORE' : 'ENGINE', 
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)
          ),
          Text(
            widget.design == 2 ? 'ACTIVE' : (loc.translate('lang') == 'IDIOMA' ? 'INICIO' : 'START'), 
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4)
          ),
        ],
      ),
    );
  }
}

class _CyberGrid extends StatelessWidget {
  final Color color;
  const _CyberGrid({required this.color});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(color: color));
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += 40) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _DashSweepPainter extends CustomPainter {
  final double progress;
  final Color color;
  _DashSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = size.width * 0.4;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Draw indicators (markers)
    final markerPaint = Paint()..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (int i = 0; i <= 20; i++) {
      final angle = math.pi + (math.pi * (i / 20));
      final isReached = (i / 20) <= progress;
      markerPaint.color = isReached ? color : Colors.white10;
      
      final tickLength = i % 5 == 0 ? 15.0 : 8.0;
      final start = center + Offset(math.cos(angle) * (radius - tickLength), math.sin(angle) * (radius - tickLength));
      final end = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      
      canvas.drawLine(start, end, markerPaint);
    }

    // Draw active arc
    final activePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress,
      false,
      activePaint,
    );

    // Draw Needle
    final needleAngle = math.pi + (math.pi * progress);
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final needleEnd = center + Offset(math.cos(needleAngle) * (radius - 5), math.sin(needleAngle) * (radius - 5));
    canvas.drawLine(center, needleEnd, needlePaint);
    
    // Needle center point
    canvas.drawCircle(center, 6, Paint()..color = color);
    canvas.drawCircle(center, 3, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _DashSweepPainter oldDelegate) => true;
}
