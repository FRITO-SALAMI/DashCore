import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/obd_provider.dart';
import '../providers/dash_settings_provider.dart';
import '../widget/gauges/sporty_dashboard.dart';
import '../widget/gauges/racing_dashboard.dart';
import '../widget/gauges/modern_dashboard.dart';
import '../widget/gauges/vehicle_3d_dashboard.dart';
import '../widget/gauges/purple_puff_dashboard.dart';
import '../widget/gauges/racing_hud_dashboard.dart';
import '../widget/gauges/glow_red_dashboard.dart';
import '../widget/gauges/hellish_red_dashboard.dart';
import '../widget/gauges/custom_gauge_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ObdProvider>();
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

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obdProvider = context.watch<ObdProvider>();
    final dashSettings = context.watch<DashSettingsProvider>();
    final obdData = obdProvider.data;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildSelectedDashboard(dashSettings, obdData),
            ),
            
            // Custom Gauges (Edit Mode)
            ...dashSettings.customGauges.map((config) {
              return Positioned(
                left: config.position.dx,
                top: config.position.dy,
                child: GestureDetector(
                  onPanUpdate: dashSettings.isEditMode ? (details) {
                    dashSettings.updateGaugePosition(config.id, config.position + details.delta);
                  } : null,
                  child: CustomGaugeWidget(
                    type: config.type,
                    value: _getGaugeValue(config.type, obdData),
                    unit: _getGaugeUnit(config.type),
                    color: dashSettings.accentColor,
                  ),
                ),
              );
            }),

            // EDIT MODE UI
            if (dashSettings.isEditMode)
              Positioned(
                top: 20,
                right: 20,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'add_gauge',
                      onPressed: () => _showAddGaugeMenu(context, dashSettings),
                      backgroundColor: const Color(0xFF00E5FF),
                      child: const Icon(Icons.add, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'close_edit',
                      onPressed: () => dashSettings.toggleEditMode(),
                      backgroundColor: Colors.redAccent,
                      mini: true,
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AÑADIR INDICADOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AddGaugeItem(icon: Icons.speed, label: 'VEL', onTap: () { settings.addCustomGauge('speed'); Navigator.pop(ctx); }),
                _AddGaugeItem(icon: Icons.track_changes, label: 'RPM', onTap: () { settings.addCustomGauge('rpm'); Navigator.pop(ctx); }),
                _AddGaugeItem(icon: Icons.thermostat, label: 'TEMP', onTap: () { settings.addCustomGauge('temp'); Navigator.pop(ctx); }),
                _AddGaugeItem(icon: Icons.bolt, label: 'VOLT', onTap: () { settings.addCustomGauge('volt'); Navigator.pop(ctx); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  dynamic _getGaugeValue(String type, data) {
    if (type == 'speed') return data.speed;
    if (type == 'rpm') return data.rpm;
    if (type == 'temp') return data.engineTemp;
    return data.voltage.toStringAsFixed(1);
  }

  String _getGaugeUnit(String type) {
    if (type == 'speed') return 'KM/H';
    if (type == 'rpm') return 'RPM';
    if (type == 'temp') return '°C';
    return 'V';
  }

  Widget _buildSelectedDashboard(DashSettingsProvider settings, obdData) {
    final tempUnitStr = settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F';
    switch (settings.selectedStyle) {
      case DashboardStyle.racing:
        return RacingDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
        );
      case DashboardStyle.modern:
        return ModernDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
        );
      case DashboardStyle.vehicle3D:
        return Vehicle3DDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
          modelPath: settings.modelPath,
        );
      case DashboardStyle.purplePuff:
        return PurplePuffDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          tempUnit: tempUnitStr,
        );
      case DashboardStyle.racingHud:
        return const RacingHudDashboard();
      case DashboardStyle.glowRed:
        return GlowRedDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          tempUnit: tempUnitStr,
        );
      case DashboardStyle.hellishRed:
        return HellishRedDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          tempUnit: tempUnitStr,
        );
      case DashboardStyle.sporty:
        return SportyDashboard(
          speed: obdData.speed,
          rpm: obdData.rpm,
          coolantTemp: settings.convertTemp(obdData.engineTemp).round(),
          voltage: obdData.voltage,
          accentColor: settings.accentColor,
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          tempUnit: tempUnitStr,
        );
    }
  }
}

class _AddGaugeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddGaugeItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF00E5FF)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
