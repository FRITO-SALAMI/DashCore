import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:usb_serial/usb_serial.dart';

class UsbGnssReader {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _input;
  bool _closed = false;
  String _partial = '';

  Future<void> start(
    UsbDevice device,
    int baud,
    void Function(Position) onFix,
    void Function() onDisconnected,
  ) async {
    final port = await device.create();
    if (port == null)
      throw StateError('El dispositivo no ofrece un puerto serie compatible.');
    if (_closed) {
      await port.close();
      return;
    }
    _port = port;
    if (!await port.open()) throw StateError('No se pudo abrir el puerto USB.');
    if (_closed) {
      await port.close();
      return;
    }
    await port.setPortParameters(
      baud,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );
    if (_closed) return;
    final input = port.inputStream;
    if (input == null) throw StateError('No hay señal de datos USB.');
    _input = input.listen(
      (bytes) {
        if (_closed) return;
        final lines = (_partial + ascii.decode(bytes, allowInvalid: true))
            .split('\n');
        final last = lines.removeLast();
        _partial = last.length <= 160 ? last : '';
        for (final line in lines) {
          final fix = _parseFix(line.trim());
          if (fix != null) onFix(fix);
        }
      },
      onError: (Object _) => onDisconnected(),
      onDone: onDisconnected,
    );
  }

  Future<void> close() async {
    _closed = true;
    try {
      await _input?.cancel();
    } catch (_) {}
    try {
      await _port?.close();
    } catch (_) {}
    _input = null;
    _port = null;
  }

  static Position? _parseFix(String line) {
    if (!line.startsWith(r'$') || line.length > 160) return null;
    final star = line.lastIndexOf('*');
    if (star != line.length - 3 || star < 2) return null;
    final expected = int.tryParse(line.substring(star + 1), radix: 16);
    var checksum = 0;
    for (var i = 1; i < star; i++) {
      checksum ^= line.codeUnitAt(i);
    }
    if (checksum != expected) return null;
    final fields = line.substring(1, star).split(',');
    if (fields.length < 10 || !fields.first.endsWith('RMC') || fields[2] != 'A')
      return null;
    final latitude = _coordinate(fields[3], fields[4], 90);
    final longitude = _coordinate(fields[5], fields[6], 180);
    if (latitude == null || longitude == null) return null;
    final course = double.tryParse(fields[8]);
    final knots = double.tryParse(fields[7]);
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: course != null && course.isFinite && course >= 0 && course < 360
          ? course
          : -1,
      headingAccuracy: 0,
      speed: knots != null && knots.isFinite && knots >= 0
          ? knots * .514444
          : 0,
      speedAccuracy: 0,
    );
  }

  static double? _coordinate(String raw, String hemisphere, int limit) {
    if (limit == 90
        ? hemisphere != 'N' && hemisphere != 'S'
        : hemisphere != 'E' && hemisphere != 'W')
      return null;
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite || value < 0) return null;
    final degrees = (value / 100).floor();
    final minutes = value - degrees * 100;
    final decimal = degrees + minutes / 60;
    if (minutes >= 60 || decimal > limit) return null;
    return hemisphere == 'S' || hemisphere == 'W' ? -decimal : decimal;
  }
}
