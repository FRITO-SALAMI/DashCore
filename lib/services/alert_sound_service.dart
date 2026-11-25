import 'package:flutter/services.dart';

class AlertSoundService {
  AlertSoundService._();
  static final AlertSoundService instance = AlertSoundService._();
  static const _channel = MethodChannel('io.dashcore.app/alert_audio');

  bool _playing = false;
  bool _silencedUntilRestart = false;

  bool get isPlaying => _playing;
  bool get silencedUntilRestart => _silencedUntilRestart;

  Future<bool> preview(String path) async {
    await stop(silenceSession: false);
    return await _play(path, loop: false);
  }

  Future<bool> playTemperatureAlert(String path) async {
    if (_silencedUntilRestart || _playing || path.isEmpty) return false;
    return _play(path, loop: true);
  }

  Future<bool> _play(String path, {required bool loop}) async {
    try {
      final ok = await _channel.invokeMethod<bool>('play', {
        'path': path,
        'loop': loop,
      }) ?? false;
      _playing = ok && loop;
      return ok;
    } catch (_) {
      _playing = false;
      return false;
    }
  }

  Future<void> stop({bool silenceSession = true}) async {
    try {
      await _channel.invokeMethod<void>('stop');
    } finally {
      _playing = false;
      if (silenceSession) _silencedUntilRestart = true;
    }
  }
}
