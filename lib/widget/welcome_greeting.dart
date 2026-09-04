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
  late AnimationController _mainController;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: Duration(milliseconds: (widget.durationSeconds * 1000).round()),
      vsync: this,
    );

    _progress = Tween<double>(begin: 0, end: 1).animate(_mainController);

    _mainController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), widget.onFinished);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          switch (widget.design) {
            case 1: return _DesignIgnition(progress: _progress.value, name: widget.username);
            case 2: return _DesignSpace(progress: _progress.value, name: widget.username);
            case 3: return _DesignCyber(progress: _progress.value, name: widget.username);
            case 4: return _DesignMinimal(progress: _progress.value, name: widget.username);
            case 0:
            default: return _DesignDefault(progress: _progress.value, name: widget.username);
          }
        },
      ),
    );
  }
}

// DESIGN 0: DEFAULT
class _DesignDefault extends StatelessWidget {
  final double progress;
  final String name;
  const _DesignDefault({required this.progress, required this.name});
  @override
  Widget build(BuildContext context) {
    final opacity = progress < 0.2 ? progress * 5 : (progress > 0.8 ? (1 - progress) * 5 : 1.0);
    return Container(
      color: Colors.black.withOpacity(0.85 * opacity.clamp(0, 1)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, color: const Color(0xFF00E5FF), size: 80 * opacity),
            const SizedBox(height: 20),
            Text('BIENVENIDO', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 4)),
            Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

// DESIGN 1: CAR IGNITION (Encendiendo motor)
class _DesignIgnition extends StatelessWidget {
  final double progress;
  final String name;
  const _DesignIgnition({required this.progress, required this.name});
  @override
  Widget build(BuildContext context) {
    final shake = math.sin(progress * 50) * (1 - progress) * 5;
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform.translate(
          offset: Offset(shake, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200, height: 200,
                    child: CircularProgressIndicator(value: progress, strokeWidth: 10, color: Colors.redAccent),
                  ),
                  const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 60),
                ],
              ),
              const SizedBox(height: 40),
              Text(progress < 0.5 ? 'CHECKING ENGINE...' : 'IGNITION ACTIVE',
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

// DESIGN 2: SPACE (Nave espacial)
class _DesignSpace extends StatelessWidget {
  final double progress;
  final String name;
  const _DesignSpace({required this.progress, required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(colors: [Color(0xFF1A0033), Colors.black], radius: 1.5),
      ),
      child: Stack(
        children: [
          ...List.generate(20, (i) => Positioned(
            left: math.Random(i).nextDouble() * 1000,
            top: math.Random(i + 1).nextDouble() * 1000,
            child: Opacity(opacity: math.sin(progress * 10 + i).abs(), child: const Icon(Icons.star, color: Colors.white, size: 2)),
          )),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rocket_launch_rounded, color: Colors.purpleAccent, size: 70),
                const SizedBox(height: 20),
                Text('WARP DRIVE READY', style: TextStyle(color: Colors.purpleAccent.withOpacity(0.7), fontSize: 10, letterSpacing: 5)),
                const SizedBox(height: 10),
                Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w100, letterSpacing: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DESIGN 3: CYBERPUNK (Futurista)
class _DesignCyber extends StatelessWidget {
  final double progress;
  final String name;
  const _DesignCyber({required this.progress, required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          Positioned(bottom: 0, left: 0, right: 0, height: 2, child: Container(color: Colors.cyanAccent.withOpacity(progress))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LOADING CORE...', style: TextStyle(color: Colors.cyanAccent.withOpacity(0.5), fontSize: 10)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2)),
                  child: Text(name.toUpperCase(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
                const SizedBox(height: 10),
                SizedBox(width: 200, child: LinearProgressIndicator(value: progress, color: Colors.cyanAccent, backgroundColor: Colors.white10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DESIGN 4: MINIMAL (Elegante)
class _DesignMinimal extends StatelessWidget {
  final double progress;
  final String name;
  const _DesignMinimal({required this.progress, required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Opacity(
          opacity: (math.sin(progress * math.pi)).clamp(0, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DASHCORE', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 15)),
              const SizedBox(height: 20),
              Container(width: 40, height: 1, color: Colors.black26),
              const SizedBox(height: 20),
              Text(name.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
