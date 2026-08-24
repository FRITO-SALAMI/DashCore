import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widget/update_dialog.dart';

class UpdateCenterScreen extends StatefulWidget {
  final VoidCallback onBack;
  const UpdateCenterScreen({super.key, required this.onBack});

  @override
  State<UpdateCenterScreen> createState() => _UpdateCenterScreenState();
}

class _UpdateCenterScreenState extends State<UpdateCenterScreen> {
  UpdateStatus _status = UpdateStatus.upToDate;
  String _currentVersion = '1.0.2';
  String? _newVersion;
  String? _downloadUrl;
  bool _isChecking = false;

  Future<void> _checkUpdates() async {
    setState(() {
      _isChecking = true;
      _status = UpdateStatus.checking;
    });

    await Future.delayed(const Duration(seconds: 2));

    try {
      final release = await SupabaseService.instance.getActiveVersion();
      if (release.isEmpty) {
         setState(() {
           _status = UpdateStatus.upToDate;
           _isChecking = false;
         });
         return;
      }

      final int latestVersionCode = release['version_code'] ?? 0;
      const int currentVersionCode = SupabaseService.appBuild;

      if (latestVersionCode > currentVersionCode) {
        setState(() {
          _status = UpdateStatus.available;
          _newVersion = release['version_name'];
          _downloadUrl = release['download_url'];
          _isChecking = false;
        });
      } else {
        setState(() {
          _status = UpdateStatus.upToDate;
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = UpdateStatus.error;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF090B0F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: widget.onBack),
                  const SizedBox(width: 8),
                  const Text('CENTRO DE ACTUALIZACIONES', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(),
                      const SizedBox(height: 30),
                      Text(
                        _status == UpdateStatus.upToDate ? 'SISTEMA AL DÍA' : (_status == UpdateStatus.available ? 'ACTUALIZACIÓN DISPONIBLE' : 'VERIFICANDO SISTEMA'),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Versión actual: $_currentVersion',
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                      const SizedBox(height: 50),
                      if (_status == UpdateStatus.available)
                         Text('Nueva versión $_newVersion lista para descargar', style: const TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : (_status == UpdateStatus.available ? () {} : _checkUpdates),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isChecking 
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(_status == UpdateStatus.available ? 'DESCARGAR AHORA' : 'BUSCAR ACTUALIZACIONES', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
     Color color = Colors.greenAccent;
     IconData icon = Icons.check_circle_rounded;
     
     if (_status == UpdateStatus.available) {
       color = Colors.amberAccent;
       icon = Icons.system_update_rounded;
     } else if (_status == UpdateStatus.checking) {
       color = const Color(0xFF00E5FF);
       icon = Icons.sync_rounded;
     }

     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
       child: Icon(icon, color: color, size: 60),
     );
  }
}
