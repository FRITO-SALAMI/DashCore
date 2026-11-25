import 'dart:async';

/// One owner for automatic attempts. A slow handshake cannot overlap the next tick.
class ObdReconnectLoop {
  ObdReconnectLoop({required this.shouldReconnect, required this.reconnect, required this.onAttempt});
  final bool Function() shouldReconnect;
  final Future<void> Function() reconnect;
  final void Function(bool) onAttempt;
  Timer? _timer;
  bool _busy = false;
  bool get isAttempting => _busy;
  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) => _attempt());
  }
  Future<void> _attempt() async {
    if (_busy || !shouldReconnect()) return;
    _busy = true;
    onAttempt(true);
    try { await reconnect(); } catch (_) {
      // The next eligible tick retries; transient losses are not modal errors.
    } finally {
      _busy = false;
      onAttempt(false);
    }
  }
  void stop() { _timer?.cancel(); _timer = null; }
}
