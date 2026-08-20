abstract class ObdConnection {
  Stream<String> get incoming;

  bool get isConnected;
  bool get isReconnecting;

  Future<void> send(String command);

  Future<void> connect();
  Future<void> disconnect();
}