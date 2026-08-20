import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dashcore/screens/car_screen.dart';
import 'package:dashcore/screens/connect_screen.dart';
import 'package:dashcore/screens/settings_screen.dart';
import 'package:dashcore/screens/styles_screen.dart';
import 'package:dashcore/screens/store_screen.dart';
import 'package:dashcore/widget/home_screen/hidden_menu_overlay.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  bool _showMenu = false;
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    
    // Simulamos una carga inicial
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _showOnboarding = !done;
        _isLoading = false;
      });
    }
  }

  void _onBackToDashboard() {
    setState(() {
      _currentIndex = 0;
    });
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    Container(color: Colors.black, child: const Center(child: Text("DASHBOARD PLACEHOLDER", style: TextStyle(color: Colors.white)))),
    ConnectionScreen(onBack: _onBackToDashboard),
    CarScreen(onBack: _onBackToDashboard),
    StylesScreen(onBack: _onBackToDashboard),
    StoreScreen(onBack: _onBackToDashboard),
    Container(color: Colors.black), // Placeholder para settings
  ];

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ANIMATED SPEEDOMETER LOADING
              const _SpeedometerLoading(),
              const SizedBox(height: 30),
              const Text(
                'DASHCORE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 14,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'INITIALIZING SYSTEMS',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(onFinish: () {
        setState(() {
          _showOnboarding = false;
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: _toggleMenu,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _screens),
            if (_showMenu)
              HiddenMenuOverlay(
                currentIndex: _currentIndex,
                onItemSelected: (menuIndex) {
                  switch (menuIndex) {
                    case 0: // HOME
                      setState(() => _currentIndex = 0);
                      break;
                    case 1: // CONNECTION
                      setState(() => _currentIndex = 2);
                      break;
                    case 2: // STYLES
                      setState(() => _currentIndex = 4);
                      break;
                    case 3: // STORE
                      setState(() => _currentIndex = 5);
                      break;
                    case 4: // SETTINGS
                      showSettingsSheet(context);
                      break;
                  }
                },
                onClose: _toggleMenu,
              ),
          ],
        ),
      ),
    );
  }
}

class _SpeedometerLoading extends StatefulWidget {
  const _SpeedometerLoading();

  @override
  State<_SpeedometerLoading> createState() => _SpeedometerLoadingState();
}

class _SpeedometerLoadingState extends State<_SpeedometerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _LoadingSpeedometerPainter(progress: _animation.value),
          ),
        );
      },
    );
  }
}

class _LoadingSpeedometerPainter extends CustomPainter {
  final double progress;
  _LoadingSpeedometerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final startAngle = 0.8 * math.pi;
    final sweepAngle = 1.4 * math.pi;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    final activePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, activePaint);
    
    // Needle
    final needleAngle = startAngle + (sweepAngle * progress);
    final needlePaint = Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 2;
    canvas.drawLine(center, center + Offset(radius * 0.8 * math.cos(needleAngle), radius * 0.8 * math.sin(needleAngle)), needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
