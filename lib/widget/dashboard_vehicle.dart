import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../providers/dash_settings_provider.dart';
import 'compatible_vehicle_model.dart';
import 'vehicle_top_view.dart';

class DashboardVehicle extends StatelessWidget {
  const DashboardVehicle({
    super.key,
    this.colorHex,
    this.vehicle,
    this.source = '',
    this.preview = false,
  });
  final String? colorHex;
  final Vehicle? vehicle;
  final String source;
  final bool preview;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider?>();
    final path = source.isEmpty ? (settings?.modelPath ?? '') : source;
    if (!preview && settings?.useVehicle3d == true && path.isNotEmpty) {
      return CompatibleVehicleModel(
        src: path,
        preferLightPreview: false,
        cameraControls: false,
      );
    }
    return VehicleTopView(
      colorHex: colorHex ?? settings?.vehicleColorHex ?? '#C5CED9',
      vehicle: vehicle ?? settings?.selectedVehicle,
      source: path,
    );
  }
}
