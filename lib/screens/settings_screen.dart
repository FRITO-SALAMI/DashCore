import 'dart:io';
import 'dart:async';
import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/widget/update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/dash_settings_provider.dart';
import '../providers/obd_provider.dart';
import '../utils/app_localizations.dart';
import '../widget/tutorial/tutorial_keys.dart';
import 'auth_screen.dart';

class _DismissibleCupertinoSheetRoute<T> extends CupertinoSheetRoute<T> {
  _DismissibleCupertinoSheetRoute({
    required super.scrollableBuilder,
    super.enableDrag,
    Color barrierColor = const Color(0x73000000),
  }) : _barrierColor = barrierColor;
  final Color _barrierColor;
  @override Color? get barrierColor => _barrierColor;
  @override bool get barrierDismissible => true;
  @override String get barrierLabel => 'Dismiss';
}

void showSettingsSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  Navigator.of(context, rootNavigator: true).push(
    _DismissibleCupertinoSheetRoute(
      barrierColor: Colors.black.withOpacity(0.45),
      scrollableBuilder: (sheetContext, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (notification.extent <= notification.minExtent + 0.01) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
              });
            }
            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.75, minChildSize: 0.50, maxChildSize: 0.95, expand: false,
            builder: (context, scrollController) => SettingsSheet(scrollController: scrollController),
          ),
        );
      },
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const SettingsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              GestureDetector(
                onVerticalDragUpdate: (details) { if (details.delta.dy > 5) onBack(); },
                child: Container(
                  width: double.infinity,
                  height: 30,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ),
              Expanded(child: SettingsSheet(
                scrollController: ScrollController(),
                onClose: onBack,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSheet extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onClose;
  const SettingsSheet({super.key, required this.scrollController, this.onClose});
  @override State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.instance.currentUser;
    final client = SupabaseService.instance.client;
    _authSubscription = client?.auth.onAuthStateChange.listen((state) {
      if (mounted) setState(() => _user = state.session?.user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openAuthScreen() async {
    final settings = context.read<DashSettingsProvider>();
    if (settings.isTutorialActive && settings.tutorialStep == 12) {
      settings.setTutorialStep(13);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (!mounted) return;
    setState(() { _user = SupabaseService.instance.currentUser; });
  }

  Future<void> _signOut() async { await Supabase.instance.client.auth.signOut(); if (!mounted) return; setState(() { _user = null; }); }

  void _showPerformanceAutoDetect(BuildContext context) {
    final settings = context.read<DashSettingsProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13161D),
        title: const Text('AUTO-OPTIMIZACIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00E5FF), size: 40),
            const SizedBox(height: 20),
            Text(
              'ARQUITECTURA: ${settings.deviceArchitecture}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              settings.isLowResourceDevice
                ? 'TU DISPOSITIVO TIENE RECURSOS LIMITADOS. RECOMENDAMOS MODO EQUILIBRADO O AHORRO.'
                : 'DISPOSITIVO POTENTE DETECTADO. PUEDES USAR MODO ULTRA O ALTO RENDIMIENTO.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (settings.isLowResourceDevice) {
                settings.setPerformanceMode(PerformanceMode.balanced);
              } else {
                settings.setPerformanceMode(PerformanceMode.ultra);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CONFIGURACIÓN APLICADA'), backgroundColor: Color(0xFF00E5FF))
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            child: const Text('APLICAR RECOMENDADO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13161D),
        title: const Text('INFORME TÉCNICO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Describe el problema...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendDiagnosis(controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            child: const Text('ENVIAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDiagnosis(String userComment) async {
    final settings = context.read<DashSettingsProvider>();
    final obd = context.read<ObdProvider>();
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    if (_user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DEBES INICIAR SESIÓN PRIMERO PARA ENVIAR REPORTES.'), backgroundColor: Colors.orangeAccent)
        );
      }
      return;
    }

    String deviceStr = "Desconocido";
    String androidVersionStr = "Desconocida";
    String architectureStr = "Desconocida";

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      deviceStr = "${android.manufacturer} ${android.model}";
      androidVersionStr = android.version.release;
      architectureStr = android.supportedAbis.join(', ');
    }

    final String messageBody = '''
Comentario:
$userComment

Información de diagnóstico:
App version: ${packageInfo.version} (${packageInfo.buildNumber})
Performance mode: ${settings.performanceMode.name}
OBD conectado: ${obd.isDeviceConnected}
Dispositivo: $deviceStr
Android: $androidVersionStr
Arquitectura: $architectureStr
''';

    Map<String, dynamic> reportData = {
      'user_id': _user?.id,
      'reporter_name': _user?.userMetadata?['display_name'] ?? _user?.email,
      'reporter_email': _user?.email,
      'subject': 'Diagnóstico técnico DashCore',
      'message': messageBody,
    };

    try {
      await SupabaseService.instance.sendTechnicalReport(reportData);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('¡GRACIAS POR TU REPORTE! LO REVISAREMOS DE INMEDIATO.'),
             backgroundColor: Color(0xFF00E5FF),
             behavior: SnackBarBehavior.floating,
           )
         );
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('NO SE PUDO ENVIAR EL INFORME. INTÉNTALO DE NUEVO MÁS TARDE.'),
             backgroundColor: Colors.redAccent,
             behavior: SnackBarBehavior.floating,
           )
         );
       }
    }
  }

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

  void _showScannerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF13161D),
          title: const Row(children: [
            Icon(Icons.radar_rounded, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 10),
            Text('ESCÁNER DE SENSORES OBD', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))
          ]),
          content: const SizedBox(
            width: double.maxFinite,
            child: _ScannerBody(),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('DETENER ESCÁNER'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = Color(0xFF00E5FF);
    final isSpanish = loc.language == Language.spanish;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xF2090B0F), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 25, backgroundColor: themeColor, backgroundImage: settings.profileImageUrl != null ? FileImage(File(settings.profileImageUrl!)) : null, child: settings.profileImageUrl == null ? const Icon(Icons.person_rounded, color: Colors.black, size: 30) : null),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_user != null ? (_user!.email ?? 'USUARIO').toUpperCase() : 'USUARIO INVITADO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_user != null ? 'Sincronización activa' : 'Inicia sesión para sincronizar', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                      ])),
                      if (_user == null)
                        ElevatedButton(
                          key: TutorialKeys.loginButtonKey,
                          onPressed: _openAuthScreen,
                          style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('ACCEDER', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))
                        )
                      else
                        IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _signOut),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(loc.translate('settings').toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: widget.onClose ?? () => Navigator.pop(context)
                  ),
                ]),

                const SizedBox(height: 24),
                _SectionHeader(title: isSpanish ? 'RENDIMIENTO' : 'PERFORMANCE'),
                const SizedBox(height: 12),
                _SettingsToggleTile(
                  icon: Icons.speed_rounded,
                  label: isSpanish ? 'REVISAR MEJOR CONFIGURACIÓN' : 'CHECK BEST CONFIGURATION',
                  value: isSpanish ? 'AUTO-DETECTAR' : 'AUTO-DETECT',
                  onTap: () => _showPerformanceAutoDetect(context),
                ),
                const SizedBox(height: 12),
                _SettingsSelector(
                  label: isSpanish ? 'MODO DE RENDIMIENTO' : 'PERFORMANCE MODE',
                  value: settings.performanceMode.name.toUpperCase(),
                  onTap: () {
                    final next = PerformanceMode.values[(settings.performanceMode.index + 1) % PerformanceMode.values.length];
                    settings.setPerformanceMode(next);
                  },
                ),
                if (settings.performanceMode == PerformanceMode.auto)
                   Padding(
                     padding: const EdgeInsets.only(top: 8, left: 10),
                     child: Text(
                       'RECOMENDADO: ${settings.deviceArchitecture}. ${settings.isLowResourceDevice ? "Optimizaciones activas." : "Recursos OK."}',
                       style: TextStyle(color: themeColor.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold),
                     ),
                   ),
                const SizedBox(height: 12),
                _SettingsToggleTile(
                  icon: Icons.monitor_heart_outlined,
                  label: isSpanish
                      ? 'MEDICIÓN DE RENDIMIENTO'
                      : 'PERFORMANCE MEASUREMENT',
                  value: settings.performanceMonitoringEnabled
                      ? (isSpanish ? 'ACTIVADA' : 'ENABLED')
                      : (isSpanish ? 'DESACTIVADA' : 'DISABLED'),
                  isActive: settings.performanceMonitoringEnabled,
                  onTap: () => settings.setPerformanceMonitoringEnabled(
                    !settings.performanceMonitoringEnabled,
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: isSpanish ? 'HERRAMIENTAS OBD' : 'OBD TOOLS'),
                const SizedBox(height: 12),
                _SettingsToggleTile(
                  icon: Icons.analytics_rounded,
                  label: isSpanish ? 'ESCÁNER DE SENSORES' : 'SENSOR SCANNER',
                  value: isSpanish ? 'VER TODO' : 'VIEW ALL',
                  onTap: () => _showScannerDialog(context),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'APARIENCIA'),
                const SizedBox(height: 12),
                _SettingsToggleTile(icon: Icons.language_rounded, label: loc.translate('lang'), value: settings.language == Language.english ? 'English' : 'Español', onTap: () => settings.setLanguage(settings.language == Language.english ? Language.spanish : Language.english)),
                const SizedBox(height: 12),
                _SettingsToggleTile(icon: Icons.waving_hand_rounded, label: 'SALUDO DE BIENVENIDA', value: settings.showWelcomeGreeting ? 'ACTIVADO' : 'DESACTIVADO', isActive: settings.showWelcomeGreeting, onTap: () => settings.toggleWelcomeGreeting(!settings.showWelcomeGreeting)),
                if (settings.showWelcomeGreeting) ...[
                   const SizedBox(height: 12),
                   _SettingsSelector(label: isSpanish ? 'DISEÑO DEL SALUDO' : 'GREETING DESIGN', value: "DISEÑO ${settings.welcomeDesign + 1}", onTap: () => settings.setWelcomeDesign((settings.welcomeDesign + 1) % 5)),
                   const SizedBox(height: 12),
                   _SettingsSlider(label: isSpanish ? 'DURACIÓN DEL SALUDO' : 'GREETING DURATION', value: settings.welcomeGreetingDuration, min: 3, max: 12, unit: 's', onChanged: settings.setWelcomeGreetingDuration),
                ],

                const SizedBox(height: 24),
                _SectionHeader(title: isSpanish ? 'SOPORTE' : 'SUPPORT'),
                const SizedBox(height: 12),
                _SettingsToggleTile(
                  icon: Icons.bug_report_rounded,
                  label: isSpanish ? 'INFORME TÉCNICO' : 'TECHNICAL REPORT',
                  value: isSpanish ? 'ENVIAR' : 'SEND',
                  onTap: _showReportDialog,
                ),
                const SizedBox(height: 12),
                _SettingsToggleTile(
                  icon: Icons.info_outline_rounded,
                  label: 'ACERCA DE',
                  value: 'DashCore v0.0.2',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'DashCore',
                    applicationVersion: '0.0.2+1',
                    applicationIcon: Image.asset('assets/icon/Logoapp.png', width: 50),
                    children: [
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => _showPrivacyPolicy(context),
                        child: const Text(
                          'POLÍTICAS DE PRIVACIDAD',
                          style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_user != null) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(title: isSpanish ? 'AVANZADO' : 'ADVANCED'),
                  const SizedBox(height: 12),
                  _SettingsToggleTile(
                    icon: Icons.delete_forever_rounded,
                    label: isSpanish ? 'ELIMINAR CUENTA' : 'DELETE ACCOUNT',
                    value: isSpanish ? 'GESTIONAR' : 'MANAGE',
                    onTap: _showDeleteAccountDialog,
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13161D),
        title: const Text('POLÍTICAS DE PRIVACIDAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        content: const SingleChildScrollView(
          child: Text(
            '''
DashCore valora tu privacidad. Esta aplicación recopila datos de telemetría de tu vehículo a través de dispositivos OBD2 y GPS para mostrar información en tiempo real.

1. Recopilación de Datos:
   - Datos del vehículo (RPM, velocidad, temperatura, etc.) mediante OBD2.
   - Ubicación en tiempo real mediante GPS para calcular velocidad.
   - Información del dispositivo para optimización de rendimiento.

2. Uso de la Información:
   - Los datos se procesan localmente para el funcionamiento del tablero.
   - Si inicias sesión, las preferencias se sincronizan con Supabase.
   - Los reportes técnicos enviados por el usuario incluyen datos de diagnóstico.

3. Permisos:
   - Bluetooth: Necesario para conectar con adaptadores OBD2.
   - Ubicación: Necesaria para el modo GPS y escaneo Bluetooth (Android requirement).
   - Almacenamiento: Para guardar fotos de perfil y caché de modelos 3D.

4. Terceros:
   - Utilizamos Supabase para autenticación y base de datos en la nube.
   - Google Play Services para servicios básicos de la plataforma.

Al usar DashCore, aceptas estos términos necesarios para la implementación en Google Play Store.
''',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    if (_user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAccountCountdownDialog(
        onConfirm: () async {
          try {
            await SupabaseService.instance.deleteAccount();
            if (mounted) {
              Navigator.of(context).pop(); // Cierra el diálogo
              if (widget.onClose != null) widget.onClose!(); // Cierra ajustes
              setState(() { _user = null; });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CUENTA ELIMINADA CORRECTAMENTE'), backgroundColor: Colors.redAccent)
              );
            }
          } catch (e) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ERROR AL ELIMINAR CUENTA: $e'), backgroundColor: Colors.redAccent)
              );
            }
          }
        },
      ),
    );
  }
}

