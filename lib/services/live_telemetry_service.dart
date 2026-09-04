import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/obd_provider.dart';

class LiveTelemetryService {
  LiveTelemetryService._();
  static final instance = LiveTelemetryService._();

  Timer? _timer;
  StreamSubscription<Position>? _gpsSubscription;
  Position? _position;
  ObdProvider? _obd;

  void start(ObdProvider obd) {
    _obd = obd;
    _gpsSubscription ??= obd.gpsPositions.listen((value) => _position = value);
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => _upload());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _position = null;
    _obd = null;
  }

  Future<void> _upload() async {
    final user = Supabase.instance.client.auth.currentUser;
    final obd = _obd;
    final position = _position;
    if (user == null || obd == null || position == null) return;

    final data = obd.data;
    await Supabase.instance.client.from('live_vehicle_state').upsert({
      'user_id': user.id,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy_m': position.accuracy,
      'heading_deg': position.heading,
      'gps_speed_kmh': position.speed * 3.6,
      'obd_connected': obd.isRealMode &&
          obd.state == ObdConnectionState.ready,
      'speed_kmh': data.speed,
      'rpm': data.rpm,
      'engine_temp_c': data.engineTemp,
      'voltage_v': data.voltage,
      'fuel_percent': data.fuelLevel,
      'odometer': data.odometer,
    }, onConflict: 'user_id');
  }
}
