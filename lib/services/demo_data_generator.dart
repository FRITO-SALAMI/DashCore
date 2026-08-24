import 'dart:async';
import 'dart:math';

import '../models/obd_data.dart';

class DemoDataGenerator {
  Timer? _timer;

  final Random _random = Random();

  void start(void Function(ObdData data) onData) {
    stop();

    onData(_generateData());

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        onData(_generateData());
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  ObdData _generateData() {
    final speed = _random.nextInt(301);
    final rpm = 800 + _random.nextInt(7201);
    
    String gear = 'N';
    if (rpm < 500) {
      gear = 'P';
    } else if (speed > 0) {
      gear = (speed / 40).floor().clamp(1, 6).toString();
    }

    return ObdData(
      speed: speed,
      rpm: rpm,
      engineTemp: 85 + _random.nextInt(15),
      voltage: 13.8 + (_random.nextDouble() * 0.8),
      fuelLevel: 10 + _random.nextInt(91),
      odometer: 125000 + _random.nextInt(100),
      gear: gear,
    );
  }
}