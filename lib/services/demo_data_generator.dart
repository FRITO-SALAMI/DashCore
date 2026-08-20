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
    return ObdData(
      speed: _random.nextInt(301),
      rpm: 800 + _random.nextInt(14001),
      engineTemp: 30 + _random.nextInt(80),
      voltage: 13.0 + (_random.nextDouble() * 2.5),
    );
  }
}