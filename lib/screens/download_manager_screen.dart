import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/resource_service.dart';

class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  List<FileSystemEntity> _vehicleDirs = [];
  List<File> _gifFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    final base = await getApplicationDocumentsDirectory();

    // Load vehicle directories
    final vehiclesPath = Directory('${base.path}/dashcore/vehicles');
    if (await vehiclesPath.exists()) {
      _vehicleDirs = vehiclesPath.listSync().whereType<Directory>().toList();
    } else {
      _vehicleDirs = [];
    }

    // Load GIFs
    _gifFiles = await ResourceService.instance.getLocalFiles('gifstore');

    setState(() => _loading = false);
  }

  Future<void> _deleteVehicle(String id) async {
    await ResourceService.instance.deleteVehicleDirectory(id);
    _loadFiles();
  }

  Future<void> _deleteGif(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
    _loadFiles();
  }

  Future<void> _deleteAllGifs() async {
    for (var f in _gifFiles) {
      if (await f.exists()) await f.delete();
    }
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1012),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('GESTOR DE DESCARGAS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('VEHÍCULOS DESCARGADOS', Icons.directions_car_rounded),
                if (_vehicleDirs.isEmpty)
                  _buildEmpty('No hay vehículos locales')
                else
                  ..._vehicleDirs.map((dir) {
                    final id = dir.path.split('/').last;
                    return _buildFileItem(
                      title: 'VEHÍCULO ID: $id',
                      subtitle: 'Recursos 3D y Fondo',
                      onDelete: () => _deleteVehicle(id),
                    );
                  }),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader('GIFS ANIMADOS', Icons.gif_box_rounded),
                    if (_gifFiles.isNotEmpty)
                      TextButton(
                        onPressed: _deleteAllGifs,
                        child: const Text('BORRAR TODO', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (_gifFiles.isEmpty)
                  _buildEmpty('No hay GIFs descargados')
                else
                  ..._gifFiles.map((file) {
                    final name = file.path.split('/').last;
                    return _buildFileItem(
                      title: name.toUpperCase(),
                      subtitle: '${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                      onDelete: () => _deleteGif(file),
                    );
                  }),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 18),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white10, fontSize: 13))),
    );
  }

  Widget _buildFileItem({required String title, required String subtitle, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF13161D),
                  title: const Text('ELIMINAR RECURSO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  content: Text('¿Estás seguro de que quieres eliminar $title?', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                    TextButton(
                      onPressed: () {
                        onDelete();
                        Navigator.pop(ctx);
                      },
                      child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
