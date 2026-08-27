class AdminUser {
  final String uuid;
  final String? email;
  final DateTime? createdAt;
  final DateTime? lastAccess;
  final String? registrationIp;
  final String? lastIp;
  final String? country;
  final String? region;
  final String? city;
  final String? device;
  final String? manufacturer;
  final String? model;
  final String? os;
  final String? osVersion;
  final String? dashCoreVersion;
  final String? language;
  final String? timezone;
  final int sessionCount;
  final List<String> recentActivity;
  final String accountStatus;
  final double? latitude;
  final double? longitude;
  final DateTime? locationTimestamp;

  AdminUser({
    required this.uuid,
    this.email,
    this.createdAt,
    this.lastAccess,
    this.registrationIp,
    this.lastIp,
    this.country,
    this.region,
    this.city,
    this.device,
    this.manufacturer,
    this.model,
    this.os,
    this.osVersion,
    this.dashCoreVersion,
    this.language,
    this.timezone,
    this.sessionCount = 0,
    this.recentActivity = const [],
    this.accountStatus = 'ACTIVE',
    this.latitude,
    this.longitude,
    this.locationTimestamp,
  });

  factory AdminUser.fromSupabase(Map<String, dynamic> data) {
    // This is a mapping from a complex join or RPC
    return AdminUser(
      uuid: data['id'] ?? data['user_id'] ?? '',
      email: data['email'],
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
      lastAccess: data['last_seen_at'] != null ? DateTime.parse(data['last_seen_at']) : null,
      registrationIp: data['registration_ip'],
      lastIp: data['last_ip'],
      country: data['country'],
      region: data['region'],
      city: data['city'],
      device: data['device_model'],
      manufacturer: data['manufacturer'],
      model: data['model'],
      os: data['android_version'] != null ? 'Android' : 'Unknown',
      osVersion: data['android_version'],
      dashCoreVersion: data['app_version'],
      language: data['language'],
      timezone: data['timezone'],
      sessionCount: data['session_count'] ?? 0,
      accountStatus: data['status'] ?? 'ACTIVE',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationTimestamp: data['location_at'] != null ? DateTime.parse(data['location_at']) : null,
    );
  }
}