class _DeleteAccountCountdownDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const _DeleteAccountCountdownDialog({required this.onConfirm});

  @override
  State<_DeleteAccountCountdownDialog> createState() => _DeleteAccountCountdownDialogState();
}

class _DeleteAccountCountdownDialogState extends State<_DeleteAccountCountdownDialog> {
  int _secondsRemaining = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() { _secondsRemaining--; });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF13161D),
      title: const Text('ELIMINAR CUENTA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
          const SizedBox(height: 20),
          const Text(
            'ESTA ACCIÓN ES IRREVERSIBLE. SE ELIMINARÁ TU PERFIL, CONFIGURACIÓN Y TODOS LOS DATOS ASOCIADOS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (_secondsRemaining > 0)
            Text(
              'ESPERA $_secondsRemaining SEGUNDOS...',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            )
          else
            const Text(
              '¿ESTÁS SEGURO?',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: _secondsRemaining == 0 ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            disabledBackgroundColor: Colors.redAccent.withOpacity(0.3),
          ),
          child: const Text('ELIMINAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _ScannerBody extends StatefulWidget {
  const _ScannerBody();
  @override State<_ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<_ScannerBody> {
  int _visibleCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_visibleCount < 6) {
        setState(() => _visibleCount++);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ObdProvider>(
      builder: (context, obd, _) {
        final data = obd.data;
        final allSensors = [
          {'label': 'VELOCIDAD', 'value': '${data.speed} KM/H', 'icon': Icons.speed},
          {'label': 'RPM', 'value': '${data.rpm}', 'icon': Icons.track_changes},
          {'label': 'TEMPERATURA', 'value': '${data.engineTemp}°C', 'icon': Icons.thermostat},
          {'label': 'VOLTAJE', 'value': '${data.voltage.toStringAsFixed(1)}V', 'icon': Icons.battery_charging_full},
          {'label': 'ODÓMETRO', 'value': '${data.odometer}', 'icon': Icons.map_rounded},
          {'label': 'MARCHA', 'value': data.gear, 'icon': Icons.settings_input_component_rounded},
        ];

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ScanningAnimation(),
                const SizedBox(height: 20),
                ...List.generate(_visibleCount.clamp(0, allSensors.length), (index) {
                  final sensor = allSensors[index];
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Icon(sensor['icon'] as IconData, color: const Color(0xFF00E5FF).withOpacity(0.4), size: 14),
                            const SizedBox(width: 10),
                            Text(sensor['label'] as String, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                          ]),
                          Text(sensor['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  );
                }),
                if (_visibleCount < allSensors.length)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('DETECTANDO SENSORES...', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanningAnimation extends StatefulWidget {
  const _ScanningAnimation();
  @override State<_ScanningAnimation> createState() => _ScanningAnimationState();
}
class _ScanningAnimationState extends State<_ScanningAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _c; @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => RotationTransition(turns: _c, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 1)), child: const Icon(Icons.sync_rounded, color: Color(0xFF00E5FF), size: 30)));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.only(left: 4), child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.5)));
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon; final String label, value; final VoidCallback onTap; final bool? isActive;
  const _SettingsToggleTile({required this.icon, required this.label, required this.value, required this.onTap, this.isActive});
  @override Widget build(BuildContext context) { final bool active = isActive ?? (value.contains('ACTIVADO') || value.contains('English') || value.contains('Español') || value.contains('VER') || value.contains('VIEW') || value.contains('ENVIAR')); return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [Icon(icon, size: 20, color: active ? const Color(0xFF00E5FF) : Colors.white24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 1.2)), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))])), const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white12)]))))); }
}

class _SettingsSelector extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _SettingsSelector({required this.label, required this.value, required this.onTap});
  @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 1.2)), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))])), const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00E5FF))])))));
}

class _SettingsSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final String unit;
  final Function(double) onChanged;
  const _SettingsSlider({required this.label, required this.value, required this.min, required this.max, required this.unit, required this.onChanged});
  @override build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 1.2)), Text("${value.round()}$unit", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)))]), Slider(value: value, min: min, max: max, activeColor: const Color(0xFF00E5FF), inactiveColor: Colors.white10, onChanged: onChanged)]));
}
