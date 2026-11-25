import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_service.dart';
import 'manual_vehicle_service.dart';
import '../core/backend_config.dart';

/// Implementación personalizada de LocalStorage usando flutter_secure_storage para cifrado.
/// Adaptada para la API de supabase_flutter 2.x
class SecureLocalStorage extends LocalStorage {
  final _storage = const FlutterSecureStorage();
  // Namespace sessions by project: tokens from the retired backend are invalid.
  static const _storageKey = 'supabase_auth_session_${BackendConfig.url}';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return null;
      // LocalStorage.accessToken expects the complete serialized session,
      // including the refresh token; the SDK decodes it itself.
      final data = json.decode(jsonStr);
      return data is Map && data['refresh_token'] is String ? jsonStr : null;
    } catch (e) {
      debugPrint('❌ Error obteniendo access_token: $e');
      return null;
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    return token != null;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: _storageKey, value: persistSessionString);
    } catch (e) {
      debugPrint('❌ Error persistiendo sesión: $e');
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('❌ Error eliminando sesión: $e');
    }
  }
}

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String supabaseUrl = BackendConfig.url;

  static const String supabasePublishableKey = BackendConfig.publishableKey;

  static const String resetPasswordRedirectUrl =
      'io.dashcore.app://login-callback/';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: SecureLocalStorage(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al inicializar Supabase: $e');
    }
  }

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn => currentUser != null;

  Future<List<Map<String, dynamic>>> getDashLeagueRanking() async {
    final supabase = client;
    if (supabase == null || currentUser == null) return const [];

    dynamic response;
    try {
      response = await supabase.rpc('get_dashleague_ranking_v3');
    } on PostgrestException catch (error) {
      // Keep older installations operational until the public-profile SQL is
      // deployed. The card still opens with the fields available in v2.
      if (error.code != '42883' && error.code != 'PGRST202') rethrow;
      response = await supabase.rpc('get_dashleague_ranking_v2');
    }
    if (response is! List) return const [];
    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> syncDrivingStats({
    required double totalDistance,
    required double maxSpeed,
  }) async {
    final supabase = client;
    if (supabase == null || currentUser == null) return null;

    final response = await supabase.rpc(
      'sync_my_driving_stats',
      params: {'new_total_distance': totalDistance, 'new_max_speed': maxSpeed},
    );
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) return Map<String, dynamic>.from(response);
    return null;
  }

  Future<bool> isUsernameAvailable(String candidate) async {
    final supabase = client;
    if (supabase == null || currentUser == null) return false;

    final response = await supabase.rpc(
      'username_available',
      params: {'candidate': candidate.trim()},
    );
    return response == true;
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) return null;

    final response = await supabase
        .from('profiles')
        .select('username, full_name, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  Future<User?> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final supabase = client;
    if (supabase == null) return null;
    final normalized = identifier.trim();
    if (normalized.contains('@')) {
      final result = await supabase.auth.signInWithPassword(
        email: normalized.toLowerCase(),
        password: password,
      );
      return result.user;
    }
    final response = await supabase.functions.invoke(
      'login-by-nickname',
      body: {'login_identifier': normalized, 'password': password},
    );
    if (response.status < 200 ||
        response.status >= 300 ||
        response.data is! Map) {
      throw const AuthException('Invalid login credentials');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final session = data['session'];
    if (session is! Map || session['refresh_token'] == null) {
      throw const AuthException('Invalid login credentials');
    }
    final result = await supabase.auth.setSession(
      session['refresh_token'].toString(),
    );
    return result.user;
  }

  Future<bool> currentProfileNeedsCompletion() async {
    if (currentUser == null) return false;
    try {
      final response = await client!.rpc('get_my_profile_completion');
      final row = response is List && response.isNotEmpty
          ? response.first
          : response;
      if (row is Map) return row['complete'] != true;
    } catch (_) {
      final metadata = currentUser?.userMetadata;
      return (metadata?['full_name']?.toString().trim().isEmpty ?? true) ||
          (metadata?['username']?.toString().trim().isEmpty ?? true);
    }
    return true;
  }

  Future<String> suggestAvailableUsername(String requested) async {
    final supabase = client;
    if (supabase == null || currentUser == null) return 'driver_2026';

    final response = await supabase.rpc(
      'suggest_available_username',
      params: {'candidate': requested.trim()},
    );
    return response?.toString() ?? 'driver_2026';
  }

  Future<String> uploadMyAvatar(File file) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) {
      throw StateError('Authentication required');
    }

    final rawExtension = file.path.split('.').last.toLowerCase();
    final extension = rawExtension == 'jpeg' ? 'jpeg' : rawExtension;
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(extension)) {
      throw const FormatException('Unsupported avatar format');
    }
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const FormatException('Unsupported avatar format'),
    };
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Avatar exceeds 5 MB');
    }

    final path = '${user.id}/avatar.$extension';
    await supabase.storage
        .from('avatars')
        .upload(
          path,
          file,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
    // The object path is intentionally stable, so add a version to prevent
    // Flutter/CDNs from continuing to display the previous avatar.
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> queueAvatarUpload(String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_avatar_upload', localPath);
  }

  Future<void> syncPendingAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('pending_avatar_upload');
    if (path == null || currentUser == null) return;
    final file = File(path);
    if (!await file.exists()) {
      await prefs.remove('pending_avatar_upload');
      return;
    }
    try {
      final url = await uploadMyAvatar(file);
      await updateMyAvatar(url);
      await prefs.remove('pending_avatar_upload');
    } catch (error) {
      debugPrint('Avatar pendiente; se reintentará después: $error');
    }
  }

  Future<void> updateMyProfile({
    required String username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final supabase = client;
    if (supabase == null || currentUser == null) {
      throw StateError('Authentication required');
    }

    await supabase.rpc(
      'update_my_profile',
      params: {
        'new_username': username.trim(),
        'new_full_name': fullName?.trim(),
        'new_avatar_url': avatarUrl,
      },
    );
    await supabase.auth.updateUser(
      UserAttributes(
        data: {
          'username': username.trim(),
          'display_name': username.trim(),
          if (fullName != null) 'full_name': fullName.trim(),
        },
      ),
    );
  }

  Future<void> updateMyAvatar(String avatarUrl) async {
    final supabase = client;
    if (supabase == null || currentUser == null) {
      throw StateError('Authentication required');
    }
    await supabase.rpc(
      'update_my_avatar',
      params: {'new_avatar_url': avatarUrl},
    );
    await supabase.auth.updateUser(
      UserAttributes(data: {'avatar_url': avatarUrl}),
    );
  }

  // ======================================================================
  // AUTENTICACIÓN & PERFIL
  // ======================================================================

  Future<void> resetPassword(String email) async {
    final supabase = client;
    if (supabase == null) return;

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: resetPasswordRedirectUrl,
      );
    } catch (e) {
      debugPrint('❌ Error enviando reset de password: $e');
      rethrow;
    }
  }

  Future<void> createUserProfile(User user) async {
    final supabase = client;
    if (supabase == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await supabase.from('user_settings').upsert({
        'user_id': user.id,
        'updated_at': now,
      }, onConflict: 'user_id');

      final countryCode = user.userMetadata?['country_code']?.toString();
      if (countryCode != null && countryCode.isNotEmpty) {
        await supabase.rpc(
          'set_my_country',
          params: {'p_country_code': countryCode},
        );
      }

      await SyncService.instance.logEvent('signup_completed');
    } catch (e) {
      debugPrint('❌ Error creando perfil de usuario: $e');
    }
  }

  Future<void> updateLastSeen() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // SyncService maneja el heartbeat automáticamente
    } catch (e) {
      debugPrint('❌ Error actualizando última actividad: $e');
    }
  }

  // ======================================================================
  // AVISOS REMOTOS
  // ======================================================================

  Future<Map<String, dynamic>?> getActiveAnnouncement() async {
    final supabase = client;
    if (supabase == null) return null;

    try {
      debugPrint('[SUPABASE] Calling RPC get_active_remote_announcement...');
      final response = await supabase.rpc('get_active_remote_announcement');
      debugPrint('[SUPABASE] Announcement Result: $response');
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ [SUPABASE] Error getActiveAnnouncement: $e');
      return null;
    }
  }

  // ======================================================================
  // INFORMACIÓN DEL DISPOSITIVO
  // ======================================================================

  Future<void> updateDeviceInfo({String? userId}) async {
    final resolvedUserId = userId ?? currentUser?.id;
    final supabase = client;

    if (resolvedUserId == null || supabase == null) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceData = await _getDeviceData();
      final now = DateTime.now().toUtc().toIso8601String();

      await supabase.from('user_devices').upsert({
        'user_id': resolvedUserId,
        'device_model': deviceData['model']?.toString(),
        'manufacturer': deviceData['manufacturer']?.toString(),
        'android_version': deviceData['androidVersion']?.toString(),
        'app_version': packageInfo.version,
        'app_version_code': int.tryParse(packageInfo.buildNumber) ?? 0,
        'last_seen_at': now,
        'metadata': deviceData,
        'updated_at': now,
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('❌ Error actualizando información del dispositivo: $e');
    }
  }

  // ======================================================================
  // CONFIGURACIÓN DEL USUARIO
  // ======================================================================

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return;

    try {
      await supabase
          .from('user_settings')
          .upsert({
            'user_id': user.id,
            'settings_data': settings,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('❌ Error guardando configuración (offline): $e');
    }
  }

  Future<Map<String, dynamic>?> loadUserSettings() async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return null;

    try {
      final response = await supabase
          .from('user_settings')
          .select('settings_data')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      final data = response['settings_data'];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      debugPrint('❌ Error cargando configuración: $e');
      return null;
    }
  }

  // ======================================================================
  // ESTILOS DESBLOQUEADOS DEL USUARIO
  // ======================================================================

  Future<void> saveUserStyles(List<String> styles) async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null || styles.isEmpty) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await supabase
          .from('user_styles')
          .upsert(
            styles
                .map(
                  (style) => {
                    'user_id': user.id,
                    'style_id': style,
                    'unlocked_at': now,
                    'source': 'app',
                  },
                )
                .toList(),
            onConflict: 'user_id,style_id',
          );
    } catch (e) {
      debugPrint('❌ Error guardando estilos del usuario: $e');
    }
  }

  Future<List<String>> loadUserStyles() async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return <String>[];

    try {
      final response = await supabase
          .from('user_styles')
          .select('style_id')
          .eq('user_id', user.id);

      return (response as List)
          .map((row) => row['style_id'])
          .whereType<String>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error cargando estilos del usuario: $e');
      return <String>[];
    }
  }

  // ======================================================================
  // INFORMES TÉCNICOS
  // ======================================================================

  Future<void> sendTechnicalReport(Map<String, dynamic> reportData) async {
    final supabase = client;
    if (supabase == null) throw Exception('Supabase no inicializado');

    try {
      final response = await supabase.functions.invoke(
        'submit-technical-report',
        body: reportData,
      );
      if (response.status < 200 || response.status >= 300) {
        throw Exception('No se pudo entregar el informe (${response.status})');
      }
    } catch (e) {
      debugPrint('❌ Error enviando informe técnico: $e');
      rethrow;
    }
  }

  // ======================================================================
  // ELIMINACIÓN DE CUENTA
  // ======================================================================

  Future<void> deleteAccount() async {
    final supabase = client;
    if (supabase == null) throw Exception('Supabase no inicializado');

    try {
      // The server validates the current user and removes only their own data.
      final userId = supabase.auth.currentUser?.id;
      final response = await supabase.functions.invoke('delete-account');
      if (response.status != 200 || response.data?['ok'] != true) {
        throw StateError('No se pudo eliminar la cuenta');
      }
      if (userId != null) {
        try {
          await ManualVehicleService.removeLocalForAccount(userId);
        } catch (_) {}
      }
      await supabase.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('❌ Error eliminando cuenta: $e');
      rethrow;
    }
  }

  // ======================================================================
  // ACTUALIZACIONES DE LA APP
  // ======================================================================

  Future<Map<String, dynamic>> getActiveVersion() async {
    final supabase = client;
    if (supabase == null) return <String, dynamic>{};

    try {
      debugPrint('[SUPABASE] Fetching app_versions (min_version_code)...');
      final response = await supabase
          .from('app_versions')
          .select('*, is_mandatory, min_version_code')
          .eq('is_active', true)
          .eq('platform', 'android')
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('[SUPABASE] Version Result: $response');

      if (response == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ [SUPABASE] Error getActiveVersion: $e');
      return <String, dynamic>{};
    }
  }

  // ======================================================================
  // VEHÍCULOS (Desde Supabase)
  // ======================================================================

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'vehicles_catalog_${BackendConfig.url}';
    final supabase = client;
    if (supabase == null) {
      try {
        return List<Map<String, dynamic>>.from(
          jsonDecode(prefs.getString(cacheKey) ?? '[]'),
        );
      } catch (_) {
        return [];
      }
    }

    try {
      debugPrint('[SUPABASE] Query: vehicles.select() from public schema');
      final response = await supabase
          .from('vehicles')
          .select(
            'id, model_url, background_url, name, brand, version, engine, model_bytes, is_active',
          )
          .eq('is_active', true)
          .order('name')
          .limit(100)
          .timeout(const Duration(seconds: 8));

      debugPrint('[SUPABASE] Vehicles Response: ${response.length} items');
      await prefs.setString(cacheKey, jsonEncode(response));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SUPABASE] Error obteniendo vehículos: $e');
      try {
        return List<Map<String, dynamic>>.from(
          jsonDecode(prefs.getString(cacheKey) ?? '[]'),
        );
      } catch (_) {
        return [];
      }
    }
  }

  // ======================================================================
  // AUXILIARES
  // ======================================================================

  Future<Map<String, dynamic>> _getDeviceData() async {
    if (kIsWeb) return {'type': 'web'};

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await _deviceInfo.androidInfo;
      return {
        'type': 'android',
        'manufacturer': info.manufacturer,
        'brand': info.brand,
        'model': info.model,
        'androidVersion': info.version.release,
        'sdkInt': info.version.sdkInt,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        'type': 'ios',
        'name': info.name,
        'model': info.model,
        'systemVersion': info.systemVersion,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }

    return {'type': defaultTargetPlatform.name};
  }
}
