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
    if (_currentTrack == null || _currentTrack!.title == null || _currentTrack!.title!.isEmpty) {
      return 'Sin reproducción';
    }
    return _currentTrack!.title!;
  }

  String get artistName {
    if (_currentTrack == null || _currentTrack!.artist == null || _currentTrack!.artist!.isEmpty) {
      return '—';
    }
    return _currentTrack!.artist!;
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
        await requestPermissions();
      }

      await NowPlaying.instance.start(resolveImages: true);

      _subscription?.cancel();
      _subscription = NowPlaying.instance.stream.listen((track) {
        _updateTrack(track);
      });
      
      // Force immediate fetch with retries
      _fetchCurrentTrack();

    } catch (e) {
      debugPrint('Error iniciando NowPlaying: $e');
    }
  }

  Future<void> _fetchCurrentTrack() async {
    for (int i = 0; i < 3; i++) {
      final current = NowPlaying.instance.track;
      if (current != null && current.title != null) {
        _updateTrack(current);
        break;
      }
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
    }
  }

  void _updateTrack(NowPlayingTrack track) {
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

  void playPause() {
    platform.invokeMethod('mediaControl', {'command': 'playPause'});
  }

  void next() {
    platform.invokeMethod('mediaControl', {'command': 'next'});
  }

  void previous() {
    platform.invokeMethod('mediaControl', {'command': 'previous'});
  }
}
