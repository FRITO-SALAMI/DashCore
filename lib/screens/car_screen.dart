import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../providers/dash_settings_provider.dart';
import '../widget/vehicle_top_view.dart';
import '../widget/workshop_diagnostics_panel.dart';
import 'manual_vehicle_screen.dart';
import '../utils/vehicle_presentation.dart';
import 'package:file_picker/file_picker.dart';

class CarScreen extends StatelessWidget {
  const CarScreen({super.key, required this.onBack});
  final VoidCallback onBack;
  static const _models = [
    Vehicle(
      id: 'local-generic',
      name: 'Deportivo',
      brand: 'Genérico',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-k5',
      name: 'K5 / Optima',
      brand: 'Kia',
      year: '2012',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-optima',
      name: 'Optima',
      brand: 'Kia',
      year: '2015',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-sonata',
      name: 'Sonata LF',
      brand: 'Hyundai',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-nline',
      name: 'Sonata N Line',
      brand: 'Hyundai',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-y20',
      name: 'Sonata Y20',
      brand: 'Hyundai',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-civic',
      name: 'Civic',
      brand: 'Honda',
      year: '2016',
      backgroundImage: '',
      modelPath: '',
    ),
    Vehicle(
      id: 'local-h1',
      name: 'H1',
      brand: 'Hyundai',
      backgroundImage: '',
      modelPath: '',
    ),
  ];

  Future<void> _time(
    BuildContext context,
    DashSettingsProvider settings,
    bool on,
  ) async {
    final minutes = on ? settings.vehicleLightsOn : settings.vehicleLightsOff;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (time == null || !context.mounted) return;
    final value = time.hour * 60 + time.minute;
    if (value == (on ? settings.vehicleLightsOff : settings.vehicleLightsOn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige horas diferentes para encender y apagar.'),
        ),
      );
      return;
    }
    await settings.setVehicleLightSchedule(
      on ? value : settings.vehicleLightsOn,
      on ? settings.vehicleLightsOff : value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final vehicles = uniqueVehicleChoices(
      _models,
      settings.availableVehicles,
      settings.selectedVehicle,
    );
    final current = settings.selectedVehicle;
    String hour(int minutes) =>
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);
    final controls = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: current?.id ?? _models.first.id,
          decoration: const InputDecoration(labelText: 'Tu vehículo'),
          items: [
            if (current != null && !vehicles.any((v) => v.id == current.id))
              DropdownMenuItem(value: current.id, child: Text(current.name)),
            ...vehicles.map(
              (v) => DropdownMenuItem(
                value: v.id,
                child: Text(
                  vehicleDisplayName(v),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (id) =>
              settings.selectVehicle(vehicles.firstWhere((v) => v.id == id)),
        ),
        const SizedBox(height: 22),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Usar mi GLB en los tableros'),
          subtitle: const Text(
            'Vista cenital por defecto. El modelo 3D se activa al elegirlo.',
          ),
          value: settings.useVehicle3d,
          onChanged: (value) async {
            if (!value) {
              await settings.setUseVehicle3d(false);
              return;
            }
            if (settings.modelPath.isNotEmpty) {
              await settings.setUseVehicle3d(true);
              return;
            }
            try {
              final file = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['glb'],
                withData: false,
              );
              final path = file?.files.single.path;
              if (path != null) await settings.importOptionalVehicleGlb(path);
            } catch (error) {
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo cargar el GLB. $error')),
                );
            }
          },
        ),
        const Text('COLOR DE CARROCERÍA'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final hex in [
              '#FFFFFF',
              '#BAC3D1',
              '#343D4B',
              '#10151E',
              '#CC343F',
              '#187CB5',
              '#1D897B',
              '#D5AC52',
            ])
              Semantics(
                button: true,
                label: 'Color $hex',
                selected: settings.vehicleColorHex == hex,
                child: InkWell(
                  onTap: () => settings.setVehicleColor(hex),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color(
                        0xFF000000 | int.parse(hex.substring(1), radix: 16),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 3,
                        color: settings.vehicleColorHex == hex
                            ? Colors.cyanAccent
                            : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.light_mode_outlined),
          title: const Text('Encender luces'),
          subtitle: Text(hour(settings.vehicleLightsOn)),
          onTap: () => _time(context, settings, true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.wb_sunny_outlined),
          title: const Text('Apagar luces'),
          subtitle: Text(hour(settings.vehicleLightsOff)),
          onTap: () => _time(context, settings, false),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.monitor_heart_outlined),
          label: const Text('Diagnóstico OBD2'),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const FractionallySizedBox(
              heightFactor: .94,
              child: WorkshopDiagnosticsPanel(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Agregar mi vehículo'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ManualVehicleScreen()),
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: const Color(0xFF061019),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('GARAJE'),
      ),
      body: LayoutBuilder(
        builder: (context, bounds) {
          final car = RepaintBoundary(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF253747), Color(0xFF061019)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: VehicleTopView(
                  colorHex: settings.vehicleColorHex,
                  vehicle: current,
                  hoodOpen: true,
                ),
              ),
            ),
          );
          return bounds.maxWidth >= 600
              ? Row(
                  children: [
                    Expanded(child: car),
                    Expanded(child: controls),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 2, child: car),
                    Expanded(flex: 3, child: controls),
                  ],
                );
        },
      ),
    );
  }
}
