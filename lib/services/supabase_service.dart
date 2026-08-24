import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String supabaseUrl =
  'https://pvcfwpziojocogfctgbw.supabase.co';

  static const String supabasePublishableKey =
  'sb_publishable_4t_Vq6QlMSK5EMVVxY7d0w_g-oY3QiC';

  static const String redirectUrl =
      'io.dashcore.app://login-callback/';

  static const String appVersion = '1.0.2';
  static const int appBuild = 4;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
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

  Future<void> createUserProfile(User user) async {
    final supabase = client;
    if (supabase == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    await supabase.from('profiles').upsert(
      {
        'id': user.id,
        'username': user.userMetadata?['display_name'],
        'avatar_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['profile_url'],
        'updated_at': now,
      },
      onConflict: 'id',
    );

    await supabase.from('user_settings').upsert(
      {
        'user_id': user.id,
        'updated_at': now,
      },
      onConflict: 'user_id',
    );

    await updateDeviceInfo(userId: user.id);
  }

  Future<void> updateLastSeen() async {
    final user = currentUser;
    if (user == null) return;

    await updateDeviceInfo(userId: user.id);
  }

  Future<void> updateDeviceInfo({String? userId}) async {
    final resolvedUserId = userId ?? currentUser?.id;
    final supabase = client;

    if (resolvedUserId == null || supabase == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceData = await _getDeviceData();
    final now = DateTime.now().toUtc().toIso8601String();

    await supabase.from('user_devices').upsert(
      {
        'user_id': resolvedUserId,
        'device_model': deviceData['model']?.toString(),
        'manufacturer': deviceData['manufacturer']?.toString(),
        'android_version': deviceData['androidVersion']?.toString(),
        'app_version': packageInfo.version,
        'app_version_code':
        int.tryParse(packageInfo.buildNumber) ?? appBuild,
        'last_seen_at': now,
        'metadata': deviceData,
        'updated_at': now,
      },
      onConflict: 'user_id',
    );
  }

  Future<void> saveUserSettings(
      Map<String, dynamic> settings,
      ) async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return;

    await supabase.from('user_settings').upsert(
      {
        ...settings,
        'user_id': user.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Future<Map<String, dynamic>?> loadUserSettings() async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return null;

    final response = await supabase
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return Map<String, dynamic>.from(response);
  }

  Future<void> saveUserStyles(List<String> styles) async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null || styles.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();

    for (final style in styles) {
      await supabase.from('user_styles').upsert(
        {
          'user_id': user.id,
          'style_id': style,
          'unlocked_at': now,
          'source': 'app',
        },
        onConflict: 'user_id,style_id',
      );
    }
  }

  Future<List<String>> loadUserStyles() async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return <String>[];

    final response = await supabase
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
    final supabase = client;

    if (user == null || supabase == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceData = await _getDeviceData();

    await supabase.from('analytics').insert(
      {
        'user_id': user.id,
        'event': eventName,
        'app_version': packageInfo.version,
        'app_build':
        int.tryParse(packageInfo.buildNumber) ?? appBuild,
        'platform': defaultTargetPlatform.name,
        'data': {
          ...(data ?? <String, dynamic>{}),
          'device': deviceData,
        },
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>> getActiveAppRelease() async {
    final supabase = client;
    if (supabase == null) return <String, dynamic>{};

    final response = await supabase
        .from('app_releases')
        .select()
        .eq('is_active', true)
        .eq('platform', 'android')
        .order('version_code', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return <String, dynamic>{};

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> getActiveVersion() async {
    final supabase = client;
    if (supabase == null) return <String, dynamic>{};

    final response = await supabase
        .from('app_versions')
        .select()
        .eq('is_active', true)
        .eq('platform', 'android')
        .order('version_code', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return <String, dynamic>{};

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final supabase = client;
    if (supabase == null) return <Map<String, dynamic>>[];

    final response = await supabase
        .from('vehicles')
        .select()
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>>
  getAvailableDashboardStyles() async {
    final supabase = client;
    if (supabase == null) return <Map<String, dynamic>>[];

    final response = await supabase
        .from('dashboard_styles')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStyleVersions(
      String styleId,
      ) async {
    final supabase = client;
    if (supabase == null) return <Map<String, dynamic>>[];

    final response = await supabase
        .from('style_versions')
        .select()
        .eq('style_id', styleId)
        .eq('is_active', true)
        .order('version', ascending: false);

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStyleAssets(
      String styleId,
      ) async {
    final supabase = client;
    if (supabase == null) return <Map<String, dynamic>>[];

    final response = await supabase
        .from('style_assets')
        .select()
        .eq('style_id', styleId)
        .order('asset_key');

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> logStyleDownload({
    required String styleId,
    required int styleVersion,
    String? deviceModel,
  }) async {
    final user = currentUser;
    final supabase = client;

    if (user == null || supabase == null) return;

    final packageInfo = await PackageInfo.fromPlatform();

    await supabase.from('style_downloads').insert(
      {
        'user_id': user.id,
        'style_id': styleId,
        'style_version': styleVersion,
        'downloaded_at':
        DateTime.now().toUtc().toIso8601String(),
        'device_platform': defaultTargetPlatform.name,
        'app_version': packageInfo.version,
        'device_model': deviceModel,
      },
    );
  }

  Future<Map<String, dynamic>> _getDeviceData() async {
    if (kIsWeb) {
      return <String, dynamic>{
        'type': 'web',
      };
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await _deviceInfo.androidInfo;

      return <String, dynamic>{
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

      return <String, dynamic>{
        'type': 'ios',
        'name': info.name,
        'model': info.model,
        'systemVersion': info.systemVersion,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }

    return <String, dynamic>{
      'type': defaultTargetPlatform.name,
    };
  }
}