import 'dart:async';
import '../widget/brightness_settings.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dashcore/screens/dashleague_screen.dart';
import 'package:dashcore/screens/password_recovery_dialog.dart';
import 'package:dashcore/screens/car_screen.dart';
import 'package:dashcore/screens/connect_screen.dart';
import 'package:dashcore/screens/home_screen.dart' as home;
import 'package:dashcore/screens/onboarding_screen.dart';
import 'package:dashcore/screens/settings_screen.dart';
import 'package:dashcore/screens/store_screen.dart';
import 'package:dashcore/screens/styles_screen.dart';
import 'package:dashcore/screens/update_center_screen.dart';
import '../widget/workshop_diagnostics_panel.dart';
import 'package:dashcore/widget/update_dialog.dart';
import 'package:dashcore/widget/tutorial_overlay.dart';
import 'package:dashcore/widget/home_screen/hidden_menu_overlay.dart'
    as hidden_menu;
import 'package:dashcore/widget/welcome_greeting.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/services/sync_service.dart';

import 'package:dashcore/screens/auth_screen.dart';
import 'package:dashcore/services/diagnostic_service.dart';
import 'package:dashcore/services/performance_monitor_service.dart';
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
  StreamSubscription<Map<String, dynamic>>? _announcementSubscription;
  StreamSubscription<bool>? _rankingSyncSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveryDialogOpen = false;
  bool _announcementDialogOpen = false;
  Map<String, dynamic>? _pendingAnnouncement;
  bool _isRankingSyncing = false;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !settings.isTutorialActive) return;
        setState(() {
          if ({2, 5, 8, 9, 11}.contains(step)) {
            _currentIndex = 0;
            _showMenu = true;
          } else {
            _showMenu = false;
            _currentIndex = switch (step) {
              3 || 4 => 3,
              6 => 2,
              10 => 4,
              12 => 5,
              _ => 0,
            };
          }
        });
        settings.setDashboardVisible(_currentIndex == 0);
      });
    };
    context.read<DashSettingsProvider>().addListener(_tutorialListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _syncPerformanceMonitoring(context.read<DashSettingsProvider>());
        await _checkForAppUpdate();
        await _checkProfileCompletion();
      }
    });
    _announcementSubscription = SyncService.instance.announcements.listen(
      _showRemoteAnnouncement,
    );
    unawaited(SyncService.instance.refreshActiveAnnouncement());
    _authSubscription = SupabaseService.instance.client?.auth.onAuthStateChange
        .listen((state) {
          _loadWelcomeUsername();
          if (state.event == AuthChangeEvent.passwordRecovery) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_openPasswordRecovery());
            });
            WidgetsBinding.instance.ensureVisualUpdate();
          }
        });
    unawaited(_loadWelcomeUsername());
    _rankingSyncSubscription = SyncService.instance.rankingSyncChanges.listen((
      syncing,
    ) {
      if (mounted) setState(() => _isRankingSyncing = syncing);
    });
  }

  Future<void> _showRemoteAnnouncement(
    Map<String, dynamic> announcement,
  ) async {
    if (!mounted) return;
    if (_announcementDialogOpen) {
      _pendingAnnouncement = announcement;
      return;
    }
    final expiresAt = DateTime.tryParse(
      announcement['expires_at']?.toString() ?? '',
    );
    if (expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc())) return;

    final priority = int.tryParse('${announcement['priority'] ?? 0}') ?? 0;
    final severity = '${announcement['severity'] ?? announcement['type'] ?? ''}'
        .toLowerCase();
    final critical = priority >= 3 || severity == 'critical';
    _announcementDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: !critical,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          critical ? Icons.warning_amber_rounded : Icons.campaign_rounded,
          color: critical ? Colors.redAccent : Colors.cyanAccent,
          size: 38,
        ),
        title: Text(announcement['title']?.toString() ?? 'Aviso de DashCore'),
        content: Text(announcement['message']?.toString() ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(critical ? 'ENTENDIDO' : 'CERRAR'),
          ),
        ],
      ),
    );
    _announcementDialogOpen = false;
    final pending = _pendingAnnouncement;
    _pendingAnnouncement = null;
    if (pending != null && mounted) {
      await _showRemoteAnnouncement(pending);
    }
  }

  Future<void> _loadWelcomeUsername() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _welcomeUsername = 'INVITADO');
      return;
    }
    String? nickname;
    try {
      nickname = (await SupabaseService.instance.getMyProfile())?['username']
          ?.toString();
    } catch (_) {}
    nickname ??= user.userMetadata?['username']?.toString();
    nickname ??= user.userMetadata?['display_name']?.toString();
    nickname ??= user.email?.split('@').first;
    final resolvedNickname = nickname?.trim();
    if (mounted && resolvedNickname != null && resolvedNickname.isNotEmpty) {
      setState(() => _welcomeUsername = resolvedNickname);
    }
  }

  Future<void> _checkProfileCompletion() async {
    if (!await SupabaseService.instance.currentProfileNeedsCompletion() ||
        !mounted)
      return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.manage_accounts_rounded,
          color: Color(0xFF00E5FF),
          size: 42,
        ),
        title: const Text('COMPLETA TU PERFIL', textAlign: TextAlign.center),
        content: const Text(
          'Agrega tu nombre y nickname para identificarte correctamente en DashLeague.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final completed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(completeProfile: true),
                ),
              );
              if (completed == true && mounted) {
                showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('¡BIENVENIDO A DASHCORE!'),
                    content: Text(
                      'Tus datos están completos. Puedes modificar tu perfil y foto desde Configuración.',
                    ),
                  ),
                );
              }
            },
            child: const Text('ACTUALIZA TUS DATOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPasswordRecovery() async {
    if (_recoveryDialogOpen) return;
    final auth = SupabaseService.instance.client?.auth;
    if (auth == null) return;
    _recoveryDialogOpen = true;
    try {
      final changed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PasswordRecoveryDialog(
          savePassword: (password) async {
            await auth.updateUser(UserAttributes(password: password));
          },
        ),
      );
      if (changed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada.')),
        );
      }
    } finally {
      _recoveryDialogOpen = false;
    }
  }

  void _syncPerformanceMonitoring(DashSettingsProvider settings) {
    if (settings.performanceMonitoringEnabled &&
        !context.read<ObdProvider>().accSleeping) {
      PerformanceMonitorService.instance.start(context.read<ObdProvider>());
    } else {
      PerformanceMonitorService.instance.stop();
    }
  }

  Future<void> _checkForAppUpdate() async {
    if (_isUpdateDialogOpen) return;
    try {
      final package = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(package.buildNumber) ?? 0;
      final release = await SupabaseService.instance.getActiveVersion();
      if (!mounted || release.isEmpty) return;
      final latestCode = (release['version_code'] as num?)?.toInt() ?? 0;
      final minCode = (release['min_version_code'] as num?)?.toInt() ?? 0;
      if (latestCode <= currentCode) {
        context.read<DashSettingsProvider>().setHasUpdateAvailable(false);
        return;
      }
      final mandatory =
          release['is_mandatory'] == true || minCode > currentCode;
      context.read<DashSettingsProvider>().setHasUpdateAvailable(true);
      _isUpdateDialogOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: !mandatory,
        builder: (_) => PopScope(
          canPop: !mandatory,
          child: UpdateDialog(
            currentVersion: package.version,
            newVersion: release['version_name']?.toString(),
            downloadUrl: release['download_url']?.toString(),
            releaseNotes: release['release_notes']?.toString(),
            isMandatory: mandatory,
          ),
        ),
      );
      _isUpdateDialogOpen = false;
      _updateCheckSucceeded = true;
    } catch (error) {
      debugPrint('[UPDATE] No se pudo comprobar la versión: $error');
      _isUpdateDialogOpen = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Head units commonly move the activity to the background while ACC and
    // the foreground OBD service remain active. ACC events, not visibility,
    // control the deep power-saving state.
    context.read<ObdProvider>().setForeground(
      state == AppLifecycleState.resumed,
    );
    context.read<DashSettingsProvider>().setAppActive(
      !context.read<ObdProvider>().accSleeping,
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(SyncService.instance.refreshActiveAnnouncement());
      unawaited(_checkForAppUpdate());
      unawaited(_loadWelcomeUsername());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _announcementSubscription?.cancel();
    _rankingSyncSubscription?.cancel();
    _authSubscription?.cancel();

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
    context.read<DashSettingsProvider>().setDashboardVisible(index == 0);
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
    final settings = context.watch<DashSettingsProvider>();
    final sleeping = context.select<ObdProvider, bool>(
      (obd) => obd.accSleeping,
    );
    if (sleeping) {
      PerformanceMonitorService.instance.stop();
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MODO 2DO PLANO · ACC OFF',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

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

    final List<Widget> _screens = [
      const home.HomeScreen(),
      ConnectionScreen(onBack: () => _onNavigate(0)),
      StylesScreen(onBack: () => _onNavigate(0)),
      StoreScreen(
        key: ValueKey('store-tutorial-${settings.tutorialStep}'),
        onBack: () {
          _onNavigate(0);
          if (settings.isTutorialActive && settings.tutorialStep == 5) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _openMenu());
          }
        },
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('DIAGNÓSTICO'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onNavigate(0),
          ),
        ),
        body: const WorkshopDiagnosticsPanel(),
      ),
      SettingsScreen(onBack: () => _onNavigate(0)),
      UpdateCenterScreen(onBack: () => _onNavigate(0)),
      DashLeagueScreen(onBack: () => _onNavigate(0)),
      CarScreen(onBack: () => _onNavigate(0)),
    ];

    return BrightnessRuntime(
      child: Scaffold(
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

            if (_isRankingSyncing)
              Positioned(
                top: 18,
                right: 18,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101820).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 18),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'ACTUALIZANDO RANKING...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (settings.isTutorialActive)
              TutorialOverlay(
                onFinish: () {
                  // Tutorial finished logic
                },
              ),
          ],
        ),
      ),
    );
  }
}
