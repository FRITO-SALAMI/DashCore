import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/bluetooth_obd_connection.dart';
import 'services/supabase_service.dart';
import 'services/analytics_service.dart';
import 'providers/obd_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/dash_settings_provider.dart';
import 'providers/music_provider.dart';
import 'core/app_themes.dart';
import 'screens/root_screen.dart';
import 'widget/reconnection_banner.dart';
import 'utils/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  // Handler global de errores para analítica
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AnalyticsService.instance.logEvent('error', data: {
      'exception': details.exceptionAsString(),
      'stack': details.stack.toString().split('\n').take(10).join('\n'),
    });
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DashSettingsProvider>(
          create: (_) => DashSettingsProvider(),
        ),
        ChangeNotifierProvider<MusicProvider>(
          create: (_) => MusicProvider(),
        ),
        ChangeNotifierProvider<BluetoothProvider>(
          create: (_) => BluetoothProvider(),
        ),
        ChangeNotifierProxyProvider<BluetoothProvider, ObdProvider>(
          create: (context) {
            return ObdProvider(
              BluetoothObdConnection(
                context.read<BluetoothProvider>(),
              ),
            );
          },
          update: (
              context,
              bluetoothProvider,
              obdProvider,
              ) {
            obdProvider!.updateConnection(
              BluetoothObdConnection(
                bluetoothProvider,
              ),
            );

            return obdProvider;
          },
        ),
      ],
      child: const DashCoreApp(),
    ),
  );
}

class DashCoreApp extends StatelessWidget {
  const DashCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashCore',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.darkTheme,
      home: const RootScreen(),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            Consumer2<BluetoothProvider, ObdProvider>(
              builder: (
                  context,
                  bluetoothProvider,
                  obdProvider,
                  _,
                  ) {
                final bool isBluetoothReconnecting =
                    bluetoothProvider.isReconnectingBackground;

                final bool isObdRecovering =
                    obdProvider.isRealMode &&
                        obdProvider.state ==
                            ObdConnectionState.initializing;

                final bool showBanner =
                    isBluetoothReconnecting || isObdRecovering;

                final loc = AppLocalizations.of(context);

                final String message = isBluetoothReconnecting
                    ? loc.translate('reconnecting')
                    : isObdRecovering
                    ? loc.translate(obdProvider.initMessage)
                    : '';

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  top: showBanner
                      ? MediaQuery.of(context).padding.top + 10
                      : -100,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: !showBanner,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: showBanner ? 1.0 : 0.0,
                      child: ReconnectionBanner(
                        message: message,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}