import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../models/gadget_config.dart';
import '../editable_gadget_wrapper.dart';
import '../../painters/rpm_gauge_painter.dart';
import '../../painters/speed_ring_gauge_painter.dart';
import '../../providers/dash_settings_provider.dart';
import '../../providers/music_provider.dart';
import '../rpm_warning_animation.dart';
import '../dashboard_background.dart';
import '../music_hub.dart';

import '../../models/obd_data.dart';

class DashcoreDashboard extends StatefulWidget {
  final ObdData data;

  const DashcoreDashboard({super.key, required this.data});
  @override State<DashcoreDashboard> createState() => _DashcoreDashboardState();
}

class _DashcoreDashboardState extends State<DashcoreDashboard> {
  late final Map<String, GadgetConfig> gadgets = {
    'rpm_gauge': GadgetConfig(id: 'rpm_gauge', label: 'RPM GAUGE', relativeX: 0.02, relativeY: 0.05, relativeWidth: 0.32, relativeHeight: 0.55),
    'speed_ring_gauge': GadgetConfig(id: 'speed_ring_gauge', label: 'SPEED RING', relativeX: 0.34, relativeY: 0.05, relativeWidth: 0.32, relativeHeight: 0.55),
    'vehicle_model': GadgetConfig(id: 'vehicle_model', label: 'VEHICLE', relativeX: 0.66, relativeY: 0.05, relativeWidth: 0.32, relativeHeight: 0.55),
    'media_player_bar': GadgetConfig(id: 'media_player_bar', label: 'MEDIA HUB', relativeX: 0.02, relativeY: 0.65, relativeWidth: 0.28, relativeHeight: 0.2), // Bottom Left
    'volt_temp_hub': GadgetConfig(id: 'volt_temp_hub', label: 'VOLT & TEMP', relativeX: 0.64, relativeY: 0.65, relativeWidth: 0.34, relativeHeight: 0.22),
    'sensors_bar': GadgetConfig(id: 'sensors_bar', label: 'SENSORS BAR', relativeX: 0.02, relativeY: 0.9, relativeWidth: 0.96, relativeHeight: 0.08),
  };

  void _updateGadget(GadgetConfig updated) => setState(() => gadgets[updated.id] = updated);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final music = context.read<MusicProvider>();
    final accentColor = settings.accentColor;

    return Container(
      color: const Color(0xFF020408),
      child: Stack(
        children: [
          DashboardBackground(backgroundImage: settings.backgroundImage, isAssetBackground: settings.isAssetBackground, opacity: 0.3),
          _buildTopBar(accentColor),
          Positioned.fill(
            top: 50,
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: gadgets.values.map((config) {
                  return Positioned(
                    left: config.relativeX * constraints.maxWidth, top: config.relativeY * constraints.maxHeight,
                    width: config.relativeWidth * constraints.maxWidth, height: config.relativeHeight * constraints.maxHeight,
                    child: EditableGadgetWrapper(
                      config: config, isEditMode: settings.isEditMode, onConfigChanged: _updateGadget,
                      onTapEdit: () => debugPrint('Edit \${config.label}'),
                      parentSize: Size(constraints.maxWidth, constraints.maxHeight),
                      child: _buildGadgetContent(config.id, accentColor, music, settings),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color color) => Positioned(top: 0, left: 0, right: 0, height: 60, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), child: Center(child: Text('DASHCORE PRO', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8, shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 15)])))));

  Widget _buildGadgetContent(String id, Color color, MusicProvider music, DashSettingsProvider settings) {
    switch (id) {
      case 'rpm_gauge':
        return Stack(
          alignment: Alignment.center,
          children: [
            RpmWarningAnimation(
              rpm: widget.data.rpm,
              child: RepaintBoundary(child: CustomPaint(painter: RpmGaugePainter(rpmValue: widget.data.rpm / 1000, color: color, showNumbers: false, isSolid: true), child: const SizedBox.expand())),
            ),
            Positioned(bottom: 25, child: Text('RPM', style: TextStyle(color: color.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2))),
          ],
        );
      case 'speed_ring_gauge': return _buildSpeedRingPanel(color);
      case 'volt_temp_hub': return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_largeSensorItem(Icons.bolt_rounded, Colors.orangeAccent, 'VOLT', '${widget.data.voltage.toStringAsFixed(1)}V'), const VerticalDivider(color: Colors.white10, width: 1, indent: 15, endIndent: 15), _largeSensorItem(Icons.thermostat_rounded, Colors.cyanAccent, 'TEMP', '${widget.data.engineTemp}°C')]);
      case 'vehicle_model': return RepaintBoundary(child: ModelViewer(key: ValueKey('${settings.modelPath}_${settings.vehicleColorHex}'), src: settings.modelPath, backgroundColor: Colors.transparent, autoRotate: false, cameraControls: false, disableZoom: true, disablePan: true, cameraOrbit: '45deg 75deg 3m', exposure: 1.0, shadowIntensity: 0.1, loading: Loading.eager, relatedJs: _getVehicleScript(settings.vehicleColorHex)));
      case 'media_player_bar': return MusicHub(accentColor: color, compact: true);
      case 'sensors_bar': return _buildSensorsBar(color);
      default: return const SizedBox.shrink();
    }
  }

  Widget _panelBox({required Widget child, double padding = 10}) => Container(decoration: BoxDecoration(color: const Color(0xFF0A0D14).withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]), padding: EdgeInsets.all(padding), child: child);

  Widget _buildSpeedRingPanel(Color color) => Stack(alignment: Alignment.center, children: [RepaintBoundary(child: CustomPaint(painter: SpeedRingGaugePainter(speedKmh: widget.data.speed.toDouble(), color: color), child: const SizedBox.expand())), Column(mainAxisSize: MainAxisSize.min, children: [Text('${widget.data.speed}', style: const TextStyle(color: Colors.white, fontSize: 92, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -4)), const Text('KM/H', style: TextStyle(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4))])]);

  Widget _largeSensorItem(IconData i, Color c, String l, String v) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 28), const SizedBox(height: 4), Text(v, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)), Text(l, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold))]);

  Widget _buildSensorsBar(Color color) {
    final settings = context.read<DashSettingsProvider>();
    final fuel = settings.useSimulatedFuel ? settings.simulatedFuelLevel.round() : widget.data.fuelLevel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [if (settings.showFuelGauge) _fuelSensor(color, fuel)]),
          Row(children: [const Icon(Icons.more_horiz_rounded, color: Colors.white12, size: 20)])
        ]
      )
    );
  }
  Widget _fuelSensor(Color c, int level) => Row(children: [const Icon(Icons.local_gas_station_rounded, color: Colors.blueAccent, size: 20), const SizedBox(width: 8), Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('FUEL', style: TextStyle(color: Colors.white38, fontSize: 7, fontWeight: FontWeight.bold)), Row(children: [Text('$level%', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Container(width: 60, height: 3, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (level/100).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)))))])])]);

  String _getVehicleScript(String hex) {
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
}
