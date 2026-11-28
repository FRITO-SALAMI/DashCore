import '../widget/compatible_vehicle_model.dart';
import 'dart:async';
import '../widget/brightness_settings.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import '../providers/obd_provider.dart';
import '../utils/app_localizations.dart';
import '../widget/tutorial/tutorial_keys.dart';
import '../services/alert_sound_service.dart';
import '../services/manual_vehicle_service.dart';
import '../widget/workshop_diagnostics_panel.dart';
import '../widget/vehicle_top_view.dart';
import '../core/app_colors.dart';

class WorkshopScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WorkshopScreen({super.key, required this.onBack});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  bool _processingRearPhoto = false;

  Future<void> _addRearPhoto(DashSettingsProvider settings) async {
    final vehicle = settings.selectedVehicle;
    if (_processingRearPhoto || vehicle == null || !vehicle.isCustom) return;
    setState(() => _processingRearPhoto = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1024, imageQuality: 85,
      );
      if (file == null || !mounted || settings.selectedVehicle?.id != vehicle.id) return;
      final updated = await ManualVehicleService.attachPhoto(vehicle, File(file.path), rear: true, cutout: true);
      if (!mounted || settings.selectedVehicle?.id != vehicle.id) return;
      await settings.registerManualVehicle(updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        updated.rearArtworkPath?.endsWith('cutout_rear.png') == true
          ? 'Foto trasera aplicada al vehículo.' : 'Foto trasera guardada con su fondo.',
      )));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la foto trasera.')),
      );
    } finally {
      if (mounted) setState(() => _processingRearPhoto = false);
    }
  }

  Future<void> _openDiagnostics() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.cardBg,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: const WorkshopDiagnosticsPanel(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = AppColors.accent;
    final isSpanish = loc.language == Language.spanish;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.translate('workshop').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  if (settings.selectedVehicle?.isCustom == true)
                    IconButton(
                      tooltip: 'Cambiar foto trasera',
                      onPressed: _processingRearPhoto ? null : () => _addRearPhoto(settings),
                      icon: const Icon(Icons.camera_rear_outlined),
                    ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: const Text('Diagnóstico'),
                    onPressed: _openDiagnostics,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white10),
                          ),
                        ),
                        if (settings.modelPath.isEmpty)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 82),
                              child: VehicleTopView(colorHex: settings.vehicleColorHex, vehicle: settings.selectedVehicle),
                            ),
                          )
                        else CompatibleVehicleModel(
                          key: ValueKey(settings.modelPath),
                          src: settings.modelPath,
                          preferLightPreview: false,
                          alt: 'Vehículo',
                          autoRotate: false,
                          cameraControls: true,
                          disableZoom: false,
                          backgroundColor: Colors.transparent,
                          cameraOrbit: '0deg 5deg 4.5m',
                          defaultZoom: 1,
                          loading: Loading.eager,
                          relatedJs: _getWorkshopScripts(
                            settings.vehicleColorHex,
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          child: Column(
                            children: [
                              Text(
                                settings.selectedVehicle?.name.toUpperCase() ??
                                    'SIN VEHÍCULO',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                settings.selectedVehicle?.brand.toUpperCase() ??
                                    '',
                                style: TextStyle(
                                  color: themeColor.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            isSpanish
                                ? 'VEHÍCULO Y TABLERO'
                                : 'VEHICLE AND DASHBOARD',
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 10, bottom: 18),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.amberAccent.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isSpanish
                                        ? 'AVISO: La personalización de carrocería sigue en desarrollo.'
                                        : 'NOTICE: Body customization is still in development.',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              bottom: 10,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isSpanish
                                      ? 'COLOR DE CARROCERÍA - EN DESARROLLO'
                                      : 'BODY COLOR - IN DEVELOPMENT',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isSpanish
                                      ? '(CAPA: CARROCERÍA)'
                                      : '(LAYER: BODY)',
                                  style: TextStyle(
                                    color: themeColor.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              bottom: 20,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                key: TutorialKeys.workshopColorKey,
                                children: [
                                  _ColorSwatch(
                                    color: '#FFFFFF',
                                    isSelected:
                                        settings.vehicleColorHex == '#FFFFFF',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#FF0000',
                                    isSelected:
                                        settings.vehicleColorHex == '#FF0000',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#00FF00',
                                    isSelected:
                                        settings.vehicleColorHex == '#00FF00',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#0000FF',
                                    isSelected:
                                        settings.vehicleColorHex == '#0000FF',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#FFFF00',
                                    isSelected:
                                        settings.vehicleColorHex == '#FFFF00',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#FF00FF',
                                    isSelected:
                                        settings.vehicleColorHex == '#FF00FF',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#00FFFF',
                                    isSelected:
                                        settings.vehicleColorHex == '#00FFFF',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                  _ColorSwatch(
                                    color: '#333333',
                                    isSelected:
                                        settings.vehicleColorHex == '#333333',
                                    onSelect: (value) {
                                      settings.setVehicleColor(value);
                                      if (settings.isTutorialActive &&
                                          settings.tutorialStep == 10) {
                                        settings.setTutorialStep(11);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          _WorkshopToggleTile(
                            icon: Icons.local_gas_station_rounded,
                            label: loc.translate('fuel_gauge'),
                            value: settings.showFuelGauge
                                ? (isSpanish ? 'ACTIVADO' : 'ON')
                                : (isSpanish ? 'DESACTIVADO' : 'OFF'),
                            isActive: settings.showFuelGauge,
                            onTap: () => settings.toggleShowFuelGauge(
                              !settings.showFuelGauge,
                            ),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.thermostat_rounded,
                            label: loc.translate('temp_warning'),
                            value: '${settings.tempAlertThreshold.round()}°C',
                            onTap: () => _showSliderDialog(
                              context,
                              loc.translate('temp_warning'),
                              settings.tempAlertThreshold,
                              80,
                              130,
                              '°C',
                              (v) => settings.setTempAlertThreshold(v),
                            ),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.speed_rounded,
                            label: loc.translate('speed_warning'),
                            value:
                                '${settings.displaySpeedAlertThreshold.round()} ${settings.speedUnitLabel}',
                            onTap: () => _showSliderDialog(
                              context,
                              loc.translate('speed_warning'),
                              settings.displaySpeedAlertThreshold,
                              settings.displaySpeed(60),
                              settings.displaySpeed(220),
                              ' ${settings.speedUnitLabel}',
                              (v) => settings.setSpeedAlertThreshold(
                                settings.speedToKmh(v),
                              ),
                            ),
                          ),

                          _WorkshopToggleTile(
                            icon: Icons.notifications_active_rounded,
                            label: isSpanish
                                ? 'SONIDOS DE ALERTA'
                                : 'ALERT SOUNDS',
                            value: settings.selectedAlertSoundPath == null
                                ? (isSpanish
                                      ? 'DESCARGAR / ELEGIR'
                                      : 'DOWNLOAD / CHOOSE')
                                : settings.alertSoundLabel(
                                    settings.selectedAlertSoundPath!,
                                  ),
                            onTap: () =>
                                _showAlertSoundSelection(context, settings),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.gas_meter_rounded,
                            label: loc.translate('fuel_simulator'),
                            value: settings.useSimulatedFuel
                                ? '${settings.simulatedFuelLevel.round()}%'
                                : (isSpanish ? 'REAL (OBD2)' : 'REAL'),
                            onTap: () =>
                                _showFuelLevelSelection(context, settings),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader(isSpanish ? 'SISTEMA' : 'SYSTEM'),
                          _WorkshopToggleTile(
                            icon: Icons.schedule,
                            label: 'FORMATO DE HORA',
                            value: settings.use24HourFormat
                                ? '24 HORAS'
                                : '12 HORAS (AM/PM)',
                            onTap: () => settings.setUse24HourFormat(
                              !settings.use24HourFormat,
                            ),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.straighten,
                            label: 'UNIDADES',
                            value:
                                settings.distanceUnit == DistanceUnit.kilometers
                                ? 'KILÓMETROS · KM/H'
                                : 'MILLAS · MPH',
                            onTap: () => settings.setDistanceUnit(
                              settings.distanceUnit == DistanceUnit.kilometers
                                  ? DistanceUnit.miles
                                  : DistanceUnit.kilometers,
                            ),
                          ),
                          const BrightnessSettings(),
                          _WorkshopToggleTile(
                            icon: Icons.thermostat_outlined,
                            label: loc.translate('temp_unit'),
                            value: settings.tempUnit == TemperatureUnit.celsius
                                ? 'CELSIUS (°C)'
                                : 'FAHRENHEIT (°F)',
                            onTap: () => settings.setTempUnit(
                              settings.tempUnit == TemperatureUnit.celsius
                                  ? TemperatureUnit.fahrenheit
                                  : TemperatureUnit.celsius,
                            ),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.directions_car_rounded,
                            label: loc.translate('change_vehicle'),
                            value: isSpanish ? 'GARAJE' : 'GARAGE',
                            onTap: () =>
                                _showVehicleSelection(context, settings),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          _buildSectionHeader(
                            isSpanish ? 'RENDIMIENTO' : 'PERFORMANCE',
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.bolt_rounded,
                            label: isSpanish
                                ? 'MODO ULTRA DATOS (10Hz+)'
                                : 'ULTRA DATA MODE (10Hz+)',
                            value: settings.highPerformanceMode
                                ? (isSpanish ? 'ACTIVADO' : 'ON')
                                : (isSpanish ? 'DESACTIVADO' : 'OFF'),
                            isActive: settings.highPerformanceMode,
                            onTap: () {
                              final newVal = !settings.highPerformanceMode;
                              settings.toggleHighPerformanceMode(newVal);
                              context.read<ObdProvider>().setPerformanceMode(
                                newVal,
                              );
                            },
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.offline_bolt_rounded,
                            label: isSpanish
                                ? 'MODO HYPER-CONEXIÓN (Clone Stable)'
                                : 'HYPER-CONNECTION MODE (Clone Stable)',
                            value: settings.isCloneMode
                                ? (isSpanish ? 'ACTIVADO' : 'ON')
                                : (isSpanish ? 'DESACTIVADO' : 'OFF'),
                            isActive: settings.isCloneMode,
                            onTap: () {
                              final newVal = !settings.isCloneMode;
                              settings.toggleCloneMode(newVal);
                              context.read<ObdProvider>().setCloneMode(newVal);
                            },
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.speed_rounded,
                            label: isSpanish
                                ? 'MODO EXTREMO (Experimental)'
                                : 'EXTREME MODE (Experimental)',
                            value: settings.isAdvancedObdMode
                                ? (isSpanish ? 'ACTIVADO' : 'ON')
                                : (isSpanish ? 'DESACTIVADO' : 'OFF'),
                            isActive: settings.isAdvancedObdMode,
                            onTap: () {
                              final newVal = !settings.isAdvancedObdMode;
                              settings.toggleAdvancedObdMode(newVal);
                              context.read<ObdProvider>().setAdvancedMode(
                                newVal,
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWorkshopScripts(String hex) {
    final r = int.parse(hex.substring(1, 3), radix: 16) / 255.0;
    final g = int.parse(hex.substring(3, 5), radix: 16) / 255.0;
    final b = int.parse(hex.substring(5, 7), radix: 16) / 255.0;

    return '''
      const mv = document.querySelector('model-viewer');
      mv.addEventListener('load', () => {
        if (mv.model && mv.model.materials.length > 0) {
          mv.model.materials.forEach(m => {
            const name = m.name.toLowerCase();
            // Estandarización: 'carroceria' (minúsculas) y 'Carroceria' (Starex) se detectan aquí.
            // Se excluyen explícitamente gomas, cristales y el material 'Resto' del Starex.
            const isBody = (name === 'carroceria' || name === 'carrocería') ||
                           (name.includes('paint') && !name.includes('glass') && !name.includes('interior')) ||
                           (name.includes('exterior') && !name.includes('glass')) ||
                           (name === 'body') ||
                           (name.includes('material') && !name.includes('glass') && !name.includes('tire') && !name.includes('gomas') && !name.includes('resto'));

            if (isBody) {
              m.pbrMetallicRoughness.setBaseColorFactor([$r, $g, $b, 1]);
            }
          });
        }
      });
    ''';
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 15, top: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    ),
  );

  void _showSliderDialog(
    BuildContext context,
    String title,
    double current,
    double min,
    double max,
    String suffix,
    Function(double) onSave,
  ) {
    double tempVal = current.clamp(min, max);
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tempVal.round()}$suffix',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Slider(
                value: tempVal,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                activeColor: const Color(0xFF00E5FF),
                onChanged: (v) => setModalState(() => tempVal = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(tempVal);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                loc.translate('save'),
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

  Future<void> _showAlertSoundSelection(
    BuildContext context,
    DashSettingsProvider settings,
  ) async {
    if (settings.alertSoundPaths.isEmpty) {
      final download = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          title: const Text(
            'DESCARGAR SONIDOS',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Descarga el paquete de sonidos de alerta para poder elegir y probar uno.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DESCARGAR'),
            ),
          ],
        ),
      );
      if (download != true || !context.mounted) return;
      final ok = await settings.downloadAlertSounds();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Sonidos descargados'
                : 'No se pudo descargar el paquete de sonidos',
          ),
        ),
      );
      if (!ok) return;
    }

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          itemCount: settings.alertSoundPaths.length,
          separatorBuilder: (_, _) => const Divider(color: Colors.white10),
          itemBuilder: (_, index) {
            final path = settings.alertSoundPaths[index];
            final selected = path == settings.selectedAlertSoundPath;
            return ListTile(
              leading: Icon(
                Icons.volume_up_rounded,
                color: selected ? const Color(0xFF00E5FF) : Colors.white54,
              ),
              title: Text(
                'SONIDO ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF))
                  : null,
              onTap: () async {
                settings.selectAlertSound(path);
                await AlertSoundService.instance.preview(path);
              },
            );
          },
        ),
      ),
    );
  }

  void _showFuelLevelSelection(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    double tempVal = settings.simulatedFuelLevel.clamp(0.0, 100.0);
    final isSpanish = AppLocalizations.of(context).language == Language.spanish;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSpanish ? 'NIVEL DE COMBUSTIBLE' : 'FUEL LEVEL',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              Slider(
                value: tempVal,
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: const Color(0xFF00E5FF),
                onChanged: (v) => setModalState(() => tempVal = v),
              ),
              Text(
                '${tempVal.round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        settings.toggleUseSimulatedFuel(false);
                        Navigator.pop(ctx);
                      },
                      child: Text(isSpanish ? 'USAR REAL' : 'USE REAL'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        settings.setSimulatedFuelLevel(tempVal);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSpanish ? 'ESTABLECER' : 'SET',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleSelection(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    final isSpanish = AppLocalizations.of(context).language == Language.spanish;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 20),
            Text(
              isSpanish ? 'SELECCIONA TU VEHÍCULO' : 'SELECT YOUR VEHICLE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: settings.availableVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = settings.availableVehicles[index];
                  final isSelected = settings.selectedVehicle?.id == vehicle.id;
                  return ListTile(
                    leading: Icon(
                      Icons.directions_car,
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.white24,
                    ),
                    title: Text(
                      vehicle.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    onTap: () {
                      settings.selectVehicle(vehicle);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String color;
  final bool isSelected;
  final Function(String) onSelect;
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    final c = Color(int.parse(color.replaceFirst('#', 'FF'), radix: 16));
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10)]
              : null,
        ),
      ),
    );
  }
}

class _WorkshopToggleTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  final bool? isActive;
  const _WorkshopToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isActive,
  });
  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    final active =
        isActive ??
        (value == 'ACTIVADO' ||
            value == 'ON' ||
            value.contains('GPS') ||
            value.contains('OBD2'));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? themeColor.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: active ? themeColor : Colors.white24,
          size: 20,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white12,
          size: 14,
        ),
      ),
    );
  }
}
