import 'package:flutter/material.dart';
import '../models/obd_data.dart';
import '../providers/dash_settings_provider.dart';
import '../services/alert_sound_service.dart';

class DashboardLimitAlerts extends StatefulWidget {
  final ObdData data;
  final DashSettingsProvider settings;
  const DashboardLimitAlerts({
    super.key,
    required this.data,
    required this.settings,
  });

  @override
  State<DashboardLimitAlerts> createState() => _DashboardLimitAlertsState();
}

class _DashboardLimitAlertsState extends State<DashboardLimitAlerts> {
  bool _startingSound = false;

  bool get _temperatureExceeded =>
      widget.settings.tempWarningEnabled &&
      widget.data.engineTemp >= widget.settings.tempAlertThreshold;

  String? get _selectedSound {
    try {
      return widget.settings.selectedAlertSoundPath;
    } on NoSuchMethodError {
      // Keeps lightweight test/fake settings objects compatible.
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSound());
  }

  @override
  void didUpdateWidget(covariant DashboardLimitAlerts oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSound();
  }

  Future<void> _syncSound() async {
    final audio = AlertSoundService.instance;
    final path = _selectedSound;
    if (!_temperatureExceeded) {
      if (audio.isPlaying) {
        await audio.stop(silenceSession: false);
        if (mounted) setState(() {});
      }
      return;
    }
    if (path == null || audio.isPlaying || audio.silencedUntilRestart || _startingSound) return;
    _startingSound = true;
    await audio.playTemperatureAlert(path);
    _startingSound = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final data = widget.data;
    final speed =
        settings.speedWarningEnabled &&
        data.speed >= settings.speedAlertThreshold;
    final temp = _temperatureExceeded;
    if (!speed && !temp) return const SizedBox.shrink();
    final audio = AlertSoundService.instance;
    return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [
                    if (speed)
                      '⚠ VELOCIDAD ${settings.displaySpeed(data.speed).round()} ${settings.speedUnitLabel} · LÍMITE ${settings.displaySpeedAlertThreshold.round()} ${settings.speedUnitLabel}',
                    if (temp)
                      '⚠ TEMPERATURA ${data.engineTemp} °C · LÍMITE ${settings.tempAlertThreshold.round()} °C',
                  ].join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (temp && audio.isPlaying) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await audio.stop();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('DETENER ALERTA'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }
}
