import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_service.dart';

/// Implementación personalizada de LocalStorage usando flutter_secure_storage para cifrado.
/// Adaptada para la API de supabase_flutter 2.x
class SecureLocalStorage extends LocalStorage {
  final _storage = const FlutterSecureStorage();
  static const _storageKey = 'supabase_auth_token';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return null;
      final data = json.decode(jsonStr);
      return data['access_token'];
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

  static const String supabaseUrl = 'https://pvcfwpziojocogfctgbw.supabase.co';

  static const String supabasePublishableKey =
      'sb_publishable_4t_Vq6QlMSK5EMVVxY7d0w_g-oY3QiC';

  static const String resetPasswordRedirectUrl =
      'https://dashcore-web.vercel.app/reset-password.html';

  static const String appVersion = '0.0.2';
  static const int appBuild = 1;

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

      // Listener para eventos de autenticación
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final user = data.session?.user;

        if (event == AuthChangeEvent.signedIn && user != null) {
          AnalyticsService.instance.logEvent(
            'login',
            data: {'method': user.appMetadata['provider'] ?? 'email'},
          );
          AnalyticsService.instance.trackAppStart();
        } else if (event == AuthChangeEvent.signedOut) {
          AnalyticsService.instance.logEvent('logout');
        } else if (event == AuthChangeEvent.initialSession && user != null) {
          AnalyticsService.instance.trackAppStart();
        }
      });
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
      await supabase.from('profiles').upsert({
        'id': user.id,
        'username':
            user.userMetadata?['display_name'] ?? user.email?.split('@')[0],
        'avatar_url':
            user.userMetadata?['avatar_url'] ??
            user.userMetadata?['profile_url'],
        'total_distance': 0.0,
        'max_speed': 0.0,
        'driver_level': 'PRINCIPIANTE',
        'updated_at': now,
      }, onConflict: 'id');

      await supabase.from('user_settings').upsert({
        'user_id': user.id,
        'updated_at': now,
      }, onConflict: 'user_id');

      await AnalyticsService.instance.trackUserRegistration(user);
      await updateDeviceInfo(userId: user.id);
    } catch (e) {
      debugPrint('❌ Error creando perfil de usuario: $e');
    }
  }

  Future<void> updateLastSeen() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await AnalyticsService.instance.trackAppStart();
      await updateDeviceInfo(userId: user.id);
      await AnalyticsService.instance.updateSessionActivity();
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
        'app_version_code': int.tryParse(packageInfo.buildNumber) ?? appBuild,
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
            ...settings,
            'user_id': user.id,
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
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
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
      for (final style in styles) {
        await supabase.from('user_styles').upsert({
          'user_id': user.id,
          'style_id': style,
          'unlocked_at': now,
          'source': 'app',
        }, onConflict: 'user_id,style_id');
      }
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
      await supabase.from('technical_reports').insert(reportData);
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
      // Llamamos a una función RPC personalizada que borra al usuario en auth.users
      // Esta función debe existir en la base de datos con SECURITY DEFINER.
      await supabase.rpc('delete_user_account');
      await supabase.auth.signOut();
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
    final supabase = client;
    if (supabase == null) {
      debugPrint('[SUPABASE] client is NULL in getVehicles');
      return [];
    }

    try {
      debugPrint('[SUPABASE] Query: vehicles.select() from public schema');
      final response = await supabase
          .from('vehicles')
          .select('id, model_url, background_url, name, brand, version, is_active')
          .eq('is_active', true)
          .order('name');

      debugPrint('[SUPABASE] Vehicles Response: ${response.length} items');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SUPABASE] Error obteniendo vehículos: $e');
      return [];
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
