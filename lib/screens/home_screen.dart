import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/obd_provider.dart';
import '../providers/dash_settings_provider.dart';
import '../providers/music_provider.dart';
import '../widget/gauges/sporty_dashboard.dart';
import '../widget/gauges/racing_dashboard.dart';
import '../widget/gauges/modern_dashboard.dart';
import '../widget/gauges/vehicle_3d_dashboard.dart';
import '../widget/gauges/racing_hud_dashboard.dart';
import '../widget/gauges/glow_red_dashboard.dart';
import '../widget/gauges/hellish_red_dashboard.dart';
import '../widget/gauges/custom_gauge_widget.dart';
import '../widget/gauges/retro_lcd_dashboard.dart';
import '../widget/gauges/ev_cluster_dashboard.dart';
import 'dashboard/themes/tesla_style_theme_screen.dart';
import 'dashboard/themes/classic_sport_theme_screen.dart';
import 'dashboard/themes/race_cluster_theme_screen.dart';
import 'dashboard/themes/modern_tesla_themes.dart';

import '../widget/gauges/purple_maps_dashboard.dart';
import '../widget/gauges/neon_world_dashboard.dart';
import '../widget/gauges/dashcore_dashboard.dart';
import '../utils/app_localizations.dart';
import '../widget/dashboard_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<String>? _errorSubscription;

  bool _showStyleConfig = false;
  String? _editingGaugeId;
  bool _isPickerOpen = false;

  VoidCallback? _settingsListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = context.read<ObdProvider>();
      final dashSettings = context.read<DashSettingsProvider>();
      final musicProvider = context.read<MusicProvider>();

      _requestInitialPermissions(musicProvider);

      _settingsListener = () {
        if (mounted) {
          _checkResources(dashSettings);
        }
      };

      dashSettings.addListener(_settingsListener!);

      _checkResources(dashSettings);

      _errorSubscription = provider.errorEvents.listen((errorMessage) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    });
  }

  Future<void> _requestInitialPermissions(MusicProvider music) async {
    final status = await [
      Permission.location,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ].request();

    if (status[Permission.location]?.isDenied ?? false) {
      debugPrint('Location permission denied');
    }

    await music.requestPermissions();
  }

  void _checkResources(DashSettingsProvider settings) {
    final vehicle = settings.selectedVehicle;

    if (vehicle != null &&
        !vehicle.isDownloaded &&
        vehicle.modelUrl != null) {
      _showDownloadDialog(context, settings);
    }
  }

  void _showDownloadDialog(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<DashSettingsProvider>(
          builder: (context, provider, _) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1D24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'DESCARGAR RECURSOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Es necesario descargar el modelo 3D y fondos para este vehículo.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (provider.isDownloadingResources) ...[
                    LinearProgressIndicator(
                      value: provider.downloadProgress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(provider.downloadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      provider.downloadSizeMessage,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              actions: [
                if (!provider.isDownloadingResources)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'MÁS TARDE',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ElevatedButton(
                  onPressed: provider.isDownloadingResources
                      ? null
                      : () async {
                          final success =
                              await provider.downloadVehicleResources();

                          if (success && mounted) {
                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Recursos descargados correctamente',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    disabledBackgroundColor: Colors.white10,
                  ),
                  child: Text(
                    provider.isDownloadingResources
                        ? 'DESCARGANDO...'
                        : 'DESCARGAR AHORA',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();

    if (_settingsListener != null) {
      try {
        context.read<DashSettingsProvider>().removeListener(
              _settingsListener!,
            );
      } catch (_) {}
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obdProvider = context.watch<ObdProvider>();
    final dashSettings = context.watch<DashSettingsProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final obdData = obdProvider.data;

    final isGifBackground = dashSettings.backgroundImage?.endsWith('.gif') ?? false;

    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildSelectedDashboard(
                  dashSettings,
                  obdData,
                  musicProvider,
                ),
              ),
            ),

            if (dashSettings.lightDesign != 0 && !isGifBackground && dashSettings.selectedStyle != DashboardStyle.sketch)
              Positioned.fill(
                child: _DashboardLightOverlay(
                  color: dashSettings.lightColor,
                  design: dashSettings.lightDesign,
                  rpm: obdData.rpm,
                ),
              ),

            ...dashSettings.customGauges.map((config) {
              final bool isBeingEdited =
                  _editingGaugeId == config.id;

              return Positioned(
                left: config.position.dx,
                top: config.position.dy,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: dashSettings.isEditMode
                          ? () {
                              setState(() {
                                _editingGaugeId = config.id;
                                _showStyleConfig = true;
                              });
                            }
                          : null,
                      onPanUpdate: dashSettings.isEditMode
                          ? (details) {
                              dashSettings.updateGaugePosition(
                                config.id,
                                config.position + details.delta,
                              );
                            }
                          : null,
                      onLongPress: dashSettings.isEditMode
                          ? () {
                              dashSettings.removeCustomGauge(config.id);

                              if (_editingGaugeId == config.id) {
                                setState(() {
                                  _editingGaugeId = null;
                                });
                              }
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: isBeingEdited
                              ? Border.all(
                                  color: Colors.white,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CustomGaugeWidget(
                          type: config.type,
                          value: _getGaugeValue(
                            config.type,
                            obdData,
                          ),
                          unit: _getGaugeUnit(config.type),
                          color: dashSettings.accentColor,
                          size: config.size,
                          design: config.design,
                          logoPath: config.logoPath,
                        ),
                      ),
                    ),
                    if (dashSettings.isEditMode && isBeingEdited)
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            final newSize = Size(
                              (config.size.width + details.delta.dx)
                                  .clamp(80.0, 600.0), // Min size increased
                              (config.size.height + details.delta.dy)
                                  .clamp(40.0, 400.0),
                            );

                            dashSettings.updateGaugeSize(
                              config.id,
                              newSize,
                            );
                          },
                          child: Container(
                            width: 50, height: 50, // Even larger area
                            color: Colors.transparent, // Ensure it captures taps
                            child: Center(
                              child: Container(
                                width: 28, height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E5FF),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                                ),
                                child: const Icon(
                                  Icons.open_in_full_rounded,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            if (dashSettings.isEditMode)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13161D).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _EditBarButton(
                          icon: Icons.add_rounded,
                          label: 'GADGET',
                          onTap: () => _showAddGaugeMenu(context, dashSettings),
                        ),
                        _EditBarButton(
                          icon: Icons.create_new_folder_rounded,
                          label: loc.translate('new_sketch'),
                          onTap: () {
                             dashSettings.createNewSketch();
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(loc.translate('new_sketch')))
                             );
                          },
                        ),
                        _EditBarButton(
                          icon: Icons.palette_rounded,
                          label: 'STYLING',
                          onTap: () {
                            setState(() {
                              _showStyleConfig = !_showStyleConfig;
                              if (!_showStyleConfig) _editingGaugeId = null;
                            });
                          },
                        ),
                        const VerticalDivider(color: Colors.white10, indent: 20, endIndent: 20),
                        _EditBarButton(
                          icon: Icons.check_circle_rounded,
                          label: 'FINISH EDITING',
                          color: const Color(0xFF00E5FF),
                          onTap: () {
                            if (dashSettings.selectedStyle == DashboardStyle.sketch) {
                              dashSettings.saveAsMyStyle();
                            }
                            dashSettings.toggleEditMode();
                            setState(() {
                              _showStyleConfig = false;
                              _editingGaugeId = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_showStyleConfig && dashSettings.isEditMode)
              Positioned(
                left: 20,
                top: 20,
                bottom: 20,
                width: 280,
                child: _StyleConfigPanel(
                  settings: dashSettings,
                  editingGaugeId: _editingGaugeId,
                  onClose: () {
                    setState(() {
                      _showStyleConfig = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddGaugeMenu(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AÑADIR INDICADOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _AddGaugeItem(
                      icon: Icons.speed,
                      label: 'VEL',
                      onTap: () {
                        settings.addCustomGauge('speed');
                        Navigator.pop(ctx);
                      },
                    ),
                    _AddGaugeItem(
                      icon: Icons.track_changes,
                      label: 'RPM',
                      onTap: () {
                        settings.addCustomGauge('rpm');
                        Navigator.pop(ctx);
                      },
                    ),
                    _AddGaugeItem(
                      icon: Icons.thermostat,
                      label: 'TEMP',
                      onTap: () {
                        settings.addCustomGauge('temp');
                        Navigator.pop(ctx);
                      },
                    ),
                    _AddGaugeItem(
                      icon: Icons.local_gas_station_rounded,
                      label: 'FUEL',
                      onTap: () {
                        settings.addCustomGauge('fuel');
                        Navigator.pop(ctx);
                      },
                    ),
                    _AddGaugeItem(
                      icon: Icons.bolt,
                      label: 'VOLT',
                      onTap: () {
                        settings.addCustomGauge('volt');
                        Navigator.pop(ctx);
                      },
                    ),
                    _AddGaugeItem(
                      icon: Icons.music_note_rounded,
                      label: 'MUSIC',
                      onTap: () {
                        settings.addCustomGauge('music_hub');
                        Navigator.pop(ctx);
                      },
                    ),
                    _AddGaugeItem(
                      icon: Icons.crop_square_rounded,
                      label: 'BOX',
                      onTap: () {
                        settings.addCustomGauge('box');
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  dynamic _getGaugeValue(
    String type,
    dynamic data,
  ) {
    switch (type) {
      case 'speed':
        return data.speed;

      case 'rpm':
        return data.rpm;

      case 'temp':
        return data.engineTemp;

      case 'fuel':
        return data.fuelLevel;

      case 'music_hub':
        return '';

      case 'volt':
      default:
        return data.voltage.toStringAsFixed(1);
    }
  }

  String _getGaugeUnit(String type) {
    switch (type) {
      case 'speed':
        return 'KM/H';

      case 'rpm':
        return 'RPM';

      case 'temp':
        return '°C';

      case 'fuel':
        return '%';

      case 'music_hub':
        return '';

      case 'volt':
      default:
        return 'V';
    }
  }

  Widget _buildSelectedDashboard(
    DashSettingsProvider settings,
    dynamic obdData,
    MusicProvider music,
  ) {
    final loc = AppLocalizations.of(context);
    final tempUnitStr =
        settings.tempUnit == TemperatureUnit.celsius
            ? '°C'
            : '°F';

    final convertedTemp =
        settings.convertTemp(obdData.engineTemp).round();

    final fuelLevel = settings.useSimulatedFuel
        ? settings.simulatedFuelLevel.round()
        : obdData.fuelLevel.round();

    switch (settings.selectedStyle) {
      case DashboardStyle.sporty:
        return SportyDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          needleColor: settings.needleColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
        );

      case DashboardStyle.racing:
        return RacingDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          needleColor: settings.needleColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
        );

      case DashboardStyle.modern:
        return ModernDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          needleColor: settings.needleColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
        );

      case DashboardStyle.vehicle3D:
        return Vehicle3DDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
          modelPath: settings.modelPath,
        );

      case DashboardStyle.purpleMaps:
        return PurpleMapsDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
        );

      case DashboardStyle.neonWorld:
        return NeonWorldDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
        );

      case DashboardStyle.dashcore:
        return DashcoreDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
        );

      case DashboardStyle.racingHud:
        return const RacingHudDashboard();

      case DashboardStyle.glowRed:
        return GlowRedDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
          tempUnit: tempUnitStr,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          trackTitle: music.trackTitle,
          artistName: music.artistName,
        );

      case DashboardStyle.hellishRed:
        return HellishRedDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: convertedTemp,
          voltage: obdData.voltage,
          tempUnit: tempUnitStr,
        );

      case DashboardStyle.teslaStyle:
        return TeslaStyleThemeScreen(
          data: obdData,
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
          fuelLevel: fuelLevel.toDouble(),
          trackTitle: music.trackTitle,
          artistName: music.artistName,
          isPlaying: music.isPlaying,
          progress: music.progress,
          onPlayPause: music.playPause,
          onPrev: music.previous,
          onNext: music.next,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          appSlotBuilder: (context, index) {
            final pkg = settings.teslaAppSlots[index];

            if (pkg == null || pkg.isEmpty) {
              return Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color:
                      settings.accentColor.withOpacity(0.3),
                  size: 30,
                ),
              );
            }

            return Center(
              child: _buildAppIcon(
                pkg,
                settings.accentColor,
              ),
            );
          },
          onAppTap: (index) {
            final pkg = settings.teslaAppSlots[index];

            if (settings.isEditMode) {
              _showTeslaAppPicker(
                context,
                settings,
                index,
              );
            } else {
              if (pkg != null && pkg.isNotEmpty) {
                _launchApp(pkg);
              } else {
                _showTeslaAppPicker(
                  context,
                  settings,
                  index,
                );
              }
            }
          },
        );

      case DashboardStyle.classicSport:
        return ClassicSportThemeScreen(
          data: obdData,
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
          fuelLevel: fuelLevel.toDouble(),
        );

      case DashboardStyle.raceCluster:
        return RaceClusterThemeScreen(
          data: obdData,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
        );

      case DashboardStyle.retroLcd:
        return RetroLcdTheme(
          data: RetroLcdThemeData(
            speed: obdData.speed.toDouble(),
            rpm: obdData.rpm,
            coolantPercent:
                (obdData.engineTemp / 120).clamp(0.0, 1.0),
            fuelLevel: fuelLevel.toDouble(),
            engineTime: '06:99',
            trip: '${obdData.odometer / 10}.0',
          ),
          accentColor: settings.accentColor,
        );

      case DashboardStyle.evCluster:
        return EvClusterTheme(
          data: EvClusterThemeData(
            speedKmh: obdData.speed.toDouble(),
            rpmThousands: obdData.rpm / 1000,
            batteryPercent: fuelLevel.toDouble(),

            // CORREGIDO:
            // EvClusterThemeData requiere estos dos parámetros.
            coolantTemp: convertedTemp.toDouble(),
            voltage: obdData.voltage.toDouble(),

            gear: obdData.gear,
            nowPlayingLabel: music.trackTitle,
          ),
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
        );

      case DashboardStyle.teslaRoad:
        return ModernTeslaRoadTheme(
          data: obdData,
          modelPath: settings.modelPath,
          nowPlayingTitle: music.trackTitle,
          accentColor: settings.accentColor,
        );

      case DashboardStyle.teslaModel:
        return ModernTeslaModelTheme(
          data: obdData,
          modelPath: settings.modelPath,
          nowPlayingTitle: music.trackTitle,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
        );

      case DashboardStyle.sketch:
      case DashboardStyle.myStyle:
        return Stack(
          children: [
            if (settings.backgroundImage != null)
              DashboardBackground(
                backgroundImage: settings.backgroundImage,
                isAssetBackground: settings.isAssetBackground,
                opacity: 0.2,
              ),
            Center(
              child: Text(
                settings.selectedStyle == DashboardStyle.myStyle ? 'MI ESTILO' : loc.translate('new_sketch'),
                style: const TextStyle(color: Colors.white10, fontSize: 40, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAppIcon(
    String pkg,
    Color color,
  ) {
    IconData icon = Icons.apps_rounded;
    final p = pkg.toLowerCase();

    if (p.contains('maps') || p.contains('navigation') || p.contains('waze')) {
      icon = Icons.map_rounded;
    } else if (p.contains('spotify') || p.contains('music') || p.contains('player')) {
      icon = Icons.music_note_rounded;
    } else if (p.contains('youtube') || p.contains('video') || p.contains('netflix')) {
      icon = Icons.video_library_rounded;
    } else if (p.contains('chrome') || p.contains('browser') || p.contains('opera')) {
      icon = Icons.public_rounded;
    } else if (p.contains('phone') || p.contains('dialer') || p.contains('contacts')) {
      icon = Icons.phone_rounded;
    } else if (p.contains('message') || p.contains('sms') || p.contains('whatsapp') || p.contains('telegram') || p.contains('messenger')) {
      icon = Icons.message_rounded;
    } else if (p.contains('setting')) {
      icon = Icons.settings_rounded;
    } else if (p.contains('camera')) {
      icon = Icons.camera_alt_rounded;
    } else if (p.contains('gallery') || p.contains('photo')) {
      icon = Icons.photo_library_rounded;
    } else if (p.contains('radio')) {
      icon = Icons.radio_rounded;
    } else if (p.contains('clock') || p.contains('alarm')) {
      icon = Icons.access_time_filled_rounded;
    }

    return Icon(
      icon,
      color: color,
      size: 40,
    );
  }

  Future<void> _launchApp(String packageName) async {
    const platform = MethodChannel(
      'io.dashcore.app/launcher',
    );

    try {
      await platform.invokeMethod(
        'launchApp',
        {'packageName': packageName},
      );
    } on PlatformException catch (e) {
      debugPrint(
        "Failed to launch app: '${e.message}'.",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir la app: $packageName',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showTeslaAppPicker(
    BuildContext context,
    DashSettingsProvider settings,
    int index,
  ) async {
    if (_isPickerOpen) return;

    _isPickerOpen = true;

    const platform = MethodChannel(
      'io.dashcore.app/launcher',
    );

    List<Map<String, String>> installedApps = [];

    try {
      final List<dynamic>? result =
          await platform.invokeMethod('getInstalledApps');

      if (result != null) {
        installedApps = result
            .map(
              (e) => Map<String, String>.from(e as Map),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching apps: $e');
    }

    if (!context.mounted) {
      _isPickerOpen = false;
      return;
    }

    final pickerResult = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CONFIGURAR ACCESO DIRECTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white38,
                        ),
                        onPressed: () =>
                            Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona una aplicación para el espacio #${index + 1}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: installedApps.length + 1,
                      itemBuilder: (context, i) {
                        if (i == installedApps.length) {
                          return _buildCustomAppButton(
                            context,
                            settings,
                            index,
                          );
                        }

                        final app = installedApps[i];

                        final name =
                            app['name'] ?? 'App';

                        final pkg =
                            app['packageName'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            settings.setTeslaAppSlot(
                              index,
                              pkg,
                            );

                            Navigator.pop(ctx, true);
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.03),
                                  borderRadius:
                                      BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white10,
                                  ),
                                ),
                                child: Center(
                                  child: _buildAppIcon(
                                    pkg,
                                    const Color(
                                      0xFF00E5FF,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        settings.setTeslaAppSlot(
                          index,
                          null,
                        );

                        Navigator.pop(ctx, true);
                      },
                      child: const Text(
                        'LIMPIAR ESPACIO',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    debugPrint(
      'Picker closed with result: $pickerResult',
    );

    _isPickerOpen = false;
  }

  Widget _buildCustomAppButton(
    BuildContext context,
    DashSettingsProvider settings,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _showCustomAppDialog(
        context,
        settings,
        index,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white24,
          ),
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_link_rounded,
              color: Colors.white54,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'PERSONALIZADA',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomAppDialog(
    BuildContext context,
    DashSettingsProvider settings,
    int index,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          title: const Text(
            'APP PERSONALIZADA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Introduce el nombre del paquete (package name) de la app que deseas agregar.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText:
                      'ej: com.google.android.youtube',
                  hintStyle: const TextStyle(
                    color: Colors.white12,
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.white38,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  settings.setTeslaAppSlot(
                    index,
                    controller.text.trim(),
                  );

                  Navigator.pop(ctx);

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF00E5FF),
              ),
              child: const Text(
                'GUARDAR',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardLightOverlay extends StatefulWidget {
  final Color color;
  final int design;
  final int rpm;

  const _DashboardLightOverlay({
    required this.color,
    required this.design,
    required this.rpm,
  });

  @override
  State<_DashboardLightOverlay> createState() =>
      _DashboardLightOverlayState();
}

class _DashboardLightOverlayState
    extends State<_DashboardLightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        double opacity = 0.25;

        if (widget.design == 2) {
          opacity =
              0.1 + (_controller.value * 0.3);
        } else if (widget.design == 3) {
          opacity =
              (widget.rpm / 8000).clamp(
            0.15,
            0.7,
          );
        }

        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(opacity),
                  widget.color.withOpacity(0.0),
                ],
                radius: 1.3,
                center: const Alignment(0, 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddGaugeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddGaugeItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E5FF)
                    .withOpacity(0.4),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00E5FF),
              size: 25,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _EditBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Colors.white.withOpacity(0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activeColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleConfigPanel extends StatefulWidget {
  final DashSettingsProvider settings;
  final String? editingGaugeId;
  final VoidCallback onClose;

  const _StyleConfigPanel({
    required this.settings,
    this.editingGaugeId,
    required this.onClose,
  });

  @override
  State<_StyleConfigPanel> createState() => _StyleConfigPanelState();
}

class _StyleConfigPanelState extends State<_StyleConfigPanel> {
  int _currentTab = 0; // 0: Estilo, 1: Personalizar

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13161D)
            .withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.editingGaugeId != null
                        ? Icons.tune_rounded
                        : Icons.palette_rounded,
                    color:
                        const Color(0xFF00E5FF),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.editingGaugeId != null
                        ? 'DISEÑO INDICADOR'
                        : 'EDITOR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white24,
                  size: 18,
                ),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.editingGaugeId == null)
            Row(
              children: [
                _TabButton(
                  label: 'LUCES',
                  isActive: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'PERSONALIZAR',
                  isActive: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1),
                ),
              ],
            ),
          const SizedBox(height: 24),
          if (widget.editingGaugeId == null) ...[
            if (_currentTab == 0) ...[
              const Text(
                'COLOR PRINCIPAL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _ColorPicker(
                selectedColor:
                    widget.settings.accentColor,
                onColorSelected: (c) =>
                    widget.settings.setAccentColor(c),
              ),
              const SizedBox(height: 20),
              const Text(
                'COLOR DE AGUJA / DETALLES',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _ColorPicker(
                selectedColor:
                    widget.settings.needleColor,
                onColorSelected: (c) =>
                    widget.settings.setNeedleColor(c),
              ),
              const SizedBox(height: 20),
              const Text(
                'COLOR DE FONDO',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _ColorPicker(
                selectedColor:
                    widget.settings.gaugeColor,
                onColorSelected: (c) =>
                    widget.settings.setGaugeColor(c),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 30),
              const Text(
                'DISEÑO DE ILUMINACIÓN',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _DesignOption(
                      label: 'SIN ILUMINACIÓN',
                      isActive:
                          widget.settings.lightDesign == 0,
                      onTap: () =>
                          widget.settings.setLightDesign(0),
                    ),
                    _DesignOption(
                      label: 'NEÓN ESTÁTICO',
                      isActive:
                          widget.settings.lightDesign == 1,
                      onTap: () =>
                          widget.settings.setLightDesign(1),
                    ),
                    _DesignOption(
                      label: 'RESPIRACIÓN',
                      isActive:
                          widget.settings.lightDesign == 2,
                      onTap: () =>
                          widget.settings.setLightDesign(2),
                    ),
                    _DesignOption(
                      label: 'DINÁMICO RPM',
                      isActive:
                          widget.settings.lightDesign == 3,
                      onTap: () =>
                          widget.settings.setLightDesign(3),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // TAB PERSONALIZAR
              const Text(
                'AÑADIR HUBS A TU ESTILO',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _HubAddItem(
                      label: 'VELOCIDAD',
                      icon: Icons.speed,
                      onTap: () => widget.settings.addCustomGauge('speed'),
                    ),
                    _HubAddItem(
                      label: 'RPM',
                      icon: Icons.track_changes,
                      onTap: () => widget.settings.addCustomGauge('rpm'),
                    ),
                    _HubAddItem(
                      label: 'TEMPERATURA',
                      icon: Icons.thermostat,
                      onTap: () => widget.settings.addCustomGauge('temp'),
                    ),
                    _HubAddItem(
                      label: 'VOLTAJE',
                      icon: Icons.bolt,
                      onTap: () => widget.settings.addCustomGauge('volt'),
                    ),
                    _HubAddItem(
                      label: 'MÚSICA',
                      icon: Icons.music_note_rounded,
                      onTap: () => widget.settings.addCustomGauge('music_hub'),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // MODO EDICIÓN DE INDICADOR ESPECÍFICO
            _GaugeEditor(
              settings: widget.settings,
              gaugeId: widget.editingGaugeId!,
              onDelete: widget.onClose,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00E5FF).withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? const Color(0xFF00E5FF) : Colors.white10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubAddItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HubAddItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBoxCompact extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionBoxCompact({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugeEditor extends StatelessWidget {
  final DashSettingsProvider settings;
  final String gaugeId;
  final VoidCallback onDelete;

  const _GaugeEditor({required this.settings, required this.gaugeId, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final gauge = settings.customGauges.firstWhere((g) => g.id == gaugeId);

    return Expanded(
      child: ListView(
        children: [
          const Text(
            'DISEÑO VISUAL',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _DesignOption(
            label: 'POR DEFECTO',
            isActive: gauge.design == 0,
            onTap: () => settings.updateGaugeDesign(gaugeId, 0),
          ),
          _DesignOption(
            label: 'ESTILO MODERN',
            isActive: gauge.design == 1,
            onTap: () => settings.updateGaugeDesign(gaugeId, 1),
          ),
          _DesignOption(
            label: 'MINIMALISTA',
            isActive: gauge.design == 2,
            onTap: () => settings.updateGaugeDesign(gaugeId, 2),
          ),
          
          const SizedBox(height: 20),
          const Text(
            'PERSONALIZAR LOGO / IMAGEN',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionBoxCompact(
                label: 'CAMBIAR LOGO',
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    settings.updateGaugeCustomization(gaugeId, logoPath: image.path);
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionBoxCompact(
                label: 'LIMPIAR',
                onTap: () => settings.updateGaugeCustomization(gaugeId, logoPath: ''),
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              settings.removeCustomGauge(gaugeId);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'ELIMINAR INDICADOR',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF00E5FF),
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.white,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final bool isSelected =
            selectedColor.value == c.value;

        return GestureDetector(
          onTap: () => onColorSelected(c),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color:
                        c.withOpacity(0.5),
                    blurRadius: 10,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DesignOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DesignOption({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00E5FF)
                  .withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF00E5FF)
                : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}