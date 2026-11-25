import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/gadget_config.dart';
import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../display_units.dart';
import '../dashboard_background.dart';
import '../editable_gadget_wrapper.dart';

/// YouTube remains inside this dedicated style. The WebView is destroyed when
/// the user changes style, so it never competes with a GLB renderer.
class PremiumDashboard extends StatefulWidget {
  const PremiumDashboard({
    super.key,
    required this.data,
    required this.fuelLevel,
  });

  final ObdData data;
  final double fuelLevel;

  @override
  State<PremiumDashboard> createState() => _PremiumDashboardState();
}

class _PremiumDashboardState extends State<PremiumDashboard> {
  late final WebViewController _youtube;
  int _loading = 0;

  @override
  void initState() {
    super.initState();
    _youtube = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080D14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _loading = value);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            return uri.scheme == 'http' || uri.scheme == 'https'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com/@DashcoreTeam/videos'));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final accent = settings.accentColor;
    return Stack(
      children: [
        DashboardBackground(
          backgroundImage: settings.backgroundImage,
          isAssetBackground: settings.isAssetBackground,
          opacity: .22,
        ),
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.data.speed}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SpeedUnitLabel(
                        style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _metric(
                            Icons.thermostat_rounded,
                            '${widget.data.engineTemp}°C',
                            accent,
                          ),
                          const SizedBox(width: 35),
                          _metric(
                            Icons.bolt_rounded,
                            '${widget.data.voltage.toStringAsFixed(1)}V',
                            Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    width: double.infinity,
                    height: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF080D14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: WebViewWidget(controller: _youtube),
                        ),
                        if (_loading < 100)
                          LinearProgressIndicator(
                            value: _loading == 0 ? null : _loading / 100,
                            color: Colors.redAccent,
                            backgroundColor: Colors.transparent,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String value, Color color) => Container(
    width: 132,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xCC080D14),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(.45), width: 1.5),
      boxShadow: [BoxShadow(color: color.withOpacity(.16), blurRadius: 18)],
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

/// Video is isolated in this dashboard so its decoder never competes with a
/// GLB renderer or an animated background on low-memory/32-bit devices.
class Mp4Dashboard extends StatefulWidget {
  const Mp4Dashboard({super.key, required this.data, required this.fuelLevel});

  final ObdData data;
  final double fuelLevel;

  @override
  State<Mp4Dashboard> createState() => _Mp4DashboardState();
}

class _Mp4DashboardState extends State<Mp4Dashboard> {
  static const _maxLoopDuration = Duration(seconds: 30);
  VideoPlayerController? _video;
  String? _loadedPath;
  String? _videoError;
  int _videoGeneration = 0;
  Future<void> _videoWork = Future.value();
  bool _restartingVideo = false;

  final Map<String, GadgetConfig> _gadgets = {
    'speed': GadgetConfig(
      id: 'speed',
      label: 'VELOCIDAD',
      relativeX: .03,
      relativeY: .08,
      relativeWidth: .30,
      relativeHeight: .48,
    ),
    'sensors': GadgetConfig(
      id: 'sensors',
      label: 'TEMP / VOLT',
      relativeX: .03,
      relativeY: .60,
      relativeWidth: .30,
      relativeHeight: .25,
    ),
    'video': GadgetConfig(
      id: 'video',
      label: 'VIDEO',
      relativeX: .37,
      relativeY: .06,
      relativeWidth: .60,
      relativeHeight: .82,
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<DashSettingsProvider>(context);
    final path = settings.isAppActive ? settings.selectedVideoPath : null;
    if (path == _loadedPath) return;
    _loadedPath = path;
    final generation = ++_videoGeneration;
    _videoWork = _videoWork.then((_) => _loadVideo(path, generation));
  }

  bool _current(int generation) => mounted && generation == _videoGeneration;

  Future<void> _loadVideo(String? path, int generation) async {
    if (!_current(generation)) return;
    final previous = _video;
    if (previous != null) {
      previous.removeListener(_limitPlayback);
      setState(() => _video = null);
    }
    VideoPlayerController? pending;
    try {
      await previous?.dispose();
      if (!_current(generation)) return;
      if (path == null || path.isEmpty || !await File(path).exists()) {
        if (_current(generation)) {
          setState(() => _videoError = 'SELECCIONA UN VIDEO EN LA TIENDA');
        }
        return;
      }
      if (!_current(generation)) return;
      final controller = VideoPlayerController.file(
        File(path),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      pending = controller;
      await controller.initialize().timeout(const Duration(seconds: 8));
      if (!_current(generation)) return;
      await controller.setVolume(0);
      await controller.setLooping(false);
      if (!_current(generation)) return;
      await controller.play();
      if (!_current(generation)) return;
      controller.addListener(_limitPlayback);
      setState(() {
        _video = controller;
        _videoError = null;
      });
      pending = null;
    } catch (_) {
      if (_current(generation)) {
        setState(() => _videoError = 'MP4 NO COMPATIBLE. USA H.264 · 720P');
      }
    } finally {
      try {
        await pending?.dispose();
      } catch (_) {}
    }
  }

  Future<void> _limitPlayback() async {
    final controller = _video;
    if (_restartingVideo || controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration < _maxLoopDuration
        ? controller.value.duration
        : _maxLoopDuration;
    if (duration > Duration.zero && controller.value.position >= duration) {
      _restartingVideo = true;
      try {
        await controller.seekTo(Duration.zero);
        if (mounted && identical(_video, controller)) await controller.play();
      } catch (_) {
        // The player can be disposed while a seek is in flight.
      } finally {
        _restartingVideo = false;
      }
    }
  }

  @override
  void dispose() {
    _videoGeneration++;
    _video?.removeListener(_limitPlayback);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final accent = settings.accentColor;
    return ColoredBox(
      color: const Color(0xFF020408),
      child: LayoutBuilder(
        builder: (context, bounds) => Stack(
          children: _gadgets.values.map((config) {
            return Positioned(
              left: config.relativeX * bounds.maxWidth,
              top: config.relativeY * bounds.maxHeight,
              width: config.relativeWidth * bounds.maxWidth,
              height: config.relativeHeight * bounds.maxHeight,
              child: EditableGadgetWrapper(
                config: config,
                isEditMode: settings.isEditMode,
                parentSize: Size(bounds.maxWidth, bounds.maxHeight),
                onTapEdit: () {},
                onConfigChanged: (updated) =>
                    setState(() => _gadgets[updated.id] = updated),
                child: _panel(config.id, accent, settings),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _panel(String id, Color accent, DashSettingsProvider settings) {
    switch (id) {
      case 'speed':
        return _glass(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.data.speed}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SpeedUnitLabel(
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
        );
      case 'sensors':
        return _glass(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metric(
                Icons.thermostat_rounded,
                '${widget.data.engineTemp}°C',
                'TEMP',
                accent,
              ),
              _metric(
                Icons.bolt_rounded,
                '${widget.data.voltage.toStringAsFixed(1)}V',
                'VOLT',
                Colors.orangeAccent,
              ),
            ],
          ),
        );
      default:
        return _videoPanel(accent, settings);
    }
  }

  Widget _videoPanel(Color accent, DashSettingsProvider settings) {
    final controller = _video;
    return _glass(
      padding: 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            Center(
              child: Text(
                _videoError ?? 'PREPARANDO VIDEO…',
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: Row(
              children: [
                IconButton(
                  onPressed: controller == null
                      ? null
                      : () => setState(() {
                          controller.value.isPlaying
                              ? controller.pause()
                              : controller.play();
                        }),
                  icon: Icon(
                    controller?.value.isPlaying == true
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                const Text(
                  'CICLO OPTIMIZADO · MÁX. 30 S',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openYoutubeLite,
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('YOUTUBE LITE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openYoutubeLite() => url_launcher.launchUrl(
    Uri.parse('https://m.youtube.com/@DashcoreTeam'),
    mode: url_launcher.LaunchMode.externalApplication,
  );

  Widget _glass({required Widget child, double padding = 12}) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: const Color(0xFF080D14),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
    ),
    child: child,
  );

  Widget _metric(IconData icon, String value, String label, Color color) =>
      FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      );
}
