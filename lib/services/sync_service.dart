import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'diagnostic_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  // Lazy access keeps offline startup safe if initialization fails.
  SupabaseClient get _supabase => Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _currentSessionId;
  Timer? _heartbeatTimer;
  Timer? _announcementPollTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _announcementSubscription;
  final StreamController<Map<String, dynamic>> _announcementController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _rankingSyncController =
      StreamController<bool>.broadcast();
  String? _lastAnnouncementId;
  String? _lastAnnouncementRevision;

  Stream<Map<String, dynamic>> get announcements =>
      _announcementController.stream;
  Stream<bool> get rankingSyncChanges => _rankingSyncController.stream;
  void setRankingSyncing(bool value) => _rankingSyncController.add(value);
  bool _sleeping = false;
  bool _initialized = false;
  bool _refreshingAnnouncement = false;

  Future<void> setAccSleeping(bool sleeping) async {
    if (_sleeping == sleeping) return;
    _sleeping = sleeping;
    if (sleeping) {
      _heartbeatTimer?.cancel();

      await _announcementSubscription?.cancel();
      _announcementSubscription = null;
      _announcementPollTimer?.cancel();
      _supabase.realtime.disconnect();
      _supabase.auth.stopAutoRefresh();
    } else {
      _supabase.auth.startAutoRefresh();
      _setupAnnouncementListener();
      if (_currentSessionId != null) _startHeartbeat();
    }
  }

  /// Inicializa el servicio y configura listeners
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        _startSession(user);
        logEvent(
          'login',
          data: {'method': user.appMetadata['provider'] ?? 'email'},
        );
      } else if (event == AuthChangeEvent.signedOut) {
        _stopSession();
        logEvent('logout');
      } else if (event == AuthChangeEvent.initialSession && user != null) {
        _startSession(user);
      }
    });

    _setupAnnouncementListener();
  }

  // ======================================================================
  // GESTIÓN DE SESIÓN
  // ======================================================================

  Future<void> _startSession(User user) async {
    if (_sleeping) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceData = await _getDetailedDeviceData();
      final now = DateTime.now().toUtc().toIso8601String();

      // 1. Sincronizar app_users
      await _syncAppUser(user, packageInfo, deviceData);


      // 2. Crear user_sessions
      final session = await _supabase
          .from('user_sessions')
          .insert({
            'user_id': user.id,
            'started_at': now,
            'last_seen_at': now,
            'platform': defaultTargetPlatform.name,
            'device_info': deviceData,
          })
          .select('session_id')
          .single();
      _currentSessionId = session['session_id']?.toString();
      if (_currentSessionId == null) {
        throw StateError('Supabase no devolvió el id de la sesión');
      }

      // 3. Sincronizar user_devices
      await _syncUserDevice(user.id, packageInfo, deviceData);

      // 4. Iniciar Heartbeat
      _startHeartbeat();

      debugPrint('🚀 Sesión Sync activa: $_currentSessionId');
    } catch (e) {
      debugPrint('❌ Error iniciando sesión Sync: $e');
    }
  }

  void _stopSession() {
    _heartbeatTimer?.cancel();
    _currentSessionId = null;

  }

  void _startHeartbeat() {
    if (_sleeping) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 90), (
      timer,
    ) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || _currentSessionId == null) return;

      try {
        await _supabase
            .from('user_sessions')
            .update({'last_seen_at': DateTime.now().toUtc().toIso8601String()})
            .eq('session_id', _currentSessionId!)
            .eq('user_id', userId);
      } catch (_) {}
    });
  }

  // ======================================================================
  // SINCRONIZACIÓN DE DATOS
  // ======================================================================

  Future<void> _syncAppUser(
    User user,
    PackageInfo packageInfo,
    Map<String, dynamic> deviceData,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase.from('app_users').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': user.userMetadata?['display_name'],
      'last_login_at': now,
      'country_code': Platform.localeName.contains('_')
          ? Platform.localeName.split('_').last
          : null,
      'language_code': Platform.localeName.split('_').first,
      'timezone': DateTime.now().timeZoneName,
      'device_model': deviceData['model'],
      'manufacturer': deviceData['manufacturer'],
      'android_version': deviceData['os_version'],
      'dashcore_version': packageInfo.version,
      'dashcore_build': int.tryParse(packageInfo.buildNumber) ?? 0,
      'updated_at': now,
    }, onConflict: 'id');
  }

  Future<void> _syncUserDevice(
    String userId,
    PackageInfo packageInfo,
    Map<String, dynamic> deviceData,
  ) async {
    await _supabase.from('user_devices').upsert({
      'user_id': userId,
      'device_model': deviceData['model'],
      'manufacturer': deviceData['manufacturer'],
      'android_version': deviceData['os_version'],
      'architecture': deviceData['architecture'],
      'app_version': packageInfo.version,
      'app_version_code': int.tryParse(packageInfo.buildNumber) ?? 0,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      'metadata': deviceData,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<void> updateSelectedVehicle(String vehicleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase
          .from('app_users')
          .update({
            'vehicle_selected_id': vehicleId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } catch (_) {}
  }

  // ======================================================================
  // EVENTOS & ERRORES
  // ======================================================================

  Future<void> logEvent(String eventName, {Map<String, dynamic>? data}) async {
    // Version 2 keeps automatic diagnostics on the device only.
    DiagnosticService.log(eventName);
  }

  void logError(String exception, String stack) {
    logEvent(
      'error',
      data: {
        'exception': exception,
        'stack': stack.split('\n').take(5).join('\n'),
      },
    );
  }

  // ======================================================================
  // LIVE LOCATION
  // ======================================================================

  // ======================================================================
  // REALTIME ANNOUNCEMENTS
  // ======================================================================

  void _setupAnnouncementListener() {
    _announcementSubscription?.cancel();
    _announcementPollTimer?.cancel();
    _announcementSubscription = _supabase
        .from('app_announcements')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .listen((data) {
          if (data.isNotEmpty) {
            final latest = data.reduce((a, b) {
              final aDate =
                  DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                  DateTime(1970);
              final bDate =
                  DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                  DateTime(1970);
              return bDate.isAfter(aDate) ? b : a;
            });
            _publishAnnouncement(Map<String, dynamic>.from(latest));
          }
        }, onError: (Object error) {
          debugPrint('[ANNOUNCEMENTS] Realtime unavailable: $error');
        });
    // Realtime requires the table to be in Supabase's publication. Polling is
    // an intentional fallback for head units where that channel is unavailable.
    unawaited(refreshActiveAnnouncement());
    _announcementPollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshActiveAnnouncement(),
    );
  }

  Future<void> refreshActiveAnnouncement() async {
    if (_sleeping || _refreshingAnnouncement) return;
    _refreshingAnnouncement = true;
    try {
      final response = await _supabase.rpc('get_active_remote_announcement');
      if (response is Map) {
        _publishAnnouncement(Map<String, dynamic>.from(response));
      }
    } catch (error) {
      debugPrint('[ANNOUNCEMENTS] Poll failed: $error');
    } finally {
      _refreshingAnnouncement = false;
    }
  }

  void _publishAnnouncement(Map<String, dynamic> announcement) {
    final id = announcement['id']?.toString();
    if (id == null || id.isEmpty) return;
    final revision = '${announcement['updated_at'] ?? announcement['created_at'] ?? ''}';
    if (id == _lastAnnouncementId && revision == _lastAnnouncementRevision) {
      return;
    }
    _lastAnnouncementId = id;
    _lastAnnouncementRevision = revision;
    _announcementController.add(announcement);
  }

  // ======================================================================
  // CONSENTIMIENTO
  // ======================================================================

  Future<void> recordConsent({
    required bool accepted,
    required String version,
  }) async {
    try {
      // Offline startup can continue even if Supabase did not initialize.
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final packageInfo = await PackageInfo.fromPlatform();
      await _supabase.from('consent_records').insert({
        'user_id': userId,
        'accepted': accepted,
        'version': version,
        'platform': defaultTargetPlatform.name,
        'app_version': packageInfo.version,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

    } catch (e) {
      debugPrint('Error recording consent: $e');
    }
  }

  // ======================================================================
  // HELPERS
  // ======================================================================

  Future<Map<String, dynamic>> _getDetailedDeviceData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (kIsWeb) return {'type': 'web'};

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return {
        'type': 'android',
        'manufacturer': info.manufacturer,
        'model': info.model,
        'os_version': info.version.release,
        'sdk_int': info.version.sdkInt,
        'architecture': info.supportedAbis.first,
        'is_physical': info.isPhysicalDevice,
        'app_version': packageInfo.version,
      };
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        'type': 'ios',
        'manufacturer': 'Apple',
        'model': info.model,
        'os_version': info.systemVersion,
        'architecture': 'arm64',
        'is_physical': info.isPhysicalDevice,
        'app_version': packageInfo.version,
      };
    }
    return {'type': 'unknown'};
  }
}
