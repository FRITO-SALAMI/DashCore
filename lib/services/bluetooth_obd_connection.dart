import '../providers/bluetooth_provider.dart';
import 'obd_connection.dart';

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
    // La conexión Bluetooth es gestionada por BluetoothProvider.
  }

  @override
  Future<void> disconnect() async {
    await provider.disconnect();
  }
}