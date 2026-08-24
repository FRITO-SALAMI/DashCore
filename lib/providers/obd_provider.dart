import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obd_data.dart';
import '../services/obd_connection.dart';
import '../services/demo_data_generator.dart';

enum ObdConnectionState { disconnected, initializing, ready, error }

class ObdProvider extends ChangeNotifier {
  final ObdConnection currentConnection;
  late ObdConnection _connection;

  final _errorEventController = StreamController<String>.broadcast();
  Stream<String> get errorEvents => _errorEventController.stream;

  bool get isDeviceConnected => _connection.isConnected;

  final DemoDataGenerator _demoGenerator = DemoDataGenerator();

  StreamSubscription<String>? _rxSubscription;
  StreamSubscription<Position>? _gpsSubscription;

  Completer<String>? _commandCompleter;
  final StringBuffer _commandBuffer = StringBuffer();

  ObdConnectionState _state = ObdConnectionState.disconnected;
  ObdConnectionState get state => _state;

  ObdData _data = const ObdData();
  ObdData get data => _data;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isRealMode = false;
  bool get isRealMode => _isRealMode;

  bool _isPerformanceMode = false;
  bool get isPerformanceMode => _isPerformanceMode;

  bool _isAdvancedMode = false;
  bool get isAdvancedMode => _isAdvancedMode;

  bool _isPowerSavingMode = false;
  bool get isPowerSavingMode => _isPowerSavingMode;

  bool _isGpsMode = false;
  bool get isGpsMode => _isGpsMode;

  String _initMessage = "DASHBOARD";
  String get initMessage => _initMessage;

  bool _prevIsConnected = false;
  bool _prevIsReconnecting = false;

  set state(ObdConnectionState value) {
    if (_state == value) return;
    developer.log('🔄 STATE CHANGE: $_state -> $value', name: 'ObdProvider');
    _state = value;
    notifyListeners();
  }

  ObdProvider(this.currentConnection) {
    _connection = currentConnection;
    _listen();
    _checkAutoStart();
  }

  Future<void> _checkAutoStart() async {
    final prefs = await SharedPreferences.getInstance();
    _isPerformanceMode = prefs.getBool('is_performance_mode') ?? false;
    _isAdvancedMode = prefs.getBool('is_advanced_mode') ?? false;
    final wasReal = prefs.getBool('last_was_real_mode') ?? false;
    final wasGps = prefs.getBool('last_was_gps_mode') ?? false;

    if (wasReal) {
      _isRealMode = true;
      // updateConnection will handle handshake once Bluetooth is up
    } else if (wasGps) {
      toggleGpsMode();
    }
  }

  void updateConnection(ObdConnection newConnection) {
    _connection = newConnection;
    _listen();

    final currentIsConnected = _connection.isConnected;
    final currentIsReconnecting = _connection.isReconnecting;

    bool wasDisconnectedOrReconnecting = !_prevIsConnected || _prevIsReconnecting;

    if (_isRealMode && wasDisconnectedOrReconnecting && currentIsConnected && !currentIsReconnecting) {
      _recoverEcuConnection();
    }

    _prevIsConnected = currentIsConnected;
    _prevIsReconnecting = currentIsReconnecting;

    notifyListeners();
  }

  void setPerformanceMode(bool value) {
    _isPerformanceMode = value;
    notifyListeners();
  }

  void setAdvancedMode(bool value) {
    _isAdvancedMode = value;
    notifyListeners();
  }

  void setPowerSavingMode(bool value) {
    _isPowerSavingMode = value;
    notifyListeners();
  }

