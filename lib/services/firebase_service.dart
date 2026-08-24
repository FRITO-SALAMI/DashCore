import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServiceLegacy {
  SupabaseServiceLegacy._();

  static final SupabaseServiceLegacy instance = SupabaseServiceLegacy._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String supabaseUrl =
      'https://pvcfwpziojocogfctgbw.supabase.co';

  static const String supabasePublishableKey =
      'sb_publishable_4t_Vq6QlMSK5EMVVxY7d0w_g-oY3QiC';

  static const String appVersion = '1.0.2';
  static const int appBuild = 4;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  Future<void> createUserProfile(User user) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceData = await _getDeviceData();

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': user.userMetadata?['display_name'] ??
            user.email?.split('@').first,
        'avatar_url': user.userMetadata?['avatar_url'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _supabase.from('user_settings').upsert({
        'user_id': user.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Solo se ejecuta si existe la tabla user_devices.
      try {
        await _supabase.from('user_devices').upsert({
          'user_id': user.id,
          'email': user.email,
          'app_version': packageInfo.version,
          'app_build': int.tryParse(packageInfo.buildNumber) ?? appBuild,
          'platform': defaultTargetPlatform.name,
          'device': deviceData,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {
        // No impedir login si esta tabla todavía no existe.
      }
    } catch (_) {
      // La aplicación puede continuar funcionando localmente.
    }
  }

  Future<void> updateLastSeen() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceData = await _getDeviceData();

      await _supabase.from('user_devices').upsert({
        'user_id': user.id,
        'email': user.email,
        'app_version': packageInfo.version,
        'app_build': int.tryParse(packageInfo.buildNumber) ?? appBuild,
        'platform': defaultTargetPlatform.name,
        'device': deviceData,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // No impedir el funcionamiento de la aplicación.
    }
  }

  Future<void> saveUserSettings(
      Map<String, dynamic> settings,
      ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    await _supabase.from('user_settings').upsert({
      ...settings,
      'user_id': user.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> loadUserSettings() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final response = await _supabase
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> saveUserStyles(List<String> styles) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    for (final style in styles) {
      await _supabase.from('user_styles').upsert(
        {
          'user_id': user.id,
          'style_id': style,
          'unlocked_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,style_id',
      );
    }
  }

  Future<List<String>> loadUserStyles() async {
    final user = currentUser;

    if (user == null) {
      return <String>[];
    }

    final response = await _supabase
        .from('user_styles')
        .select('style_id')
        .eq('user_id', user.id);

    return (response as List)
        .map((row) => row['style_id'])
        .whereType<String>()
        .toList();
  }

  Future<void> logEvent(
      String eventName, {
        Map<String, dynamic>? data,
      }) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      await _supabase.from('analytics').insert({
        'user_id': user.id,
        'event': eventName,
        'app_version': packageInfo.version,
        'app_build': int.tryParse(packageInfo.buildNumber) ?? appBuild,
        'platform': defaultTargetPlatform.name,
        'data': data ?? <String, dynamic>{},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Analytics nunca debe romper la aplicación.
    }
  }

  Future<Map<String, dynamic>> _getDeviceData() async {
    if (kIsWeb) {
      return {
        'type': 'web',
      };
    }

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

    return {
      'type': defaultTargetPlatform.name,
    };
  }
}