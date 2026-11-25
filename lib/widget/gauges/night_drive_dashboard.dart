import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../../providers/music_provider.dart';
import '../../screens/settings_screen.dart';
import '../display_units.dart';
import '../tutorial/tutorial_keys.dart';
import '../vehicle_stage.dart';
import '../../screens/car_screen.dart';

/// Native implementation of the supplied cockpit reference.
class NightDriveDashboard extends StatelessWidget {
  const NightDriveDashboard({
    super.key,
    required this.data,
    required this.settings,
    required this.sourceLabel,
    this.preview = false,
  });
  final ObdData data;
  final DashSettingsProvider settings;
  final String sourceLabel;
  final bool preview;
  static const cyan = Color(0xFF00D5FF);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF040C13),
    child: LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1120,
          height: 500,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'D',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 34,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'DashCore',
                      style: TextStyle(
                        color: Color(0xFFF2F7FC),
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(width: 1, height: 25, color: Colors.white24),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cyan,
                              Color(0xFF6151DA),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Text(
                      sourceLabel,
                      style: const TextStyle(
                        color: Color(0xFF9FAFBC),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 24),
                    if (preview)
                      const Text(
                        '8:45',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const DashboardClock(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Expanded(
                              child: RepaintBoundary(child: _vehicle(context)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: KeyedSubtree(
                                    key: preview
                                        ? null
                                        : TutorialKeys.speedGaugeKey,
                                    child: _metric(
                                      Icons.speed_rounded,
                                      '${settings.displaySpeed(data.speed).round()}',
                                      settings.speedUnitLabel,
                                      'Velocidad',
                                      primary: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: KeyedSubtree(
                                    key: preview
                                        ? null
                                        : TutorialKeys.temperatureGaugeKey,
                                    child: _metric(
                                      Icons.thermostat_rounded,
                                      '${settings.convertTemp(data.engineTemp).round()}',
                                      settings.tempUnit ==
                                              TemperatureUnit.celsius
                                          ? '°C'
                                          : '°F',
                                      'Temp. motor',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: KeyedSubtree(
                                    key: preview
                                        ? null
                                        : TutorialKeys.voltageGaugeKey,
                                    child: _metric(
                                      Icons.battery_charging_full_rounded,
                                      data.voltage.toStringAsFixed(1),
                                      'V',
                                      'Voltaje batería',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 400,
                              child: _NightMusicCard(preview: preview),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF07131D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF153243)),
                  ),
                  child: Row(
                    children: [
                      _nav(Icons.home_rounded, 'Inicio', () {}, active: true),
                      _divider(),
                      _nav(
                        Icons.music_note_rounded,
                        'Música',
                        () => showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: const Color(0xFF07111D),
                          builder: (_) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: _NightMusicCard(),
                          ),
                        ),
                      ),
                      _divider(),
                      _nav(Icons.phone_outlined, 'Teléfono', () async {
                        bool opened = false;
                        try {
                          opened = await launchUrl(
                            Uri.parse('tel:'),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {}
                        if (!opened && context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Este dispositivo no tiene una app de teléfono.',
                              ),
                            ),
                          );
                      }),
                      _divider(),
                      _nav(
                        Icons.settings_outlined,
                        'Ajustes',
                        () => showSettingsSheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _vehicle(BuildContext context) => preview
      ? Image.asset(
          'assets/images/png/night_drive_car.png',
          fit: BoxFit.contain,
          cacheWidth: 480,
        )
      : VehicleStage(
          vehicle: settings.selectedVehicle,
          modelPath: settings.modelPath,
          reduceMotion: settings.reduceMotion,
          onChangeVehicle: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (routeContext) =>
                  CarScreen(onBack: () => Navigator.of(routeContext).pop()),
            ),
          ),
        );

  Widget _metric(
    IconData icon,
    String value,
    String unit,
    String label, {
    bool primary = false,
  }) => Container(
    height: 116,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: primary ? const Color(0xFF092635) : const Color(0xFF0A1924),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: primary ? cyan : const Color(0xFF2A4859)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: cyan, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB8CEDB), fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: primary ? 82 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFFB8CEDB),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _divider() =>
      Container(width: 1, height: 34, color: const Color(0xFF365264));
  Widget _nav(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: active
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF075071), Color(0xFF082235)],
                    )
                  : null,
              border: active ? Border.all(color: cyan) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: active ? cyan : Colors.white70, size: 27),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NightMusicCard extends StatefulWidget {
  const _NightMusicCard({this.preview = false});
  final bool preview;

  @override
  State<_NightMusicCard> createState() => _NightMusicCardState();
}

class _NightMusicCardState extends State<_NightMusicCard> {
  MusicProvider? _progressProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = !widget.preview && (ModalRoute.isCurrentOf(context) ?? true);
    final provider = visible ? context.read<MusicProvider>() : null;
    if (identical(provider, _progressProvider)) return;
    _progressProvider?.hideProgress();
    _progressProvider = provider;
    provider?.showProgress();
  }

  @override
  void dispose() {
    _progressProvider?.hideProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.preview
      ? _card(null)
      : Consumer<MusicProvider>(builder: (context, music, _) => _card(music));
  Widget _card(MusicProvider? music) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF69599D)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF142334), Color(0xFF10121F), Color(0xFF26123F)],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 86,
                height: 86,
                child: music?.nativeArtwork == null
                    ? const ColoredBox(
                        color: Color(0xFF322568),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFFD2BAFF),
                          size: 40,
                        ),
                      )
                    : Image.memory(
                        music!.nativeArtwork!,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.music_note_rounded),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music?.trackTitle ?? 'TU MÚSICA',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    music?.artistName ?? 'DashCore Audio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9EAFBD),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      24,
                      (i) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: (music?.hasActiveSession ?? true)
                                ? 5 + (i * 7 % 17).toDouble()
                                : 3,
                            color: Color.lerp(
                              NightDriveDashboard.cyan,
                              const Color(0xFFC94AFF),
                              i / 23,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: music?.progress ?? .42,
            minHeight: 4,
            backgroundColor: const Color(0xFF435162),
            color: NightDriveDashboard.cyan,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _time(music?.position ?? const Duration(minutes: 1, seconds: 24)),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              _time(music?.duration ?? const Duration(minutes: 3, seconds: 20)),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Anterior',
              onPressed: music?.previous,
              icon: const Icon(
                Icons.skip_previous_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 22),
            IconButton.filledTonal(
              tooltip: (music?.isPlaying ?? false) ? 'Pausar' : 'Reproducir',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF16344D),
                side: const BorderSide(color: NightDriveDashboard.cyan),
              ),
              onPressed: music?.playPause,
              icon: Icon(
                (music?.isPlaying ?? false)
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 22),
            IconButton(
              tooltip: 'Siguiente',
              onPressed: music?.next,
              icon: const Icon(
                Icons.skip_next_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  static String _time(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Lightweight, faithful store thumbnail: no GLB, clock or active music session.
class NightDrivePreview extends StatelessWidget {
  const NightDrivePreview({super.key, required this.settings});
  final DashSettingsProvider settings;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: NightDriveDashboard(
      data: const ObdData(speed: 86, rpm: 0, engineTemp: 89, voltage: 13.8),
      settings: settings,
      sourceLabel: 'VISTA PREVIA',
      preview: true,
    ),
  );
}