  Future<void> _recoverEcuConnection() async {
    state = ObdConnectionState.initializing;
    developer.log('🔄 Bluetooth restored. Waiting for hardware initialization...', name: 'ObdProvider');
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!_isRealMode) return;
    bool isSuccess = await runHandshake();
    if (!_isRealMode) return;
    if (isSuccess) {
      state = ObdConnectionState.ready;
      _startPollingLoop();
    } else {
      stopWithError("Connection lost: failed to reconnect to ECU");
    }
  }

  void _listen() {
    _rxSubscription?.cancel();
    _rxSubscription = _connection.incoming.listen(_handleIncomingData);
  }

  void _handleIncomingData(String rawData) {
    if (_isDemoMode || _isGpsMode) return;
    _commandBuffer.write(rawData);
    if (rawData.contains(">")) {
      if (_commandCompleter?.isCompleted == false) {
        _commandCompleter?.complete(_commandBuffer.toString());
      }
    }
  }

  Future<String> _sendAndWait(String command) async {
    _commandBuffer.clear();
    _commandCompleter = Completer<String>();
    _connection.send("$command\r");
    try {
      return await _commandCompleter!.future.timeout(const Duration(seconds: 3));
    } catch (e) {
      developer.log("Command timeout $command: $e", name: 'ObdLogic');
      return "";
    }
  }

  ObdData _parseResponse(String rawData, ObdData currentBatchData) {
    final cleanData = rawData.replaceAll('>', '').trim();
    if (cleanData.isEmpty || cleanData == "OK" || cleanData.contains("ELM327")) return currentBatchData;

    final parts = cleanData.split(RegExp(r'\s+'));
    try {
      if (parts.length >= 3 && parts[0] == "41" && parts[1] == "0D") {
        return currentBatchData.copyWith(speed: int.parse(parts[2], radix: 16));
      } else if (parts.length >= 4 && parts[0] == "41" && parts[1] == "0C") {
        final a = int.parse(parts[2], radix: 16);
        final b = int.parse(parts[3], radix: 16);
        return currentBatchData.copyWith(rpm: ((a * 256) + b) ~/ 4);
      } else if (parts.length >= 3 && parts[0] == "41" && parts[1] == "05") {
        return currentBatchData.copyWith(engineTemp: int.parse(parts[2], radix: 16) - 40);
      } else if (cleanData.contains('V')) {
        final voltValue = double.tryParse(cleanData.replaceAll('V', ''));
        if (voltValue != null) return currentBatchData.copyWith(voltage: voltValue);
      }
    } catch (e) {
      developer.log("Parsing error: $e", name: 'ObdLogic');
    }
    return currentBatchData;
  }

  Future<void> toggleRealMode() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_connection.isConnected || (_connection.isReconnecting && !isRealMode)) return;

    if (_isRealMode) {
      stopRealData();
      state = ObdConnectionState.disconnected;
      await prefs.setBool('last_was_real_mode', false);
      return;
    }

    if (_isDemoMode || _isGpsMode) {
      stopDemoMode();
      stopGpsMode();
    }

    bool isSuccessHandshake = await runHandshake();
    if (state == ObdConnectionState.disconnected) return;

    if (isSuccessHandshake) {
      _isRealMode = true;
      await prefs.setBool('last_was_real_mode', true);
      state = ObdConnectionState.ready;
      _startPollingLoop();
    } else {
      state = ObdConnectionState.error;
    }
  }

  Future<void> _startPollingLoop() async {
    while (_isRealMode) {
      if (_connection.isReconnecting || state == ObdConnectionState.initializing) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      if (!_connection.isConnected) break;

      ObdData batchData = _data;
      String speedRes = await _sendAndWait("010D");
      if (!_isRealMode || !_connection.isConnected) return;
      batchData = _parseResponse(speedRes, batchData);

      String rpmRes = await _sendAndWait("010C");
      if (!_isRealMode || !_connection.isConnected) return;
      batchData = _parseResponse(rpmRes, batchData);

      String tempRes = await _sendAndWait("0105");
      if (!_isRealMode || !_connection.isConnected) return;
      batchData = _parseResponse(tempRes, batchData);

      String voltRes = await _sendAndWait("ATRV");
      if (!_isRealMode || !_connection.isConnected) return;
      batchData = _parseResponse(voltRes, batchData);

      if (_isRealMode && _connection.isConnected) {
        _data = batchData;
        notifyListeners();
      }
      if (_isRealMode) {
        int delay = 500;
        if (_isPowerSavingMode) {
          delay = 1000;
        } else if (_isAdvancedMode) {
          delay = 20;
        } else if (_isPerformanceMode) {
          delay = 100;
        }
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    if (_isRealMode) stopRealData();
  }

  void stopRealData() {
    if (state == ObdConnectionState.disconnected) return;
    _isRealMode = false;
    if (_commandCompleter?.isCompleted == false) _commandCompleter?.complete("");
    _data = const ObdData();
    state = ObdConnectionState.disconnected;
    notifyListeners();
  }

  void stopWithError(String errorMessage) {
    stopRealData();
    _errorEventController.add(errorMessage);
    notifyListeners();
  }

  /// ======= GPS MODE (MODO SIN OBD) =========

  Future<void> toggleGpsMode() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isRealMode) return;
    if (_isGpsMode) {
      stopGpsMode();
      await prefs.setBool('last_was_gps_mode', false);
      return;
    }

    if (_isDemoMode) stopDemoMode();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _isGpsMode = true;
    await prefs.setBool('last_was_gps_mode', true);
    state = ObdConnectionState.ready;
    _initMessage = "GPS ACTIVE";

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((Position position) {
      final kmh = (position.speed * 3.6).round();
      int simulatedRpm = 800 + (kmh * 20);
      if (kmh > 0) simulatedRpm += 1000;
      if (simulatedRpm > 6500) simulatedRpm = 6500;

      _data = _data.copyWith(
        speed: kmh,
        rpm: simulatedRpm,
        engineTemp: 90,
        voltage: 14.2,
        fuelLevel: 65,
        odometer: 154230,
        gear: kmh > 0 ? 'D' : 'P',
      );
      notifyListeners();
    });

    notifyListeners();
  }

  void stopGpsMode() {
    _isGpsMode = false;
    _gpsSubscription?.cancel();
    _data = const ObdData();
    state = ObdConnectionState.disconnected;
    notifyListeners();
  }

  /// ===== DEMO MODE =========

  Future<void> toggleDemoMode() async {
    if (_isRealMode || _isGpsMode) return;
    if (_isDemoMode) {
      stopDemoMode();
      return;
    }
    _isDemoMode = true;
    _demoGenerator.start((ObdData newObdData) {
      _data = newObdData;
      notifyListeners();
    });
    notifyListeners();
  }

  void stopDemoMode() {
    _isDemoMode = false;
    _demoGenerator.stop();
    _data = const ObdData();
    notifyListeners();
  }

  Future<bool> runHandshake() async {
    try {
      state = ObdConnectionState.initializing;
      _initMessage = "Connecting to ECU";
      notifyListeners();

      String atz = await _sendAndWait("ATZ");
      if (state == ObdConnectionState.disconnected) return false;
      if (!atz.toUpperCase().contains("ELM327")) return false;

      String ate0 = await _sendAndWait("ATE0");
      if (state == ObdConnectionState.disconnected) return false;
      if (!ate0.toUpperCase().contains("OK")) return false;

      String atl0 = await _sendAndWait("ATL0");
      if (state == ObdConnectionState.disconnected) return false;
      if (!atl0.toUpperCase().contains("OK")) return false;

      String atsp0 = await _sendAndWait("ATSP0");
      if (state == ObdConnectionState.disconnected) return false;
      if (!atsp0.toUpperCase().contains("OK")) return false;

      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _initMessage = "Initialization error";
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _isRealMode = false;
    _demoGenerator.stop();
    _gpsSubscription?.cancel();
    _errorEventController.close();
    _rxSubscription?.cancel();
    super.dispose();
  }
}
