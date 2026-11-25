import 'dart:async';
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/services/obd_connection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SlowClone implements ObdConnection {
  final controller = StreamController<String>();
  final commands = <String>[];
  final timers = <Timer>[];
  bool outstanding = false;
  bool overlap = false;
  @override
  bool isConnected = true;
  @override
  bool get isReconnecting => false;
  @override
  Stream<String> get incoming => controller.stream;
  @override
  Future<void> connect() async { isConnected = true; }
  @override
  Future<void> disconnect() async { isConnected = false; }
  @override
  Future<void> send(String command) async {
    if (outstanding) overlap = true;
    outstanding = true;
    final cmd = command.trim();
    commands.add(cmd);
    final reply = switch (cmd) {
      'ATZ' => 'ATZ\rELM327 v1.5\r>',
      '010D' => '41 0D 2A\r>',
      '010C' => '41 0C 1F 40\r>',
      '0105' => '41 05 7B\r>',
      'ATRV' => '13.8V\r>',
      _ => 'OK\r>',
    };
    // Slow, fragmented replies: the next PID must wait for the prompt.
    timers.add(Timer(const Duration(milliseconds: 25), () => controller.add(reply.substring(0, 3))));
    timers.add(Timer(const Duration(milliseconds: 110), () { outstanding = false; controller.add(reply.substring(3)); }));
  }
  Future<void> close() async { for (final timer in timers) { timer.cancel(); } await controller.close(); }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ELM clone keeps PID order, adaptive timing and exact readings with delayed fragments', () async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('io.dashcore.app/persistence');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => false);
    final clone = SlowClone();
    final obd = ObdProvider(clone);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    obd.setCloneMode(true);
    await obd.toggleRealMode();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(obd.data.speed, 42);
    expect(obd.data.rpm, 2000);
    expect(obd.data.engineTemp, 83);
    expect(obd.data.voltage, 13.8);
    expect(clone.commands.take(5), ['ATZ', 'ATE0', 'ATL0', 'ATSP0', 'AT AT1']);
    expect(clone.commands.skip(5).take(8), ['010D', '010C', '0105', 'ATRV', '010D', '010C', '0105', 'ATRV']);
    expect(clone.overlap, false);
    obd.stopRealData();
    obd.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await clone.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
}
