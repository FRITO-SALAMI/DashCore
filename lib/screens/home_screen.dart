import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/obd_provider.dart';
import '../providers/dash_settings_provider.dart';
import '../providers/music_provider.dart';
import '../models/obd_data.dart';
import '../widget/tutorial/tutorial_keys.dart';
import '../widget/gauges/sporty_dashboard.dart';
import '../widget/gauges/racing_dashboard.dart';
import '../widget/gauges/modern_dashboard.dart';
import '../widget/gauges/vehicle_3d_dashboard.dart';
import '../widget/gauges/custom_gauge_widget.dart';
import '../widget/gauges/ev_cluster_dashboard.dart';
import '../widget/gauges/premium_dashboard.dart';
import '../widget/gauges/racing_hud_dashboard.dart';
import '../widget/gauges/glow_red_dashboard.dart';
import '../widget/gauges/hellish_red_dashboard.dart';
import '../widget/gauges/retro_lcd_dashboard.dart';
import 'dashboard/themes/tesla_style_theme_screen.dart';
import 'dashboard/themes/classic_sport_theme_screen.dart';
import 'dashboard/themes/race_cluster_theme_screen.dart';
import 'dashboard/themes/modern_tesla_themes.dart';
import '../widget/gauges/purple_maps_dashboard.dart';
import '../widget/gauges/neon_world_dashboard.dart';
import '../widget/gauges/dashcore_dashboard.dart';
import '../utils/app_localizations.dart';
import '../widget/dashboard_background.dart';
import '../painters/rpm_gauge_painter.dart';
import '../painters/speed_ring_gauge_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<String>? _errorSubscription;
  bool _showStyleConfig = false;
  String? _editingGaugeId;
  VoidCallback? _settingsListener;
  ObdProvider? _obdProvider;
  ObdData _renderedData = const ObdData();
  Timer? _telemetryFrameTimer;
  bool _isShowingDownloadDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashSettings = context.read<DashSettingsProvider>();
      context.read<MusicProvider>().requestPermissions();
      _settingsListener = () {
        if (mounted) _checkResources(dashSettings);
      };
      dashSettings.addListener(_settingsListener!);
      _checkResources(dashSettings);
      _errorSubscription = context.read<ObdProvider>().errorEvents.listen((
        msg,
      ) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
          );
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ObdProvider>();
    if (!identical(provider, _obdProvider)) {
      _obdProvider?.removeListener(_onTelemetryChanged);
      _obdProvider = provider;
      _renderedData = provider.data;
      provider.addListener(_onTelemetryChanged);
    }
  }

  void _onTelemetryChanged() {
    if (!mounted || _telemetryFrameTimer != null) return;
    final settings = context.read<DashSettingsProvider>();
    if (!settings.isAppActive) return;
    final frameDelay = Duration(
      milliseconds: (1000 / settings.telemetryFramesPerSecond).round(),
    );
    _telemetryFrameTimer = Timer(frameDelay, () {
      _telemetryFrameTimer = null;
      if (!mounted || !context.read<DashSettingsProvider>().isAppActive) return;
      final latest = _obdProvider?.data;
      if (latest != null) setState(() => _renderedData = latest);
    });
  }

  void _checkResources(DashSettingsProvider settings) {
    if (_isShowingDownloadDialog) return;

    if (settings.selectedVehicle != null &&
        !settings.selectedVehicle!.isDownloaded &&
        settings.selectedVehicle!.modelUrl != null) {
      _showDownloadDialog(context, settings);
    }
  }

  void _showDownloadDialog(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    _isShowingDownloadDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer<DashSettingsProvider>(
        builder: (context, provider, _) => AlertDialog(
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
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (provider.isDownloadingResources) ...[
                LinearProgressIndicator(
                  value: provider.downloadProgress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
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
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
          actions: [
            if (!provider.isDownloadingResources)
              TextButton(
                onPressed: () {
                  _isShowingDownloadDialog = false;
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'MÁS TARDE',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ElevatedButton(
              onPressed: provider.isDownloadingResources
                  ? null
                  : () async {
                      if (await provider.downloadVehicleResources() &&
                          mounted) {
                        _isShowingDownloadDialog = false;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recursos descargados correctamente'),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _telemetryFrameTimer?.cancel();
    _obdProvider?.removeListener(_onTelemetryChanged);
    _errorSubscription?.cancel();
    if (_settingsListener != null)
      try {
        context.read<DashSettingsProvider>().removeListener(_settingsListener!);
      } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final isGif = settings.backgroundImage?.endsWith('.gif') ?? false;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      key: TutorialKeys.dashboardKey,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: TickerMode(
                enabled: settings.isAppActive,
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildSelectedDashboard(settings, _renderedData),
                  ),
                ),
              ),
            ),
            if (settings.lightDesign != 0 &&
                !isGif &&
                settings.selectedStyle != DashboardStyle.sketch)
              Positioned.fill(
                child: RepaintBoundary(
                  child: _DashboardLightOverlay(
                    color: settings.lightColor,
                    design: settings.lightDesign,
                    rpm: _renderedData.rpm,
                  ),
                ),
              ),

            ...settings.customGauges.map((config) {
              final isEditing = _editingGaugeId == config.id;
              return Positioned(
                left: config.position.dx,
                top: config.position.dy,
                child: RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: settings.isEditMode
                            ? () => setState(() {
                                _editingGaugeId = config.id;
                                _showStyleConfig = true;
                              })
                            : null,
                        onPanUpdate: settings.isEditMode
                            ? (d) => settings.updateGaugePosition(
                                config.id,
                                config.position + d.delta,
                              )
                            : null,
                        onLongPress: settings.isEditMode
                            ? () {
                                settings.removeCustomGauge(config.id);
                                if (_editingGaugeId == config.id)
                                  setState(() => _editingGaugeId = null);
                              }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            border: isEditing
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: CustomGaugeWidget(
                            type: config.type,
                            value: _getGaugeValue(config.type, _renderedData),
                            unit: _getGaugeUnit(config.type),
                            color: settings.accentColor,
                            size: config.size,
                            design: config.design,
                            logoPath: config.logoPath,
                          ),
                        ),
                      ),
                      if (settings.isEditMode && isEditing)
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (d) => settings.updateGaugeSize(
                              config.id,
                              Size(
                                (config.size.width + d.delta.dx).clamp(
                                  80.0,
                                  600.0,
                                ),
                                (config.size.height + d.delta.dy).clamp(
                                  40.0,
                                  400.0,
                                ),
                              ),
                            ),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E5FF),
                                    shape: BoxShape.circle,
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
                ),
              );
            }),

            if (settings.isEditMode)
              Positioned(
                top: 20,
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
                          onTap: () => _showAddGaugeMenu(context, settings),
                        ),
                        _EditBarButton(
                          icon: Icons.refresh_rounded,
                          label: settings.sketchExists ? 'REINICIAR' : 'NUEVO',
                          onTap: () => settings.createNewSketch(),
                        ),
                        _EditBarButton(
                          key: TutorialKeys.stylingButtonKey,
                          icon: Icons.palette_rounded,
                          label: 'STYLING',
                          onTap: () => setState(() {
                            _showStyleConfig = !_showStyleConfig;
                            if (!_showStyleConfig) _editingGaugeId = null;
                          }),
                        ),
                        const VerticalDivider(
                          color: Colors.white10,
                          indent: 20,
                          endIndent: 20,
                        ),
                        _EditBarButton(
                          icon: Icons.check_circle_rounded,
                          label: 'LISTO',
                          color: const Color(0xFF00E5FF),
                          onTap: () {
                            if (settings.selectedStyle == DashboardStyle.sketch)
                              settings.saveAsMyStyle();
                            settings.toggleEditMode();
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

            if (_showStyleConfig && settings.isEditMode)
              Positioned(
                left: 20,
                top: 100,
                bottom: 20,
                width: 280,
                child: _StyleConfigPanel(
                  settings: settings,
                  editingGaugeId: _editingGaugeId,
                  onClose: () => setState(() => _showStyleConfig = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddGaugeMenu(BuildContext context, DashSettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
      ),
    );
  }

  dynamic _getGaugeValue(String type, dynamic data) {
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
  ) {
    final loc = AppLocalizations.of(context);
    final unit = settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F';
    final temp = settings.convertTemp(obdData.engineTemp).round();
    final fuel = settings.useSimulatedFuel
        ? settings.simulatedFuelLevel.round()
        : obdData.fuelLevel.round();
    switch (settings.selectedStyle) {
      case DashboardStyle.sporty:
        return SportyDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          needleColor: settings.needleColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: unit,
        );
      case DashboardStyle.racing:
        return RacingDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          needleColor: settings.needleColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: unit,
        );
      case DashboardStyle.modern:
        return ModernDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          needleColor: settings.needleColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: unit,
        );
      case DashboardStyle.vehicle3D:
        return Vehicle3DDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: unit,
          modelPath: settings.modelPath,
        );
      case DashboardStyle.purpleMaps:
        return PurpleMapsDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
        );
      case DashboardStyle.neonWorld:
        return NeonWorldDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
        );
      case DashboardStyle.dashcore:
        return DashcoreDashboard(data: obdData);
      case DashboardStyle.racingHud:
        return const RacingHudDashboard();
      case DashboardStyle.glowRed:
        return GlowRedDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
          tempUnit: unit,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
        );
      case DashboardStyle.hellishRed:
        return HellishRedDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: temp,
          voltage: obdData.voltage,
          tempUnit: unit,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
        );
      case DashboardStyle.teslaStyle:
        return TeslaStyleThemeScreen(
          data: obdData,
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
          fuelLevel: fuel.toDouble(),
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          appSlotBuilder: (context, index) {
            final pkg = settings.teslaAppSlots[index];
            if (pkg == null || pkg.isEmpty)
              return Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: settings.accentColor.withOpacity(0.3),
                  size: 30,
                ),
              );
            return Center(child: _buildAppIcon(pkg, settings.accentColor));
          },
          onAppTap: (index) {
            final pkg = settings.teslaAppSlots[index];
            if (settings.isEditMode)
              _showTeslaAppPicker(context, settings, index);
            else if (pkg != null && pkg.isNotEmpty)
              _launchApp(pkg);
            else
              _showTeslaAppPicker(context, settings, index);
          },
        );
      case DashboardStyle.classicSport:
        return ClassicSportThemeScreen(
          data: obdData,
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
          fuelLevel: fuel.toDouble(),
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
            coolantPercent: (obdData.engineTemp / 120).clamp(0.0, 1.0),
            fuelLevel: fuel.toDouble(),
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
            batteryPercent: fuel.toDouble(),
            coolantTemp: temp.toDouble(),
            voltage: obdData.voltage.toDouble(),
            gear: obdData.gear,
          ),
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
        );
      case DashboardStyle.teslaRoad:
        return ModernTeslaRoadTheme(
          data: obdData,
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
        );
      case DashboardStyle.teslaModel:
        return ModernTeslaModelTheme(
          data: obdData,
          modelPath: settings.modelPath,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
        );
      case DashboardStyle.dashcorevideo:
        return PremiumDashboard(data: obdData, fuelLevel: fuel.toDouble());
      case DashboardStyle.gifSpeedo:
        return Stack(
          alignment: Alignment.center,
          children: [
            if (settings.backgroundImage != null)
              DashboardBackground(
                backgroundImage: settings.backgroundImage,
                isAssetBackground: settings.isAssetBackground,
                opacity: 1.0,
              ),
            Container(
              color: Colors.black.withOpacity(0.3),
            ), // Darken GIF slightly for better visibility
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${obdData.speed}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Text(
                  'KM/H',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
            // Readable Temp and Volt gauges in the corner
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$temp',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.thermostat_rounded,
                          color: Color(0xFF00E5FF),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          obdData.voltage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'V',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.bolt_rounded,
                          color: Colors.orangeAccent,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                settings.selectedStyle == DashboardStyle.myStyle
                    ? 'MI ESTILO'
                    : loc.translate('new_sketch'),
                style: const TextStyle(
                  color: Colors.white10,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAppIcon(String pkg, Color color) {
    IconData icon = Icons.apps_rounded;
    final p = pkg.toLowerCase();
    if (p.contains('maps'))
      icon = Icons.map_rounded;
    else if (p.contains('spotify') || p.contains('music'))
      icon = Icons.music_note_rounded;
    else if (p.contains('youtube'))
      icon = Icons.video_library_rounded;
    else if (p.contains('chrome'))
      icon = Icons.public_rounded;
    return Icon(icon, color: color, size: 40);
  }

  Future<void> _launchApp(String packageName) async {
    const platform = MethodChannel('io.dashcore.app/launcher');
    try {
      await platform.invokeMethod('launchApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: \${e.message}')));
    }
  }

  Future<void> _showTeslaAppPicker(
    BuildContext context,
    DashSettingsProvider settings,
    int index,
  ) async {
    const platform = MethodChannel('io.dashcore.app/launcher');
    List<Map<String, String>> apps = [];
    try {
      final List<dynamic>? res = await platform.invokeMethod(
        'getInstalledApps',
      );
      if (res != null)
        apps = res.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (e) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACCESO DIRECTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, i) {
                    final app = apps[i];
                    return GestureDetector(
                      onTap: () {
                        settings.setTeslaAppSlot(index, app['packageName']);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Center(
                              child: _buildAppIcon(
                                app['packageName'] ?? '',
                                const Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app['name'] ?? 'App',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                    settings.setTeslaAppSlot(index, null);
                    Navigator.pop(ctx);
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
        ),
      ),
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
  State<_DashboardLightOverlay> createState() => _DashboardLightOverlayState();
}

class _DashboardLightOverlayState extends State<_DashboardLightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        double op = 0.25;
        if (widget.design == 2)
          op = 0.1 + (_c.value * 0.3);
        else if (widget.design == 3)
          op = (widget.rpm / 8000).clamp(0.15, 0.7);
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(op),
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

class _EditBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _EditBarButton({
    super.key,
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
  int _currentTab = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13161D).withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.editingGaugeId != null
                        ? Icons.tune_rounded
                        : Icons.palette_rounded,
                    color: const Color(0xFF00E5FF),
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
                icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        key: TutorialKeys.stylingColorPickerKey,
                        selectedColor: widget.settings.accentColor,
                        onColorSelected: (c) {
                          widget.settings.setAccentColor(c);
                          if (widget.settings.isTutorialActive &&
                              widget.settings.tutorialStep == 8)
                            widget.settings.setTutorialStep(9);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'COLOR DE AGUJA',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ColorPicker(
                        selectedColor: widget.settings.needleColor,
                        onColorSelected: (c) =>
                            widget.settings.setNeedleColor(c),
                      ),
                      const SizedBox(height: 20),
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
                      ...[
                        _DesignOption(
                          label: 'SIN ILUMINACIÓN',
                          isActive: widget.settings.lightDesign == 0,
                          onTap: () => widget.settings.setLightDesign(0),
                        ),
                        _DesignOption(
                          label: 'NEÓN ESTÁTICO',
                          isActive: widget.settings.lightDesign == 1,
                          onTap: () => widget.settings.setLightDesign(1),
                        ),
                        _DesignOption(
                          label: 'RESPIRACIÓN',
                          isActive: widget.settings.lightDesign == 2,
                          onTap: () => widget.settings.setLightDesign(2),
                        ),
                        _DesignOption(
                          label: 'DINÁMICO RPM',
                          isActive: widget.settings.lightDesign == 3,
                          onTap: () => widget.settings.setLightDesign(3),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'AÑADIR HUBS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.5,
                        children: [
                          _HubAddItem(
                            label: 'VELOCIDAD',
                            icon: Icons.speed,
                            onTap: () =>
                                widget.settings.addCustomGauge('speed'),
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
                            onTap: () =>
                                widget.settings.addCustomGauge('music_hub'),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    _GaugeEditor(
                      settings: widget.settings,
                      gaugeId: widget.editingGaugeId!,
                      onDelete: widget.onClose,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00E5FF).withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF00E5FF) : Colors.white10,
          ),
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

class _HubAddItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HubAddItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF00E5FF).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF00E5FF) : Colors.white10,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    ),
  );
}

class _ColorPicker extends StatefulWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  const _ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  bool _showExtended = false;

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
    final extended = [
      Colors.blue,
      Colors.teal,
      Colors.amber,
      Colors.deepPurple,
      Colors.lime,
      Colors.indigo,
      Colors.blueGrey,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...colors.map((c) => _colorDot(c)),
            GestureDetector(
              onTap: () => setState(() => _showExtended = !_showExtended),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _showExtended ? Colors.white : Colors.white10,
                  ),
                ),
                child: Icon(
                  _showExtended ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        if (_showExtended) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: extended.map((c) => _colorDot(c, small: true)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _colorDot(Color c, {bool small = false}) {
    final bool isSelected = widget.selectedColor.value == c.value;
    final size = small ? 28.0 : 34.0;
    return GestureDetector(
      onTap: () => widget.onColorSelected(c),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: c.withOpacity(0.5), blurRadius: 10),
          ],
        ),
      ),
    );
  }
}

class _GaugeEditor extends StatelessWidget {
  final DashSettingsProvider settings;
  final String gaugeId;
  final VoidCallback onDelete;
  const _GaugeEditor({
    required this.settings,
    required this.gaugeId,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final gauge = settings.customGauges.firstWhere((g) => g.id == gaugeId);
    return Expanded(
      child: ListView(
        children: [
          const Text(
            'DISEÑO VISUAL',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
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
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              settings.removeCustomGauge(gaugeId);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ELIMINAR INDICADOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                ),
              ),
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 25),
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
      ),
    ),
  );
}
