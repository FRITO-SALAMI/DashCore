import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/vehicle_model.dart';
import '../models/analytics_event.dart';
import 'supabase_service.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  bool _consentGranted = false;
  String? _consentVersion;
  DateTime? _consentTimestamp;

  final List<AnalyticsEvent> _offlineQueue = [];
  bool _isSyncing = false;

  String? _currentSessionId;

  /// Update consent status
  void updateConsent({
    required bool granted,
    String? version,
  }) {
    final bool previouslyGranted = _consentGranted;
    _consentGranted = granted;

    if (granted) {
      _consentVersion = version;
      _consentTimestamp = DateTime.now();

      // Solo registrar si antes no estaba concedido para evitar duplicados en la misma ejecución
      if (!previouslyGranted) {
        _syncConsentToSupabase(_supabase.auth.currentUser?.id);
      }

      _processQueue();
    } else {
      _offlineQueue.clear();
      _saveQueueToLocal();
    }
  }

  /// Call this when the app starts or user logs in
  Future<void> trackAppStart() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceData = await _getDeviceData();
      final now = DateTime.now().toUtc().toIso8601String();

      // Create new session ID
      _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      // Get location info if available and permitted
      Map<String, dynamic>? locationData;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            locationData = {
              'lat': position.latitude.toStringAsFixed(2),
              'lon': position.longitude.toStringAsFixed(2),
            };
          }
        }
      } catch (_) {}

      // Update app_users record
      final response = await _supabase
          .from('app_users')
          .select('session_count, first_start_at')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        await _supabase.from('app_users').insert({
          'id': user.id,
          'email': user.email,
          'display_name': user.userMetadata?['display_name'],
          'registered_at': user.createdAt,
          'first_start_at': now,
          'last_login_at': now,
          'session_count': 1,
          'device_model': deviceData['model'],
          'manufacturer': deviceData['manufacturer'],
          'android_version': deviceData['androidVersion'],
          'dashcore_version': packageInfo.version,
          'dashcore_build': int.tryParse(packageInfo.buildNumber) ?? SupabaseService.appBuild,
          'language_code': Platform.localeName.split('_').first,
          'country_code': Platform.localeName.contains('_') ? Platform.localeName.split('_').last : null,
          'timezone': DateTime.now().timeZoneName,
          'location_approx': locationData,
          'updated_at': now,
        });
      } else {
        final int currentSessions = response['session_count'] ?? 0;
        await _supabase.from('app_users').update({
          'last_login_at': now,
          'session_count': currentSessions + 1,
          'dashcore_version': packageInfo.version,
          'dashcore_build': int.tryParse(packageInfo.buildNumber) ?? SupabaseService.appBuild,
          'timezone': DateTime.now().timeZoneName,
          'location_approx': locationData,
          'updated_at': now,
        }).eq('id', user.id);
      }
      
      // Register user session
      await _registerSession(user.id, packageInfo, deviceData);

      logEvent('app_session', data: {
        'session_id': _currentSessionId,
        'session_type': 'start',
      });

      if (_consentGranted) {
        await _syncConsentToSupabase(user.id);
      }

      await _loadQueueFromLocal();
      _processQueue();
    } catch (e) {
      debugPrint('Analytics Error (trackAppStart): $e');
    }
  }

  Future<void> _registerSession(String userId, PackageInfo packageInfo, Map<String, dynamic> deviceData) async {
    if (_currentSessionId == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('user_sessions').insert({
        'user_id': userId,
        'session_id': _currentSessionId,
        'started_at': now,
        'last_seen_at': now,
        'device_info': deviceData,
        'platform': defaultTargetPlatform.name,
        'app_version': packageInfo.version,
      });
    } catch (e) {
      debugPrint('Error registering session: $e');
    }
  }

  Future<void> updateSessionActivity() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _currentSessionId == null || !_consentGranted) return;

    try {
      await _supabase.from('user_sessions').update({
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId).eq('session_id', _currentSessionId!);
    } catch (_) {}
  }

  Future<void> _syncConsentToSupabase(String? userId) async {
    if (userId == null || !_consentGranted) return;

    try {
      await _supabase.from('consent_records').insert({
        'user_id': userId,
        'accepted': true,
        'version': _consentVersion ?? '1.0',
        'platform': defaultTargetPlatform.name,
        'app_version': (await PackageInfo.fromPlatform()).version,
        'timestamp': (_consentTimestamp ?? DateTime.now()).toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error syncing consent: $e');
    }
  }

  /// Explicitly track new registration
  Future<void> trackUserRegistration(User user) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('app_users').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'],
        'registered_at': now,
        'updated_at': now,
      });
      logEvent('signup_completed');
    } catch (e) {
      debugPrint('Analytics Error (trackUserRegistration): $e');
    }
  }

  /// Update vehicle information when selected
  Future<void> updateVehicleInfo(Vehicle vehicle) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('app_users').update({
        'vehicle_brand': vehicle.brand,
        'vehicle_model': vehicle.name,
        'vehicle_year': vehicle.year,
        'vehicle_engine': vehicle.engine,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);
      
      logEvent('vehicle_changed', data: {
        'vehicle_id': vehicle.id,
        'brand': vehicle.brand,
        'model': vehicle.name,
        'year': vehicle.year,
        'engine': vehicle.engine,
      });
    } catch (e) {
      debugPrint('Analytics Error (updateVehicleInfo): $e');
    }
  }

  /// Generic event logging
  Future<void> logEvent(String eventName, {Map<String, dynamic>? data}) async {
    if (!_consentGranted && eventName != 'consent_updated') return;

    final user = _supabase.auth.currentUser;
    final event = AnalyticsEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      eventName: eventName,
      data: data,
      createdAt: DateTime.now(),
      userId: user?.id,
    );

    _offlineQueue.add(event);
    await _saveQueueToLocal();
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isSyncing || _offlineQueue.isEmpty) return;
    _isSyncing = true;

    final List<AnalyticsEvent> toProcess = List.from(_offlineQueue);

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // Batch insert events
      await _supabase.from('app_events').insert(
        toProcess.map((event) => {
          'user_id': event.userId,
          'event_name': event.eventName,
          'event_data': event.data,
          'app_version': packageInfo.version,
          'platform': defaultTargetPlatform.name,
          'created_at': event.createdAt.toUtc().toIso8601String(),
        }).toList()
      );

      _offlineQueue.removeWhere((e) => toProcess.contains(e));
      await _saveQueueToLocal();
    } catch (e) {
      debugPrint('Error processing analytics queue: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _saveQueueToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encoded = _offlineQueue.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('analytics_offline_queue', encoded);
    } catch (e) {
      debugPrint('Error saving analytics queue: $e');
    }
  }

  Future<void> _loadQueueFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encoded = prefs.getStringList('analytics_offline_queue');
      if (encoded != null) {
        _offlineQueue.clear();
        _offlineQueue.addAll(encoded.map((s) => AnalyticsEvent.fromMap(jsonDecode(s))));
      }
    } catch (e) {
      debugPrint('Error loading analytics queue: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceData() async {
    if (kIsWeb) return {'type': 'web'};

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await _deviceInfo.androidInfo;
      return {
        'type': 'android',
        'manufacturer': info.manufacturer,
        'model': info.model,
        'brand': info.brand,
        'androidVersion': info.version.release,
        'sdkInt': info.version.sdkInt,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }
    
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        'type': 'ios',
        'model': info.model,
        'systemVersion': info.systemVersion,
        'name': info.name,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }

    return {'type': defaultTargetPlatform.name};
  }
}

