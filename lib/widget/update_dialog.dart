import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/analytics_service.dart';

enum UpdateStatus { upToDate, available, checking, error }

class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String? newVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final UpdateStatus initialStatus;
  final bool isMandatory;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    this.newVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.initialStatus = UpdateStatus.available,
    this.isMandatory = false,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  late UpdateStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  Future<void> _launchUrl() async {
    if (widget.downloadUrl == null) return;
    final Uri url = Uri.parse(widget.downloadUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String description;

    switch (_status) {
      case UpdateStatus.upToDate:
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'SISTEMA ACTUALIZADO';
        description = 'Estás en la última versión (${widget.currentVersion})';
        break;
      case UpdateStatus.available:
        statusColor = const Color(0xFF00E5FF);
        statusIcon = Icons.info_rounded;
        statusText = 'FALTA ACTUALIZACIÓN';
        description = 'Nueva versión ${widget.newVersion} disponible';
        break;
      case UpdateStatus.checking:
        statusColor = const Color(0xFF00E5FF);
        statusIcon = Icons.sync_rounded;
        statusText = 'VERIFICANDO...';
        description = 'Buscando actualizaciones en el servidor';
        break;
      case UpdateStatus.error:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_rounded;
        statusText = 'ERROR DE CONEXIÓN';
        description = 'Se requiere internet para verificar';
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_status == UpdateStatus.available && widget.releaseNotes != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.releaseNotes!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                if (!widget.isMandatory || _status != UpdateStatus.available)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (_status == UpdateStatus.available) {
                          AnalyticsService.instance.logEvent('app_update_ignored', data: {
                            'version': widget.newVersion,
                          });
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        'CERRAR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                if (_status == UpdateStatus.available && !widget.isMandatory)
                  const SizedBox(width: 16),
                if (_status == UpdateStatus.available)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AnalyticsService.instance.logEvent('app_update_clicked', data: {
                          'version': widget.newVersion,
                        });
                        _launchUrl();
                        if (!widget.isMandatory) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ACTUALIZAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
