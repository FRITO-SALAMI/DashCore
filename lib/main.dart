import 'dart:async';
import 'dart:ffi' show IntPtr, sizeOf;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/bluetooth_obd_connection.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'providers/obd_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/dash_settings_provider.dart';
import 'providers/music_provider.dart';
import 'core/app_themes.dart';
import 'screens/root_screen.dart';
import 'widget/reconnection_banner.dart';
import 'widget/animated_startup_splash.dart';
import 'utils/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final arm32 = Platform.isAndroid && sizeOf<IntPtr>() == 4;
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = (arm32 ? 16 : 32) * 1024 * 1024
    ..maximumSize = arm32 ? 40 : 80;

  final backend = _prepareBackend();
  final preferences = SharedPreferences.getInstance().timeout(
    const Duration(milliseconds: 600),
  );

  // Handler global de errores para analítica
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    SyncService.instance.logError(
      details.exceptionAsString(),
      details.stack.toString(),
    );
  };

  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => FlutterNativeSplash.remove(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DashSettingsProvider>(
          create: (_) => DashSettingsProvider(),
        ),
        ChangeNotifierProvider<MusicProvider>(create: (_) => MusicProvider()),
        ChangeNotifierProvider<BluetoothProvider>(
          create: (_) => BluetoothProvider(),
        ),
        ChangeNotifierProxyProvider<BluetoothProvider, ObdProvider>(
          create: (context) {
            final obd = ObdProvider(
              BluetoothObdConnection(context.read<BluetoothProvider>()),
            );

            obd.onAccStateChanged = (sleeping) {
              context.read<DashSettingsProvider>().setAppActive(!sleeping);
            };

            // Link stats update to DashSettingsProvider
            obd.onStatsUpdate = (speed, delta) {
              context.read<DashSettingsProvider>().updateStats(speed, delta);
            };

            return obd;
          },
          update: (context, bluetoothProvider, obdProvider) {
            obdProvider!.updateConnection(
              BluetoothObdConnection(bluetoothProvider),
            );

            // Re-ensure callback on update
            obdProvider.onStatsUpdate = (speed, delta) {
              context.read<DashSettingsProvider>().updateStats(speed, delta);
            };

            return obdProvider;
          },
        ),
      ],
      child: DashCoreApp(backend: backend, preferences: preferences),
    ),
  );
}

Future<void> _prepareBackend() async {
  try {
    await SupabaseService.initialize().timeout(const Duration(seconds: 3));
    unawaited(
      SyncService.instance.initialize().catchError((Object error) {
        debugPrint('DashCore sync: $error');
      }),
    );
  } catch (error) {
    debugPrint('DashCore startup: $error');
  }
}

class DashCoreApp extends StatelessWidget {
  const DashCoreApp({
    super.key,
    required this.backend,
    required this.preferences,
  });

  final Future<void> backend;
  final Future<SharedPreferences> preferences;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashCore',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.darkTheme,
      home: const RootScreen(),
      builder: (context, child) {
        return FutureBuilder<SharedPreferences?>(
          future: preferences,
          builder: (context, local) => FutureBuilder<void>(
            future: backend,
            builder: (context, remote) => _StartupDashboard(
              prefs: local.data,
              ready: local.connectionState == ConnectionState.done,
              dashboardReady: remote.connectionState == ConnectionState.done,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _StartupDashboard extends StatelessWidget {
  const _StartupDashboard({
    required this.prefs,
    required this.child,
    required this.ready,
    required this.dashboardReady,
  });

  final SharedPreferences? prefs;
  final Widget child;
  final bool ready, dashboardReady;

  @override
  Widget build(BuildContext context) {
    final ignition = dashboardReady
        ? context.select(
            (DashSettingsProvider settings) => (
              brand: settings.selectedVehicle?.brand,
              lowResource: settings.isLowResourceDevice,
              powerSaving: settings.reduceOrbitMotion,
            ),
          )
        : null;
    final sleeping =
        dashboardReady && context.select((ObdProvider obd) => obd.accSleeping);
    final override = prefs?.getString('ignition_profile');
    final profile = IgnitionProfile.forBrand(
      override ?? ignition?.brand ?? prefs?.getString('ignition_vehicle_brand'),
    );
    return AnimatedStartupSplash(
      profile: profile,
      ready: ready,
      dashboardReady: dashboardReady,
      enabled:
          override != 'off' &&
          ignition?.powerSaving != true &&
          prefs?.getBool('is_power_saving_mode') != true &&
          prefs?.getInt('performance_mode_idx') !=
              PerformanceMode.powerSaving.index,
      compact:
          ignition?.lowResource ??
          (Platform.isAndroid && sizeOf<IntPtr>() == 4),
      accSleeping: sleeping,
      child: dashboardReady
          ? Stack(
              fit: StackFit.expand,
              children: [child, const _ConnectionStatusBanner()],
            )
          : const SizedBox.expand(),
    );
  }
}

class _ConnectionStatusBanner extends StatelessWidget {
  const _ConnectionStatusBanner();

  @override
  Widget build(BuildContext context) {
    final isBluetoothReconnecting = context.select(
      (BluetoothProvider provider) => provider.isReconnectingBackground,
    );
    final isObdRecovering = context.select(
      (ObdProvider provider) =>
          provider.isRealMode && provider.state != ObdConnectionState.ready,
    );

    final bool showBanner = isBluetoothReconnecting || isObdRecovering;

    final loc = AppLocalizations.of(context);

    final String message = isObdRecovering
        ? loc.translate('connecting_obd_dots')
        : isBluetoothReconnecting
        ? loc.translate('reconnecting')
        : '';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      top: showBanner ? MediaQuery.of(context).padding.top + 10 : -100,
      right: 16,
      child: IgnorePointer(
        ignoring: !showBanner,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: showBanner ? 1.0 : 0.0,
          child: ReconnectionBanner(message: message),
        ),
      ),
    );
  }
}
