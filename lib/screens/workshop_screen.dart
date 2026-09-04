import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../providers/dash_settings_provider.dart';
import '../providers/obd_provider.dart';
import '../utils/app_localizations.dart';
import '../widget/tutorial/tutorial_keys.dart';

class WorkshopScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WorkshopScreen({super.key, required this.onBack});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  Future<void> _logMaterials() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CONSULTA DE MATERIALES INICIADA...'), duration: Duration(seconds: 2))
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = Color(0xFF00E5FF);
    final isSpanish = loc.language == Language.spanish;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.translate('workshop').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bug_report_rounded, color: Colors.white24),
                    onPressed: _logMaterials,
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
                        ),
                        ModelViewer(
                          key: ValueKey('${settings.modelPath}_${settings.vehicleColorHex}'),
                          src: settings.modelPath,
                          alt: 'Vehículo',
                          autoRotate: true,
                          cameraControls: true,
                          disableZoom: false,
                          backgroundColor: Colors.transparent,
                          cameraOrbit: '45deg 75deg 5m',
                          loading: Loading.eager,
                          relatedJs: _getWorkshopScripts(settings.vehicleColorHex),
                        ),
                        Positioned(
                          bottom: 40,
                          child: Column(
                            children: [
                              Text(settings.selectedVehicle?.name.toUpperCase() ?? 'SIN VEHÍCULO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                              Text(settings.selectedVehicle?.brand.toUpperCase() ?? '', style: TextStyle(color: themeColor.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
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
                          _buildSectionHeader(isSpanish ? 'PERSONALIZACIÓN - EN DESARROLLO' : 'CUSTOMIZATION - IN DEVELOPMENT'),
                          Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 8),
                            child: Text(
                              isSpanish
                                ? 'ESTAMOS TRABAJANDO PARA QUE NO CAMBIE COMPLETAMENTE EL COLOR.'
                                : 'WE ARE WORKING SO THE COLOR DOESN\'T CHANGE COMPLETELY.',
                              style: TextStyle(color: themeColor.withOpacity(1.0), fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 10),
                            child: Row(
                              children: [
                                Text(isSpanish ? 'COLOR DE CARROCERÍA - EN DESARROLLO' : 'BODY COLOR - IN DEVELOPMENT', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                const SizedBox(width: 10),
                                Text(isSpanish ? '(CAPA: CARROCERÍA)' : '(LAYER: BODY)', style: TextStyle(color: themeColor.withOpacity(0.5), fontSize: 12)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                key: TutorialKeys.workshopColorKey,
                                children: [
                                  _ColorSwatch(color: '#FFFFFF', isSelected: settings.vehicleColorHex == '#FFFFFF', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#FF0000', isSelected: settings.vehicleColorHex == '#FF0000', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#00FF00', isSelected: settings.vehicleColorHex == '#00FF00', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#0000FF', isSelected: settings.vehicleColorHex == '#0000FF', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#FFFF00', isSelected: settings.vehicleColorHex == '#FFFF00', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#FF00FF', isSelected: settings.vehicleColorHex == '#FF00FF', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#00FFFF', isSelected: settings.vehicleColorHex == '#00FFFF', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                  _ColorSwatch(color: '#333333', isSelected: settings.vehicleColorHex == '#333333', onSelect: (value) { settings.setVehicleColor(value); if (settings.isTutorialActive && settings.tutorialStep == 10) settings.setTutorialStep(11); }),
                                ],
                              ),
                            ),
                          ),

                          _WorkshopToggleTile(
                            icon: Icons.local_gas_station_rounded,
                            label: loc.translate('fuel_gauge'),
                            value: settings.showFuelGauge ? (isSpanish ? 'ACTIVADO' : 'ON') : (isSpanish ? 'DESACTIVADO' : 'OFF'),
                            isActive: settings.showFuelGauge,
                            onTap: () => settings.toggleShowFuelGauge(!settings.showFuelGauge),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.thermostat_rounded,
                            label: loc.translate('temp_warning'),
                            value: '${settings.tempAlertThreshold.round()}°C',
                            onTap: () => _showSliderDialog(context, loc.translate('temp_warning'), settings.tempAlertThreshold, 80, 130, '°C', (v) => settings.setTempAlertThreshold(v)),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.speed_rounded,
                            label: loc.translate('speed_warning'),
                            value: '${settings.speedAlertThreshold.round()} KM/H',
                            onTap: () => _showSliderDialog(context, loc.translate('speed_warning'), settings.speedAlertThreshold, 60, 220, ' KM/H', (v) => settings.setSpeedAlertThreshold(v)),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.gas_meter_rounded,
                            label: loc.translate('fuel_simulator'),
                            value: settings.useSimulatedFuel ? '${settings.simulatedFuelLevel.round()}%' : (isSpanish ? 'REAL (OBD2)' : 'REAL'),
                            onTap: () => _showFuelLevelSelection(context, settings),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader(isSpanish ? 'SISTEMA' : 'SYSTEM'),
                          _WorkshopToggleTile(
                            icon: Icons.thermostat_outlined,
                            label: loc.translate('temp_unit'),
                            value: settings.tempUnit == TemperatureUnit.celsius ? 'CELSIUS (°C)' : 'FAHRENHEIT (°F)',
                            onTap: () => settings.setTempUnit(settings.tempUnit == TemperatureUnit.celsius ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius),
                          ),
                          _WorkshopToggleTile(
                            icon: Icons.directions_car_rounded,
                            label: loc.translate('change_vehicle'),
                            value: isSpanish ? 'GARAJE' : 'GARAGE',
                            onTap: () => _showVehicleSelection(context, settings),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          _buildSectionHeader(isSpanish ? 'RENDIMIENTO' : 'PERFORMANCE'),
                          _WorkshopToggleTile(
                            icon: Icons.bolt_rounded,
                            label: isSpanish ? 'MODO ULTRA DATOS (10Hz+)' : 'ULTRA DATA MODE (10Hz+)',
                            value: settings.highPerformanceMode ? (isSpanish ? 'ACTIVADO' : 'ON') : (isSpanish ? 'DESACTIVADO' : 'OFF'),
                            isActive: settings.highPerformanceMode,
                            onTap: () => settings.toggleHighPerformanceMode(!settings.highPerformanceMode),
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

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(left: 10, bottom: 15, top: 10), child: Text(title, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)));

  void _showSliderDialog(BuildContext context, String title, double current, double min, double max, String suffix, Function(double) onSave) {
    double tempVal = current.clamp(min, max);
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tempVal.round()}$suffix', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 24, fontWeight: FontWeight.bold)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('cancel'))),
            ElevatedButton(
              onPressed: () {
                onSave(tempVal);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(loc.translate('save'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelLevelSelection(BuildContext context, DashSettingsProvider settings) {
    double tempVal = settings.simulatedFuelLevel.clamp(0.0, 100.0);
    final isSpanish = AppLocalizations.of(context).language == Language.spanish;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isSpanish ? 'NIVEL DE COMBUSTIBLE' : 'FUEL LEVEL', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 40),
              Slider(
                value: tempVal,
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: const Color(0xFF00E5FF),
                onChanged: (v) => setModalState(() => tempVal = v),
              ),
              Text('${tempVal.round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(isSpanish ? 'ESTABLECER' : 'SET', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  void _showVehicleSelection(BuildContext context, DashSettingsProvider settings) {
    final isSpanish = AppLocalizations.of(context).language == Language.spanish;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF12151C), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => DraggableScrollableSheet(initialChildSize: 0.6, expand: false, builder: (context, scrollController) => Column(children: [const SizedBox(height: 20), Text(isSpanish ? 'SELECCIONA TU VEHÍCULO' : 'SELECT YOUR VEHICLE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 20), Expanded(child: ListView.builder(controller: scrollController, itemCount: settings.availableVehicles.length, itemBuilder: (context, index) { final vehicle = settings.availableVehicles[index]; final isSelected = settings.selectedVehicle?.id == vehicle.id; return ListTile(leading: Icon(Icons.directions_car, color: isSelected ? const Color(0xFF00E5FF) : Colors.white24), title: Text(vehicle.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)), onTap: () { settings.selectVehicle(vehicle); Navigator.pop(ctx); }); }))])));
  }
}

class _ColorSwatch extends StatelessWidget {
  final String color; final bool isSelected; final Function(String) onSelect;
  const _ColorSwatch({required this.color, required this.isSelected, required this.onSelect});
  @override Widget build(BuildContext context) { final c = Color(int.parse(color.replaceFirst('#', 'FF'), radix: 16)); return GestureDetector(onTap: () => onSelect(color), child: Container(width: 40, height: 40, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.white24, width: isSelected ? 3 : 1), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : null))); }
}

class _WorkshopToggleTile extends StatelessWidget {
  final IconData icon; final String label, value; final VoidCallback onTap; final bool? isActive;
  const _WorkshopToggleTile({required this.icon, required this.label, required this.value, required this.onTap, this.isActive});
  @override Widget build(BuildContext context) { const themeColor = Color(0xFF00E5FF); final active = isActive ?? (value == 'ACTIVADO' || value == 'ON' || value.contains('GPS') || value.contains('OBD2')); return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? themeColor.withOpacity(0.2) : Colors.transparent)), child: ListTile(onTap: onTap, leading: Icon(icon, color: active ? themeColor : Colors.white24, size: 20), title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14))); }
}
