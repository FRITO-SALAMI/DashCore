import 'dart:math' as math;
import '../models/obd_data.dart';

/// Only the no-OBD experience uses this simulation. Never called by ELM parsing.
class GpsSimulation {
  DateTime? _startedAt;
  int _rpm = 800;
  void reset() { _startedAt = null; _rpm = 800; }
  ObdData sample(int gpsSpeed, DateTime now) {
    _startedAt ??= now;
    final elapsed = now.difference(_startedAt!).inMilliseconds / 1000;
    final target = gpsSpeed == 0 ? 800 : (1300 + gpsSpeed * 30).clamp(800, 7000);
    _rpm = (_rpm + (target - _rpm) * .35).round();
    return ObdData(
      speed: gpsSpeed, rpm: _rpm,
      engineTemp: (82 + 10 * (1 - math.exp(-elapsed / 90))).round(),
      voltage: 14.1 + .2 * math.sin(elapsed / 12),
      fuelLevel: 75, gear: gpsSpeed > 0 ? 'D' : 'P',
    );
  }
}
