import 'dart:io';

import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/widget/update_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../providers/dash_settings_provider.dart';
import '../providers/obd_provider.dart';
import '../utils/app_localizations.dart';
import 'auth_screen.dart';

class _DismissibleCupertinoSheetRoute<T> extends CupertinoSheetRoute<T> {
  _DismissibleCupertinoSheetRoute({
    required super.scrollableBuilder,
    super.enableDrag,
    Color barrierColor = const Color(0x73000000),
  }) : _barrierColor = barrierColor;

  final Color _barrierColor;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Dismiss';
}

void showSettingsSheet(BuildContext context) {
  HapticFeedback.mediumImpact();

  Navigator.of(context, rootNavigator: true).push(
    _DismissibleCupertinoSheetRoute(
      barrierColor: Colors.black.withOpacity(0.45),
      scrollableBuilder: (
        sheetContext,
        scrollController,
      ) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (notification.extent <= notification.minExtent + 0.01) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(sheetContext)) {
                  Navigator.pop(sheetContext);
                }
              });
            }

            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.70,
            minChildSize: 0.50,
            maxChildSize: 0.95,
            expand: false,
            builder: (
              context,
              scrollController,
            ) {
              return SettingsSheet(
                scrollController: scrollController,
              );
            },
          ),
        );
      },
    ),
  );
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.instance.currentUser;
  }

  Future<void> _openAuthScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _user = SupabaseService.instance.currentUser;
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) {
      return;
    }

    setState(() {
      _user = null;
    });
  }

  Future<void> _pickProfileImage(
    DashSettingsProvider settings,
  ) async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (!mounted) {
      return;
    }

    if (image != null) {
      settings.setProfileImageUrl(image.path);
    }
  }

  void _showFuelLevelSelection(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    double tempVal = settings.simulatedFuelLevel;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NIVEL DE COMBUSTIBLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ajusta el nivel inicial para la simulación',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_gas_station,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: Slider(
                          value: tempVal,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (v) {
                            setModalState(() {
                              tempVal = v;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${tempVal.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            settings.toggleUseSimulatedFuel(false);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'USAR DATOS OBD2',
                            style: TextStyle(
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            settings.setSimulatedFuelLevel(tempVal);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                          ),
                          child: const Text(
                            'ESTABLECER',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVehicleSelection(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'SELECCIONA TU VEHÍCULO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: settings.availableVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle =
                            settings.availableVehicles[index];

                        final isSelected =
                            settings.selectedVehicle?.id == vehicle.id;

                        final bool isLocal =
                            vehicle.modelPath.startsWith('assets/');

                        final bool needsDownload =
                            !isLocal && !vehicle.isDownloaded;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00E5FF).withOpacity(0.1)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00E5FF)
                                        .withOpacity(0.2)
                                    : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                needsDownload
                                    ? Icons.cloud_download_rounded
                                    : Icons.directions_car,
                                color: isSelected
                                    ? const Color(0xFF00E5FF)
                                    : (needsDownload
                                        ? Colors.orangeAccent
                                        : Colors.white54),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              vehicle.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              needsDownload
                                  ? 'Requiere descarga'
                                  : vehicle.brand,
                              style: TextStyle(
                                color: needsDownload
                                    ? Colors.orangeAccent.withOpacity(0.6)
                                    : Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              settings.selectVehicle(vehicle);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);

    const themeColor = Color(0xFF00E5FF);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF2090B0F),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _user != null
                            ? () => _pickProfileImage(settings)
                            : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: _user != null
                                  ? Colors.greenAccent
                                  : themeColor,
                              backgroundImage:
                                  settings.profileImageUrl != null &&
                                          !settings.profileImageUrl!
                                              .startsWith('http')
                                      ? FileImage(
                                          File(
                                            settings.profileImageUrl!,
                                          ),
                                        )
                                      : settings.profileImageUrl != null
                                          ? NetworkImage(
                                              settings.profileImageUrl!,
                                            )
                                          : null,
                              child: settings.profileImageUrl == null
                                  ? Icon(
                                      _user != null
                                          ? Icons.verified_user_rounded
                                          : Icons.person_rounded,
                                      color: Colors.black,
                                      size: 30,
                                    )
                                  : null,
                            ),
                            if (_user != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user != null
                                  ? (_user!.email ?? 'USUARIO').toUpperCase()
                                  : 'USUARIO INVITADO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _user != null
                                  ? 'Sincronización Supabase activa'
                                  : 'Inicia sesión para sincronizar',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_user == null)
                        ElevatedButton.icon(
                          onPressed: _openAuthScreen,
                          icon: const Icon(
                            Icons.login_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(
                            Icons.share_rounded,
                            color: themeColor,
                          ),
                          onPressed: () {
                            final text =
                                '¡Mira mi nivel en DashCore! Soy ${settings.driverLevel} con ${settings.totalDistance.toStringAsFixed(1)} KM recorridos. #DashCore #AndroidAuto';
                            Share.share(text);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: _signOut,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.translate('settings').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _SectionHeader(title: 'APARIENCIA'),
                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'ESTADÍSTICAS DE CONDUCCIÓN',
                  value: 'VER MI PERFIL',
                  onTap: () => _showStatistics(context, settings),
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.language_rounded,
                  label: loc.translate('lang'),
                  value: settings.language == Language.english
                      ? 'English'
                      : 'Español',
                  onTap: () {
                    settings.setLanguage(
                      settings.language == Language.english
                          ? Language.spanish
                          : Language.english,
                    );
                  },
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.waving_hand_rounded,
                  label: 'SALUDO DE BIENVENIDA',
                  value: settings.showWelcomeGreeting
                      ? 'ACTIVADO'
                      : 'DESACTIVADO',
                  onTap: () => settings.toggleWelcomeGreeting(
                    !settings.showWelcomeGreeting,
                  ),
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.local_gas_station_rounded,
                  label: 'INDICADOR DE COMBUSTIBLE',
                  value: settings.showFuelGauge
                      ? 'ACTIVADO'
                      : 'DESACTIVADO',
                  onTap: () => settings.toggleShowFuelGauge(
                    !settings.showFuelGauge,
                  ),
                ),

                if (settings.showWelcomeGreeting) ...[
                  const SizedBox(height: 12),
                  _SettingsSliderTile(
                    icon: Icons.timer_rounded,
                    label: 'DURACIÓN SALUDO',
                    value: settings.welcomeGreetingDuration,
                    min: 3,
                    max: 15,
                    suffix: 's',
                    onChanged: (v) =>
                        settings.setWelcomeGreetingDuration(v),
                  ),
                  const SizedBox(height: 12),
                  _SettingsToggleTile(
                    icon: Icons.animation_rounded,
                    label: 'DISEÑO DE ENCENDIDO',
                    value: 'DISEÑO ${settings.welcomeDesign + 1}',
                    onTap: () {
                      final int next =
                          (settings.welcomeDesign + 1) % 3;
                      settings.setWelcomeDesign(next);
                    },
                  ),
                ],

                const SizedBox(height: 24),

                _SectionHeader(title: 'SISTEMA'),
                const SizedBox(height: 12),

                _SettingsSliderTile(
                  icon: Icons.thermostat_rounded,
                  label: 'ALERTA DE TEMPERATURA',
                  value: settings.tempAlertThreshold,
                  min: 80,
                  max: 130,
                  suffix: '°C',
                  onChanged: (v) =>
                      settings.setTempAlertThreshold(v),
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.local_gas_station_rounded,
                  label: 'SIMULADOR DE COMBUSTIBLE',
                  value: settings.useSimulatedFuel
                      ? '${settings.simulatedFuelLevel.toStringAsFixed(1)}%'
                      : 'DESACTIVADO (REAL)',
                  onTap: () => _showFuelLevelSelection(
                    context,
                    settings,
                  ),
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.thermostat_outlined,
                  label: loc.translate('temp_unit'),
                  value: settings.tempUnit == TemperatureUnit.celsius
                      ? 'Celsius (°C)'
                      : 'Fahrenheit (°F)',
                  onTap: () {
                    settings.setTempUnit(
                      settings.tempUnit == TemperatureUnit.celsius
                          ? TemperatureUnit.fahrenheit
                          : TemperatureUnit.celsius,
                    );
                  },
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.location_on_rounded,
                  label: 'MODO DE FUNCIONAMIENTO',
                  value: settings.isNoObdMode
                      ? 'MODO GPS'
                      : 'MODO OBD2',
                  onTap: () {
                    final obd = context.read<ObdProvider>();

                    if (settings.isNoObdMode) {
                      settings.toggleNoObdMode(false);
                      obd.stopGpsMode();
                    } else {
                      settings.toggleNoObdMode(true);
                      obd.toggleGpsMode();
                    }
                  },
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.directions_car_rounded,
                  label: 'VEHÍCULO',
                  value: settings.selectedVehicle?.name ??
                      'SIN SELECCIONAR',
                  onTap: () => _showVehicleSelection(
                    context,
                    settings,
                  ),
                ),

                const SizedBox(height: 24),

                _SectionHeader(
                  title: 'RENDIMIENTO Y DATOS',
                ),
                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.analytics_rounded,
                  label: 'ANALÍTICA DE SUPABASE',
                  value: settings.analyticsConsent
                      ? 'ACTIVADO'
                      : 'DESACTIVADO',
                  onTap: () => settings.setAnalyticsConsent(
                    !settings.analyticsConsent,
                  ),
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.bolt_rounded,
                  label: 'MODO ESPECIAL (FAST DATA)',
                  value: settings.isPerformanceMode
                      ? 'ACTIVADO (10Hz)'
                      : 'DESACTIVADO (2Hz)',
                  onTap: () {
                    final value =
                        !settings.isPerformanceMode;

                    settings.togglePerformanceMode(value);

                    context
                        .read<ObdProvider>()
                        .setPerformanceMode(value);
                  },
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.speed_rounded,
                  label: 'MODO ADVANCED (ULTRA FAST)',
                  value: settings.isAdvancedMode
                      ? 'ACTIVADO (20Hz+)'
                      : 'DESACTIVADO',
                  onTap: () {
                    final value =
                        !settings.isAdvancedMode;

                    settings.toggleAdvancedMode(value);

                    context
                        .read<ObdProvider>()
                        .setAdvancedMode(value);
                  },
                ),

                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.battery_saver_rounded,
                  label: 'MODO AHORRO DE ENERGÍA',
                  value: settings.isPowerSavingMode
                      ? 'ACTIVADO'
                      : 'DESACTIVADO',
                  onTap: () {
                    final val =
                        !settings.isPowerSavingMode;

                    settings.togglePowerSavingMode(val);

                    context
                        .read<ObdProvider>()
                        .setPowerSavingMode(val);
                  },
                ),

                const SizedBox(height: 24),

                _SectionHeader(
                  title: 'APP & INFORMACIÓN',
                ),
                const SizedBox(height: 12),

                _SettingsToggleTile(
                  icon: Icons.info_outline_rounded,
                  label: 'ACERCA DE',
                  value: 'DashCore v1.0.2',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'DashCore',
                      applicationVersion: '1.0.2+4',
                      applicationIcon: Image.asset(
                        'assets/icon/Logoapp.png',
                        width: 50,
                      ),
                      children: [
                        const Text(
                          'DashCore es una plataforma de diagnóstico y personalización para vehículos.',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Desarrollado por el equipo de DashCore.',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                  _SettingsToggleTile(
                    icon: Icons.file_present_rounded,
                    label: 'REVISAR ARCHIVOS',
                    value: 'ESCANEAR APP',
                    onTap: () async {
                      // Show scanning dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const AlertDialog(
                          backgroundColor: Color(0xFF1A1D24),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF00E5FF)),
                              SizedBox(height: 20),
                              Text('ESCANEANDO INTEGRIDAD...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text('Verificando modelos y activos críticos', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                      );

                      // Simulate scanning work for visual feedback
                      await Future.delayed(const Duration(seconds: 2));
                      final ok = await settings.verifyAppIntegrity();

                      if (!mounted) return;
                      Navigator.pop(context); // Close scanning dialog

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('TODOS LOS ARCHIVOS ESTÁN CORRECTOS'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1D24),
                            title: const Text(
                              'ACTUALIZACIÓN NECESARIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Faltan algunos archivos del sistema o activos críticos. Descarga la última versión para corregirlo.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('CERRAR'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  url_launcher.launchUrl(
                                    Uri.parse(
                                      'https://github.com/iUnreallx/DashCore/releases',
                                    ),
                                    mode: url_launcher.LaunchMode.externalApplication,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00E5FF),
                                ),
                                child: const Text(
                                  'DESCARGAR',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatistics(
    BuildContext context,
    DashSettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min, // COMPACT
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'PERFIL DE CONDUCTOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  settings.driverLevel,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Ultra compact stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItemCompact(label: 'DIST.', value: '${settings.totalDistance.round()}KM', icon: Icons.map_rounded),
                  _StatItemCompact(label: 'MÁX.', value: '${settings.maxSpeed.round()}KMH', icon: Icons.speed_rounded),
                  _StatItemCompact(label: 'VIAJES', value: '${settings.totalTrips}', icon: Icons.route_rounded),
                  _StatItemCompact(label: 'TIEMPO', value: '${settings.totalDriveTime.inHours}H', icon: Icons.timer_rounded),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = '¡Mira mi nivel en DashCore! Soy ${settings.driverLevel} con ${settings.totalDistance.toStringAsFixed(1)} KM recorridos. #DashCore #OBD2';
                    Share.share(text);
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('COMPARTIR PERFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _GlowSwitch({
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        width: 54,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? activeColor.withOpacity(0.15) : Colors.black.withOpacity(0.6),
          border: Border.all(
            color: value ? activeColor.withOpacity(0.6) : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: value ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background track hint
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              left: value ? 28 : 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? activeColor : Colors.white.withOpacity(0.1),
                  boxShadow: value ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 2,
                      offset: const Offset(-1, -1),
                    )
                  ] : [],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: value
                    ? const Icon(Icons.power_settings_new_rounded, size: 14, color: Colors.black)
                    : const Icon(Icons.close_rounded, size: 12, color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatCircleButton extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isEnabled;

  const _RepeatCircleButton({
    required this.value,
    required this.onTap,
    required this.activeColor,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Permite clickear incluso si está "desactivado" para volver a activar
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.2),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
            child: Text(value),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? activeColor.withOpacity(0.12) : Colors.black.withOpacity(0.4),
              border: Border.all(
                color: isEnabled ? activeColor.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.2),
                  blurRadius: 12,
                )
              ] : [],
            ),
            child: Icon(
              Icons.repeat_rounded,
              size: 14,
              color: isEnabled ? activeColor : Colors.white.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItemCompact extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItemCompact({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SettingsSliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: themeColor,
              ),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${value.round()}$suffix',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape:
                  const RoundSliderOverlayShape(
                overlayRadius: 14,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: themeColor,
              inactiveColor: Colors.white12,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool? isToggle;

  const _SettingsToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isToggle,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);

    final bool isActive =
        value.contains('ACTIVADO') ||
        value.contains('MODO GPS') ||
        value.contains('MODO OBD2');

    final bool effectiveIsToggle = isToggle ?? (
        label.contains('SALUDO') ||
        label.contains('MODO') ||
        label.contains('AHORRO') ||
        label.contains('ESPECIAL') ||
        label.contains('ADVANCED') ||
        label.contains('INDICADOR') ||
        label.contains('ANALÍTICA')
    );

    final bool isMultiOption = !effectiveIsToggle && (
        label.contains('DISEÑO') ||
        label.contains('UNIDAD') ||
        label.contains('IDIOMA') ||
        label.contains('VEHÍCULO') ||
        label.contains('SIMULADOR')
    );

    final Color currentAccent = (isActive || (isMultiOption && !value.contains('DESACTIVADO') && !value.contains('SIN SELECCIONAR')))
        ? themeColor : Colors.white24;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: currentAccent.withOpacity(0.2)),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: currentAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white38,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (effectiveIsToggle)
                  _GlowSwitch(
                    value: isActive,
                    onChanged: (_) => onTap(),
                    activeColor: themeColor,
                  )
                else if (isMultiOption)
                  _RepeatCircleButton(
                    value: value,
                    onTap: onTap,
                    activeColor: themeColor,
                    isEnabled: !value.contains('DESACTIVADO') && !value.contains('SIN SELECCIONAR'),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white12,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
