import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowplaying/nowplaying.dart';

/// MusicProvider — reescrito para usar UNA sola fuente de verdad:
/// el canal nativo custom (io.dashcore.app/media_updates).
///
/// El paquete `nowplaying` se usa AHORA SOLO para gestión de permisos
/// (isEnabled / requestPermissions), no para leer el track. Antes,
/// el stream del paquete y el canal nativo escribían el mismo estado
/// (_isPlaying, _progress, etc.) sin coordinación, causando parpadeos
/// y estados congelados ("no aparece nada" / "no deja pausar").
class MusicProvider extends ChangeNotifier {
  static const platform = MethodChannel('io.dashcore.app/launcher');
  static const mediaChannel = MethodChannel('io.dashcore.app/media_updates');

  String? _title;
  String? _artist;
  Uint8List? _artwork;
  bool _isPlaying = false;
  double _progress = 0.0;
  bool _hasActiveSession = false;

  Timer? _progressTimer;

  bool get hasActiveSession => _hasActiveSession;
  bool get isPlaying => _isPlaying;
  double get progress => _progress;
  Uint8List? get nativeArtwork => _artwork;

  String get trackTitle {
    if (_hasActiveSession && _title != null && _title!.isNotEmpty) return _title!;
    return 'SIN MÚSICA';
  }

  String get artistName {
    if (_hasActiveSession && _artist != null && _artist!.isNotEmpty) return _artist!;
    return 'DashCore Audio';
  }

  MusicProvider() {
    _initNativeMediaListener();
    _checkPermissionStatus();
  }

  void _initNativeMediaListener() {
    mediaChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMetadataChanged':
          _updateFromNativeMetadata(call.arguments);
          break;
        case 'onPlaybackStateChanged':
          _updateFromNativePlaybackState(call.arguments);
          break;
      }
    });
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final bool enabled = await NowPlaying.instance.isEnabled();
      if (!enabled) {
        debugPrint('[MUSIC] Notification access aún no concedido.');
      }
    } catch (e) {
      debugPrint('[MUSIC] Error verificando permiso NowPlaying: $e');
    }
  }

  void _updateFromNativeMetadata(dynamic args) {
    if (args is! Map) return;

    final title = args['title'] as String?;
    final artist = args['artist'] as String?;
    final artworkBase64 = args['artwork'] as String?;

    final nothingPlaying = (title == null || title.isEmpty || title == 'null');

    // FIX: antes esto se ignoraba silenciosamente y el estado quedaba
    // congelado. Ahora, si el nativo reporta que no hay nada sonando,
    // se resetea explícitamente el estado y se notifica a la UI.
    if (nothingPlaying) {
      _resetToIdle();
      return;
    }

    _title = title;
    _artist = (artist == null || artist.isEmpty || artist == 'null') ? null : artist;
    _hasActiveSession = true;

    if (artworkBase64 != null) {
      try {
        _artwork = base64Decode(artworkBase64);
      } catch (e) {
        _artwork = null;
      }
    } else {
      _artwork = null;
    }

    debugPrint('[MUSIC-NATIVE] Metadata: $_title by $_artist');
    notifyListeners();
  }

  void _updateFromNativePlaybackState(dynamic args) {
    if (args is! Map) return;

    final isPlaying = args['isPlaying'] as bool? ?? false;
    final duration = (args['duration'] as num?)?.toDouble() ?? 0.0;
    final position = (args['position'] as num?)?.toDouble() ?? 0.0;

    _isPlaying = isPlaying;
    _progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;

    _startProgressTimer();
    notifyListeners();
  }

  void _resetToIdle() {
    _title = null;
    _artist = null;
    _artwork = null;
    _isPlaying = false;
    _progress = 0.0;
    _hasActiveSession = false;
    _progressTimer?.cancel();
    notifyListeners();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    if (!_isPlaying) return;
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  Future<void> requestPermissions() async {
    // 1. Acceso a notificaciones (implementación custom para datos en vivo)
    try {
      final bool hasAccess =
          await platform.invokeMethod<bool>('checkNotificationAccess') ?? false;
      if (!hasAccess) {
        await platform.invokeMethod('openNotificationAccessSettings');
        // NOTA: Android no siempre re-vincula el NotificationListenerService
        // automáticamente tras conceder el permiso desde Ajustes en todas
        // las ROMs. Si tras conceder el permiso sigue sin llegar nada,
        // hay que forzar el rebind nativo (toggleNotificationListenerService)
        // o pedirle al usuario que reabra la app una vez.
      }
    } catch (e) {
      debugPrint('[MUSIC] Error checking notification access: $e');
    }

    // 2. Permisos propios del paquete NowPlaying (solo gestión de permiso)
    try {
      final bool enabled = await NowPlaying.instance.isEnabled();
      if (!enabled) {
        await NowPlaying.instance.requestPermissions();
      }
    } catch (e) {
      debugPrint('[MUSIC] Error requesting NowPlaying permission: $e');
    }
  }

  Future<void> refresh() async {
    try {
      await platform.invokeMethod('refreshMediaSession');
    } catch (e) {
      debugPrint('[MUSIC] Error refreshing media session: $e');
    }
  }

  void playPause() async {
    final wasPlaying = _isPlaying;
    // Update optimista para que la UI responda al instante
    _isPlaying = !_isPlaying;
    notifyListeners();

    try {
      await platform.invokeMethod('mediaControl', {'command': 'playPause'});
      // El estado real confirmado llega vía onPlaybackStateChanged desde
      // el nativo — no hace falta (ni conviene) volver a consultar aquí.
    } catch (e) {
      debugPrint('[MUSIC] Error media control: $e');
      // Revertir el update optimista si el comando nativo falló
      _isPlaying = wasPlaying;
      notifyListeners();
    }
  }

  void next() async {
    try {
      await platform.invokeMethod('mediaControl', {'command': 'next'});
      _progress = 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('[MUSIC] Error media next: $e');
    }
  }

  void previous() async {
    try {
      await platform.invokeMethod('mediaControl', {'command': 'previous'});
      _progress = 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('[MUSIC] Error media previous: $e');
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}
