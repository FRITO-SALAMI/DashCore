import 'dart:math' as math;
import 'dart:async';

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
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/services/analytics_service.dart';
import 'package:provider/provider.dart';

import 'package:dashcore/widget/tutorial_overlay.dart';

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
  bool _isUpdateDialogOpen = false;
  bool _updateCheckSucceeded = false;
  String _welcomeUsername = 'INVITADO';
  Timer? _connectivityRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
    _startConnectivityPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityRetryTimer?.cancel();
    super.dispose();
  }

  void _startConnectivityPolling() {
    _connectivityRetryTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_updateCheckSucceeded && !_isUpdateDialogOpen) {
        _checkForUpdates();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<DashSettingsProvider>();
    final obd = context.read<ObdProvider>();

    if (state == AppLifecycleState.resumed) {
      _triggerGreeting();
      obd.handleAppResume();
      _checkForUpdates();
      _checkRemoteAnnouncements();
      AnalyticsService.instance.updateSessionActivity();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Guardado preventivo antes de que la radio entre en Sleep profundo
      settings.saveAllSettings();
      obd.saveConnectionState();
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

  bool _showTutorial = false;

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    final tutorialDone = prefs.getBool('tutorial_done') ?? false;

    // Registrar apertura de app
    if (prefs.getBool('app_first_open_logged') != true) {
      AnalyticsService.instance.logEvent('app_first_open');
      await prefs.setBool('app_first_open_logged', true);
    }
    AnalyticsService.instance.logEvent('app_open');

    // Iniciar verificación de actualización en paralelo
    _checkForUpdates();
    _checkRemoteAnnouncements();

    final settings = context.read<DashSettingsProvider>();
    final obd = context.read<ObdProvider>();
    
    // Vincular estadísticas de conducción
    obd.onStatsUpdate = (speed, distance) {
      settings.updateStats(speed, distance);
    };

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = SupabaseService.instance.currentUser;

    setState(() {
      _showOnboarding = !done;
      _showTutorial = false; // Se activará tras el saludo de bienvenida
      _isLoading = false;
      _currentIndex = settings.lastScreenIndex; 

      if (done && settings.showWelcomeGreeting) {
        _welcomeUsername = user != null
            ? (user.userMetadata?['display_name'] ?? user.email?.split('@')[0] ?? 'USUARIO')
            : 'INVITADO';
        _isGreetingActive = true;
      }
    });
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_done', true);
    setState(() => _showTutorial = false);
  }

  Future<void> _checkForUpdates() async {
    if (_isUpdateDialogOpen) return;

    try {
      final release = await SupabaseService.instance.getActiveVersion();
      _updateCheckSucceeded = true;
      if (release.isEmpty) return;

      final int latestVersionCode = release['version_code'] ?? 0;
      final int minVersionCode = release['minimum_version_code'] ?? 0;
      final bool isMandatory = release['is_mandatory'] ?? false;
      const int currentVersionCode = SupabaseService.appBuild;
      const String currentVersion = '1.0.2';

      final bool needsUpdate = latestVersionCode > currentVersionCode;
      final bool mustUpdate = isMandatory || (minVersionCode > currentVersionCode);

      if (needsUpdate) {
        if (!mounted) return;

        AnalyticsService.instance.logEvent('app_update_available', data: {
          'latest_version': release['version_name'],
          'is_mandatory': mustUpdate,
        });

        setState(() => _isUpdateDialogOpen = true);

        await showDialog(
          context: context,
          barrierDismissible: !mustUpdate,
          builder: (context) => WillPopScope(
            onWillPop: () async => !mustUpdate,
            child: UpdateDialog(
              currentVersion: currentVersion,
              newVersion: release['version_name'] ?? 'Nueva',
              downloadUrl: release['download_url'] ?? '',
              releaseNotes: release['release_notes'] ?? 'Mejoras de rendimiento y corrección de errores.',
              isMandatory: mustUpdate,
            ),
          ),
        );

        if (mounted) setState(() => _isUpdateDialogOpen = false);
      }
    } catch (e) {
      debugPrint('Error checking updates: $e');
    }
  }

  Future<void> _checkRemoteAnnouncements() async {
    try {
      final announcement = await SupabaseService.instance.getActiveAnnouncement();
      if (announcement == null) return;

      final String id = announcement['id']?.toString() ?? '';
      if (id.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('last_announcement_id');

      if (id == lastId) return;

      if (!mounted) return;

      AnalyticsService.instance.logEvent('remote_announcement_shown', data: {
        'announcement_id': id,
        'title': announcement['title'],
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            announcement['title'] ?? 'AVISO',
            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
          ),
          content: Text(
            announcement['message'] ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AnalyticsService.instance.logEvent('remote_announcement_closed', data: {
                  'announcement_id': id,
                });
                Navigator.pop(context);
              },
              child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        ),
      );

      await prefs.setString('last_announcement_id', id);
    } catch (e) {
      debugPrint('Error comprobando avisos: $e');
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
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOutSine,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/icon/Logoapp.png',
                  width: 180,
                  height: 180,
                ),
                onEnd: () {},
              ),
              const SizedBox(height: 40),
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
                onFinished: () async {
                  if (mounted) {
                    setState(() {
                      _isGreetingActive = false;
                    });

                    // Iniciar tutorial solo tras el saludo de bienvenida si no se ha hecho
                    final prefs = await SharedPreferences.getInstance();
                    final tutorialDone = prefs.getBool('tutorial_done') ?? false;
                    if (!tutorialDone) {
                      setState(() => _showTutorial = true);
                    }
                  }
                },
              ),
            ),

          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(onFinish: _finishTutorial),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// LOADING LOGO ANIMATION (Legacy classes removed)
// ================================================================
