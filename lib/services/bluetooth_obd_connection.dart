import '../providers/bluetooth_provider.dart';
import 'obd_connection.dart';
import '../models/obd_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothObdConnection implements ObdConnection {
  final BluetoothProvider provider;

  BluetoothObdConnection(this.provider);

  @override
  Stream<String> get incoming => provider.rxStream;

  @override
  bool get isConnected => provider.isConnected;

  @override
  bool get isReconnecting => provider.isReconnectingBackground;

  @override
  Future<void> send(String command) async {
    provider.sendCommand(command);
  }

  @override
  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('last_obd_address');
    if (address == null) throw StateError('No hay un dispositivo OBD guardado');
    final connected = await provider.connectToDevice(ObdDevice(
      name: prefs.getString('last_obd_name') ?? 'OBD', address: address, isBle: false,
    ), maxAttempts: 1);
    if (!connected) throw StateError('No se pudo reconectar Bluetooth');
  }

  @override
  Future<void> disconnect() async {
    await provider.disconnect();
  }
}