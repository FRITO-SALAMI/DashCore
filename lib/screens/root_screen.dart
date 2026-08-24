import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashcore/screens/car_screen.dart';
import 'package:dashcore/screens/connect_screen.dart';
import 'package:dashcore/screens/home_screen.dart' as home;
import 'package:dashcore/screens/onboarding_screen.dart';
import 'package:dashcore/screens/settings_screen.dart';
import 'package:dashcore/screens/store_screen.dart';
import 'package:dashcore/screens/styles_screen.dart';
import 'package:dashcore/screens/update_center_screen.dart';
import 'package:dashcore/widget/update_dialog.dart';
import 'package:dashcore/widget/home_screen/hidden_menu_overlay.dart'
as hidden_menu;
import 'package:dashcore/widget/welcome_greeting.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/services/supabase_service.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  bool _showMenu = false;
  bool _isLoading = true;
  bool _showOnboarding = false;
  bool _isGreetingActive = false;
  String _welcomeUsername = 'INVITADO';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerGreeting();
    }
  }

  void _triggerGreeting() {
    if (_isLoading || _showOnboarding) return;
    
    final settings = context.read<DashSettingsProvider>();
    if (!settings.showWelcomeGreeting) return;

    final user = SupabaseService.instance.currentUser;
    setState(() {
      _welcomeUsername = user != null
          ? (user.userMetadata?['display_name'] ?? user.email?.split('@')[0] ?? 'USUARIO')
          : 'INVITADO';
      _isGreetingActive = true;
    });
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;

    // Iniciar verificación de actualización en paralelo
    _checkForUpdates();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final settings = context.read<DashSettingsProvider>();
    final user = SupabaseService.instance.currentUser;

    setState(() {
      _showOnboarding = !done;
      _isLoading = false;
      _currentIndex = settings.lastScreenIndex; // Restore last screen

      if (done && settings.showWelcomeGreeting) {
        _welcomeUsername = user != null
            ? (user.userMetadata?['display_name'] ?? user.email?.split('@')[0] ?? 'USUARIO')
            : 'INVITADO';
        _isGreetingActive = true;
      }
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final release = await SupabaseService.instance.getActiveVersion();
      if (release.isEmpty) return;

      final int latestVersionCode = release['version_code'] ?? 0;
      const int currentVersionCode = SupabaseService.appBuild;
      const String currentVersion = '1.0.2'; // Added currentVersion string

      if (latestVersionCode > currentVersionCode) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            currentVersion: currentVersion,
            newVersion: release['version_name'] ?? 'Nueva',
            downloadUrl: release['download_url'] ?? '',
            releaseNotes: release['release_notes'] ?? 'Mejoras de rendimiento y corrección de errores.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking updates: $e');
    }
  }

  void _onBackToDashboard() {
    if (!mounted) return;

    setState(() {
      _currentIndex = 0;
      _showMenu = false;
    });
    context.read<DashSettingsProvider>().setLastScreenIndex(0);
  }

  late final List<Widget> _screens = [
    const home.HomeScreen(),

    Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'DASHBOARD PLACEHOLDER',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    ),

    ConnectionScreen(
      onBack: _onBackToDashboard,
    ),

    CarScreen(
      onBack: _onBackToDashboard,
    ),

    StylesScreen(
      onBack: _onBackToDashboard,
    ),

    StoreScreen(
      onBack: _onBackToDashboard,
    ),

    UpdateCenterScreen(
      onBack: _onBackToDashboard,
    ),

    Container(
      color: Colors.black,
    ),
  ];

  // ============================================================
  // MENÚ OCULTO
  // DOBLE TAP = ABRIR
  // ============================================================

  void _openMenu() {
    if (!mounted || _showMenu) return;

    setState(() {
      _showMenu = true;
    });
  }

  void _closeMenu() {
    if (!mounted || !_showMenu) return;

    setState(() {
      _showMenu = false;
    });
  }

  void _handleMenuSelection(int menuIndex) {
    if (!mounted) return;

    final settings = context.read<DashSettingsProvider>();

    switch (menuIndex) {
      case 0:
        setState(() {
          _currentIndex = 0;
          _showMenu = false;
        });
        settings.setLastScreenIndex(0);
        break;

      case 1:
        setState(() {
          _currentIndex = 2;
          _showMenu = false;
        });
        settings.setLastScreenIndex(2);
        break;

      case 2:
        setState(() {
          _currentIndex = 4;
          _showMenu = false;
        });
        settings.setLastScreenIndex(4);
        break;

      case 3:
        setState(() {
          _currentIndex = 5;
          _showMenu = false;
        });
        settings.setLastScreenIndex(5);
        break;

      case 4:
        setState(() {
          _currentIndex = 6; // Index for UpdateCenterScreen
          _showMenu = false;
        });
        settings.setLastScreenIndex(6);
        break;

      case 5:
        setState(() {
          _showMenu = false;
        });

        showSettingsSheet(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SpeedometerLoading(),
              SizedBox(height: 30),
              Text(
                'DASHCORE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 14,
                ),
              ),
              SizedBox(height: 10),
              Text(
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
      return OnboardingScreen(
        onFinish: () {
          if (!mounted) return;

          setState(() {
            _showOnboarding = false;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // DASHCORE / PANTALLAS
          //
          // El detector está directamente alrededor del
          // IndexedStack. Ya no existe un Positioned.fill
          // transparente encima de toda la pantalla.
          // ======================================================
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _showMenu ? null : _openMenu,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // ======================================================
          // MENÚ LATERAL
          // ======================================================
          if (_showMenu)
            Positioned.fill(
              child: hidden_menu.HiddenMenuOverlay(
                currentIndex: _currentIndex,
                onItemSelected: _handleMenuSelection,
                onClose: _closeMenu,
              ),
            ),

          // ======================================================
          // SALUDO DE BIENVENIDA
          // ======================================================
          if (_isGreetingActive)
            Positioned.fill(
              child: PremiumWelcomeOverlay(
                username: _welcomeUsername,
                durationSeconds: context.read<DashSettingsProvider>().welcomeGreetingDuration,
                design: context.read<DashSettingsProvider>().welcomeDesign,
                onFinished: () {
                  if (mounted) {
                    setState(() {
                      _isGreetingActive = false;
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// LOADING
// ================================================================

class _SpeedometerLoading extends StatefulWidget {
  const _SpeedometerLoading();

  @override
  State<_SpeedometerLoading> createState() =>
      _SpeedometerLoadingState();
}

class _SpeedometerLoadingState extends State<_SpeedometerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
            painter: _LoadingSpeedometerPainter(
              progress: _animation.value,
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// LOADING SPEEDOMETER PAINTER
// ================================================================

class _LoadingSpeedometerPainter extends CustomPainter {
  final double progress;

  const _LoadingSpeedometerPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2;

    const startAngle = 0.8 * math.pi;
    const sweepAngle = 1.4 * math.pi;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final activePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
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

    final needleAngle =
        startAngle + (sweepAngle * progress);

    final needlePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2;

    canvas.drawLine(
      center,
      center +
          Offset(
            radius * 0.8 * math.cos(needleAngle),
            radius * 0.8 * math.sin(needleAngle),
          ),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _LoadingSpeedometerPainter oldDelegate,
      ) {
    return oldDelegate.progress != progress;
  }
}