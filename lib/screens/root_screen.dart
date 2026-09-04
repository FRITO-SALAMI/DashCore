import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:dashcore/screens/dashleague_screen.dart';
import 'package:dashcore/screens/car_screen.dart';
import 'package:dashcore/screens/connect_screen.dart';
import 'package:dashcore/screens/home_screen.dart' as home;
import 'package:dashcore/screens/onboarding_screen.dart';
import 'package:dashcore/screens/settings_screen.dart';
import 'package:dashcore/screens/store_screen.dart';
import 'package:dashcore/screens/styles_screen.dart';
import 'package:dashcore/screens/update_center_screen.dart';
import 'package:dashcore/screens/workshop_screen.dart';
import 'package:dashcore/widget/update_dialog.dart';
import 'package:dashcore/widget/tutorial_overlay.dart';
import 'package:dashcore/widget/home_screen/hidden_menu_overlay.dart'
    as hidden_menu;
import 'package:dashcore/widget/welcome_greeting.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/services/analytics_service.dart';
import 'package:dashcore/services/diagnostic_service.dart';
import 'package:dashcore/services/performance_monitor_service.dart';
import 'package:dashcore/providers/music_provider.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _showMenu = false;
  bool _showOnboarding = false;
  bool _isGreetingActive = false;
  bool _isUpdateDialogOpen = false;
  bool _updateCheckSucceeded = false;
  String _welcomeUsername = 'INVITADO';
  VoidCallback? _tutorialListener;
  int _lastTutorialStep = -1;

  @override
  void initState() {
    super.initState();
    try {
      DiagnosticService.init();
      DiagnosticService.log("APP START");
    } catch (e) {}

    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
    _tutorialListener = () {
      if (!mounted) return;
      final settings = context.read<DashSettingsProvider>();
      _syncPerformanceMonitoring(settings);
      final step = settings.tutorialStep;
      if (!settings.isTutorialActive || step == _lastTutorialStep) return;
      _lastTutorialStep = step;
      if (step == 2 || step == 5 || step == 8 || step == 9 || step == 11) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !settings.isTutorialActive) return;
          setState(() {
            _currentIndex = 0;
            _showMenu = true;
          });
        });
      }
    };
    context.read<DashSettingsProvider>().addListener(_tutorialListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPerformanceMonitoring(context.read<DashSettingsProvider>());
      }
    });
  }

  void _syncPerformanceMonitoring(DashSettingsProvider settings) {
    if (settings.performanceMonitoringEnabled) {
      PerformanceMonitorService.instance.start(context.read<ObdProvider>());
    } else {
      PerformanceMonitorService.instance.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Head units commonly move the activity to the background while ACC and
    // the foreground OBD service remain active. ACC events, not visibility,
    // control the deep power-saving state.
    context.read<DashSettingsProvider>().setAppActive(true);
    if (state == AppLifecycleState.resumed) {
      context.read<MusicProvider>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_tutorialListener != null) {
      try {
        context.read<DashSettingsProvider>().removeListener(_tutorialListener!);
      } catch (_) {}
    }
    PerformanceMonitorService.instance.stop();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingDone;
        if (onboardingDone) {
          _isGreetingActive = context
              .read<DashSettingsProvider>()
              .showWelcomeGreeting;
        }
      });
    }
  }

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
      _showMenu = false;
    });
  }

  void _openMenu() {
    setState(() => _showMenu = true);
  }

  void _closeMenu() {
    setState(() => _showMenu = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onFinish: () {
          setState(() {
            _showOnboarding = false;
            _isGreetingActive = context
                .read<DashSettingsProvider>()
                .showWelcomeGreeting;
          });
        },
      );
    }

    final settings = context.watch<DashSettingsProvider>();

    final List<Widget> _screens = [
      const home.HomeScreen(),
      ConnectionScreen(onBack: () => _onNavigate(0)),
      StylesScreen(onBack: () => _onNavigate(0)),
      StoreScreen(
        onBack: () {
          _onNavigate(0);
          if (settings.isTutorialActive && settings.tutorialStep == 5) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _openMenu());
          }
        },
      ),
      WorkshopScreen(onBack: () => _onNavigate(0)),
      SettingsScreen(onBack: () => _onNavigate(0)),
      UpdateCenterScreen(onBack: () => _onNavigate(0)),
      DashLeagueScreen(onBack: () => _onNavigate(0)),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _currentIndex == 0
                ? () {
                    if (settings.isTutorialActive &&
                        settings.tutorialStep == 1) {
                      settings.setTutorialStep(2);
                    }
                    if (!_showMenu) _openMenu();
                  }
                : null,
            child: _screens[_currentIndex],
          ),

          if (_showMenu)
            hidden_menu.HiddenMenuOverlay(
              currentIndex: _currentIndex,
              onItemSelected: (index) {
                if (settings.isTutorialActive) {
                  if (index == 3 && settings.tutorialStep == 2)
                    settings.setTutorialStep(3);
                  if (index == 2 && settings.tutorialStep == 5)
                    settings.setTutorialStep(6);
                  if (index == 4 && settings.tutorialStep == 9)
                    settings.setTutorialStep(10);
                  if (index == 5 && settings.tutorialStep == 11)
                    settings.setTutorialStep(12);
                }
                _onNavigate(index);
              },
              onClose: _closeMenu,
            ),

          if (_isGreetingActive)
            PremiumWelcomeOverlay(
              username: _welcomeUsername,
              design: settings.welcomeDesign,
              durationSeconds: settings.welcomeGreetingDuration,
              onFinished: () => setState(() => _isGreetingActive = false),
            ),

          if (settings.isTutorialActive)
            TutorialOverlay(
              onFinish: () {
                // Tutorial finished logic
              },
            ),
        ],
      ),
    );
  }
}
