import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../dashboard_brand_mark.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/gadget_config.dart';
import '../music_hub.dart';
import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../display_units.dart';
import '../editable_gadget_wrapper.dart';

class PremiumDashboard extends StatelessWidget {
  const PremiumDashboard({
    super.key,
    required this.data,
    required this.fuelLevel,
  });

  final ObdData data;
  final double fuelLevel;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final accent = settings.accentColor;
    return ColoredBox(
      color: const Color(0xFF050E15),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, size) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 245,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const DashboardBrandMark(width: 62),
                          const SizedBox(height: 8),
                          Text(
                            '${data.speed}',
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1,
                              fontSize: 96,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SpeedUnitLabel(
                            style: TextStyle(
                              color: accent,
                              fontSize: 17,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _roadReading(
                                Icons.thermostat_outlined,
                                '${settings.convertTemp(data.engineTemp).round()} ${settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F'}',
                                accent,
                              ),
                              _roadReading(
                                Icons.bolt_outlined,
                                '${data.voltage.toStringAsFixed(1)} V',
                                accent,
                              ),
                              const MusicHub(compact: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: .28)),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  child: _LocalRoadVideo(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roadReading(IconData icon, String value, Color accent) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: accent, size: 16),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _LocalRoadVideo extends StatefulWidget {
  const _LocalRoadVideo();

  @override
  State<_LocalRoadVideo> createState() => _LocalRoadVideoState();
}

class _LocalRoadVideoState extends State<_LocalRoadVideo> {
  static const _poster = 'assets/videos/road_poster.jpg';
  VideoPlayerController? _controller;
  late final AppLifecycleListener _lifecycle;
  bool _play = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _syncPlayback());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<DashSettingsProvider>();
    _play =
        Platform.isAndroid &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        settings.isAppActive &&
        !settings.reduceOrbitMotion &&
        !MediaQuery.disableAnimationsOf(context);
    _syncPlayback();
  }

  void _syncPlayback() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (!_play || (state != null && state != AppLifecycleState.resumed)) {
      final previous = _controller;
      _controller = null;
      if (_ready) setState(() => _ready = false);
      if (previous != null) unawaited(previous.dispose());
    } else if (_controller == null) {
      final controller = VideoPlayerController.asset(
        'assets/videos/road_loop.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      unawaited(_prepare(controller));
    }
  }

  Future<void> _prepare(VideoPlayerController controller) async {
    try {
      await controller.initialize().timeout(const Duration(seconds: 5));
      if (!mounted || !identical(controller, _controller)) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted || !identical(controller, _controller)) return;
      await controller.play();
      if (mounted && identical(controller, _controller))
        setState(() => _ready = true);
    } catch (_) {
      if (!identical(controller, _controller)) return;
      _controller = null;
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final previous = _controller;
    _controller = null;
    if (previous != null) unawaited(previous.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) {
      return Image.asset(
        _poster,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox.fromSize(
        size: controller.value.size,
        child: VideoPlayer(controller),
      ),
    );
  }
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
    if (_restartingVideo ||
        controller == null ||
        !controller.value.isInitialized)
      return;
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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
