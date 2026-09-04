import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle_model.dart';
import '../providers/dash_settings_provider.dart';

class VehicleResourceDownloadScreen extends StatefulWidget {
  const VehicleResourceDownloadScreen({super.key, required this.vehicle});
  final Vehicle vehicle;

  @override
  State<VehicleResourceDownloadScreen> createState() =>
      _VehicleResourceDownloadScreenState();
}

class _VehicleResourceDownloadScreenState
    extends State<VehicleResourceDownloadScreen> {
  String? _error;

  Future<void> _download() async {
    setState(() => _error = null);
    final settings = context.read<DashSettingsProvider>();
    settings.selectVehicle(widget.vehicle);
    final success = await settings.downloadVehicleResources();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(
        () => _error =
            'No se pudieron descargar los recursos. Verifica la conexión.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('DESCARGAR RECURSOS'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_download_rounded,
                  color: Color(0xFF00E5FF),
                  size: 74,
                ),
                const SizedBox(height: 22),
                Text(
                  widget.vehicle.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'El modelo 3D y los recursos visuales de este vehículo se descargarán una sola vez y quedarán guardados en este dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, height: 1.4),
                ),
                const SizedBox(height: 28),
                if (settings.isDownloadingResources) ...[
                  LinearProgressIndicator(
                    value: settings.downloadProgress,
                    color: const Color(0xFF00E5FF),
                    backgroundColor: Colors.white10,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    settings.downloadSizeMessage,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: settings.isDownloadingResources
                        ? null
                        : _download,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      settings.isDownloadingResources
                          ? 'DESCARGANDO…'
                          : 'DESCARGAR Y SELECCIONAR',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
