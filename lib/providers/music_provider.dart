import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';

class MusicProvider extends ChangeNotifier {
  static const platform = MethodChannel('io.dashcore.app/launcher');

  NowPlayingTrack? _currentTrack;
  bool _isPlaying = false;
  double _progress = 0.0;
  StreamSubscription<NowPlayingTrack>? _subscription;
  Timer? _progressTimer;

  NowPlayingTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  double get progress => _progress;

  String get trackTitle {
    final title = _currentTrack?.title;
    if (title == null || title.isEmpty || title == 'null' || title == 'Unknown') {
      return _isPlaying ? 'REPRODUCIENDO...' : 'DashCore Music';
    }
    return title;
  }

  String get artistName {
    final artist = _currentTrack?.artist;
    if (artist == null || artist.isEmpty || artist == 'null' || artist == 'Unknown') {
      return 'DashCore Audio';
    }
    return artist;
  }

  MusicProvider() {
    _init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final bool enabled = await NowPlaying.instance.isEnabled();
      if (!enabled) {
        // La petición de permisos se hace desde la UI usualmente, pero aseguramos aquí
        debugPrint('[MUSIC] NowPlaying not enabled, requesting...');
      }

      await NowPlaying.instance.start(resolveImages: true);

      _subscription?.cancel();
      _subscription = NowPlaying.instance.stream.listen((track) {
        _updateTrack(track);
      });
      
      // Bucle de refresco agresivo al inicio
      _fetchCurrentTrack();
      
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_currentTrack == null || _currentTrack!.title == null) {
          _fetchCurrentTrack();
        } else {
          timer.cancel();
        }
      });

    } catch (e) {
      debugPrint('Error iniciando NowPlaying: $e');
    }
  }

  Future<void> _fetchCurrentTrack() async {
    try {
      final current = NowPlaying.instance.track;
      if (current != null) {
        _updateTrack(current);
      }
    } catch (e) {
      debugPrint('Error fetching track: $e');
    }
  }

  void _updateTrack(NowPlayingTrack track) {
    // Si el track viene vacío o nulo, no sobreescribimos con 'Unknown' si ya teníamos algo
    if (track.title == null || track.title!.isEmpty || track.title == 'null') {
      if (_currentTrack != null) return;
    }

    debugPrint('[MUSIC] Track update: ${track.title} by ${track.artist} (${track.state})');
    _currentTrack = track;
    _isPlaying = track.state == NowPlayingState.playing;

    if (track.duration.inMilliseconds > 0) {
      _progress = track.progress.inMilliseconds /
          track.duration.inMilliseconds;
      _progress = _progress.clamp(0.0, 1.0);
    } else {
      _progress = 0.0;
    }

    _startProgressTimer();
    notifyListeners();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();

    if (!_isPlaying) return;

    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        notifyListeners();
      },
    );
  }

  Future<void> requestPermissions() async {
    final bool enabled = await NowPlaying.instance.isEnabled();
    if (!enabled) {
      await NowPlaying.instance.requestPermissions();
      // Re-initialize after permission
      await Future.delayed(const Duration(seconds: 1));
      _init();
    }
  }

  void playPause() async {
    try {
      // Optimistic update for UI responsiveness
      _isPlaying = !_isPlaying;
      notifyListeners();

      await platform.invokeMethod('mediaControl', {'command': 'playPause'});

      // Delay and fetch to confirm real state
      Future.delayed(const Duration(milliseconds: 800), _fetchCurrentTrack);
    } catch (e) {
      debugPrint('Error media control: $e');
    }
  }

  void next() async {
    try {
      await platform.invokeMethod('mediaControl', {'command': 'next'});
      // Reset progress optimistically
      _progress = 0.0;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 1000), _fetchCurrentTrack);
    } catch (e) {
      debugPrint('Error media next: $e');
    }
  }

  void previous() async {
    try {
      await platform.invokeMethod('mediaControl', {'command': 'previous'});
      _progress = 0.0;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 1000), _fetchCurrentTrack);
    } catch (e) {
      debugPrint('Error media previous: $e');
    }
  }
}
