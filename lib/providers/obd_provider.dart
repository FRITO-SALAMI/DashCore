import 'dart:async';
import '../services/obd_reconnect_loop.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obd_data.dart';
import '../services/obd_connection.dart';
import '../services/demo_data_generator.dart';
import '../services/gps_simulation.dart';
import '../services/sync_service.dart';

import '../services/resource_service.dart';
import '../services/bluetooth_obd_connection.dart';

enum ObdConnectionState { disconnected, initializing, ready, error }

class ObdProvider extends ChangeNotifier {
  static const _persistenceChannel = MethodChannel(
    'io.dashcore.app/persistence',
  );
  final ObdConnection currentConnection;
  late ObdConnection _connection;

  final _errorEventController = StreamController<String>.broadcast();
  Stream<String> get errorEvents => _errorEventController.stream;

  final _gpsPositionController = StreamController<Position>.broadcast();
  Stream<Position> get gpsPositions => _gpsPositionController.stream;

  bool get isDeviceConnected => _connection.isConnected;

  final DemoDataGenerator _demoGenerator = DemoDataGenerator();
  final GpsSimulation _gpsSimulation = GpsSimulation();

  StreamSubscription<String>? _rxSubscription;
  StreamSubscription<Position>? _gpsSubscription;
  Position? _lastPosition;

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

  bool _isCloneMode = false;
  bool get isCloneMode => _isCloneMode;

  bool _isAdvancedMode = false;
  bool get isAdvancedMode => _isAdvancedMode;

  bool _isPowerSavingMode = false;
  bool get isPowerSavingMode => _isPowerSavingMode;

  bool _isGpsMode = false;
  bool get isGpsMode => _isGpsMode;
  int _pollGeneration = 0;
  Future<void> Function(int generation)? _workshopRequest;
  bool _workshopRunning = false;
  bool _accSleeping = false;
  bool get accSleeping => _accSleeping;
  Future<void> _accTransition = Future.value();
  bool _wasRealBeforeAccOff = false;
  bool _wasGpsBeforeAccOff = false;

  void Function(bool sleeping)? onAccStateChanged;
  Function(double speed, double distanceDelta)? onStatsUpdate;

  String _initMessage = "DASHBOARD";
  String get initMessage => _initMessage;

  bool _foreground = true;
  bool _obdWanted = false;
  bool _disposed = false;
  bool _recovering = false;
  bool _reconnectAttempt = false;
  bool get isReconnectAttempt =>
      _reconnectAttempt && !_accSleeping && _foreground;
  late final ObdReconnectLoop _reconnectLoop = ObdReconnectLoop(
    shouldReconnect: () =>
        !_disposed &&
        _foreground &&
        !_accSleeping &&
        _obdWanted &&
        !_isGpsMode &&
        !_isDemoMode &&
        !_recovering &&
        (!_connection.isConnected || state != ObdConnectionState.ready),
    reconnect: () async {
      if (!_connection.isConnected) await _connection.connect();
      if (_accSleeping || !_foreground || !_obdWanted || _disposed) return;
      _isRealMode = true;
      await _recoverEcuConnection();
    },
    onAttempt: (value) {
      _reconnectAttempt = value;
      if (!_disposed) notifyListeners();
    },
  );
  void setForeground(bool value) {
    _foreground = value;
    if (value && !_accSleeping) {
      _reconnectLoop.start();
    } else {
      _reconnectLoop.stop();
    }
    notifyListeners();
  }

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
    _persistenceChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScreenSleep':
          await (_accTransition = _accTransition
              .catchError((Object error) {
                developer.log('ACC transition failed: $error');
              })
              .then((_) => enterAccSleepMode()));
          break;
        case 'onScreenWakeup':
          await (_accTransition = _accTransition
              .catchError((Object error) {
                developer.log('ACC transition failed: $error');
              })
              .then((_) => exitAccSleepMode()));
          break;
      }
    });
    _listen();
    _initializePowerState();
  }

  Future<void> _initializePowerState() async {
    try {
      if (await _persistenceChannel.invokeMethod<bool>('getAccSleeping') ==
          true) {
        await enterAccSleepMode();
        return;
      }
    } catch (_) {}
    if (_accSleeping) return;
    await _checkAutoStart();
    await _initGlobalGpsTracking();
  }

  int _visualLocationConsumers = 0;
  Position? get lastGpsPosition => _lastPosition;

  Future<bool> acquireVisualLocation() async {
    _visualLocationConsumers++;
    await _initGlobalGpsTracking();
    return _gpsSubscription != null;
  }

  void releaseVisualLocation() {
    if (_visualLocationConsumers > 0) _visualLocationConsumers--;
    if (_visualLocationConsumers == 0 && !_isGpsMode && !_isRealMode) _stopGpsTracking();
  }

  void _stopGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _lastPosition = null;
  }

  Future<void> _initGlobalGpsTracking() async {
    if (_accSleeping || _gpsSubscription != null || (!_isGpsMode && !_isRealMode && _visualLocationConsumers == 0)) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _errorEventController.add('Activa la ubicación para utilizar GPS local');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (_accSleeping || (permission != LocationPermission.always && permission != LocationPermission.whileInUse)) return;
      if (_disposed || _gpsSubscription != null ||
          (!_isGpsMode && !_isRealMode && _visualLocationConsumers == 0)) return;
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
      ).listen((position) {
        if (_accSleeping || !position.latitude.isFinite || !position.longitude.isFinite || position.accuracy > 50) return;
        final previous = _lastPosition;
        final kmh = position.speed.isFinite ? (position.speed * 3.6).clamp(0, 300).round() : 0;
        double distanceDelta = 0;
        if (previous != null) {
          final seconds = position.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
          final meters = Geolocator.distanceBetween(previous.latitude, previous.longitude, position.latitude, position.longitude);
          // Discard GPS jumps and long gaps rather than awarding false distance.
          if (seconds > 0 && seconds < 60 && meters / seconds < 85) distanceDelta = meters / 1000;
        }
        _lastPosition = position;
        _gpsPositionController.add(position);
        if (_isDemoMode) return;
        if (_isGpsMode || _isRealMode) onStatsUpdate?.call(kmh.toDouble(), distanceDelta);
        if (!_isGpsMode) return;
        _data = _gpsSimulation.sample(kmh, position.timestamp);
        notifyListeners();
      }, onError: (Object error) {
        _errorEventController.add('No se pudo leer GPS: $error');
        _stopGpsTracking();
      });
    } catch (error) {
      _errorEventController.add('No se pudo iniciar GPS local: $error');
    }
  }
  Future<void> _checkAutoStart() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accSleeping) return;
    _isPerformanceMode = prefs.getBool('is_performance_mode') ?? false;
    _isCloneMode = prefs.getBool('is_clone_mode') ?? false;
    _isAdvancedMode = prefs.getBool('is_advanced_mode') ?? false;
    final wasReal = prefs.getBool('last_was_real_mode') ?? false;
    final wasGps = prefs.getBool('last_was_gps_mode') ?? false;
    _obdWanted = wasReal;
    if (_foreground) _reconnectLoop.start();

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

    bool wasDisconnectedOrReconnecting =
        !_prevIsConnected || _prevIsReconnecting;

    if (_isRealMode &&
        !_reconnectLoop.isAttempting &&
        !_recovering &&
        !_accSleeping &&
        wasDisconnectedOrReconnecting &&
        currentIsConnected &&
        !currentIsReconnecting) {
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

  void setCloneMode(bool value) {
    _isCloneMode = value;
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

  Future<void> saveConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('last_was_real_mode', _isRealMode);
    await prefs.setBool('last_was_gps_mode', _isGpsMode);
    await prefs.setBool('is_performance_mode', _isPerformanceMode);
    await prefs.setBool('is_clone_mode', _isCloneMode);
    await prefs.setBool('is_advanced_mode', _isAdvancedMode);
  }

  Future<void> handleAppResume() async {
    if (_workshopRunning) return;
    developer.log(
      '🚀 App Resumed: Checking connection health...',
      name: 'ObdProvider',
    );

    if (_isRealMode) {
      if (!_connection.isConnected || state == ObdConnectionState.error) {
        developer.log(
          '⚠️ Real mode was active but connection is dead. Recovering...',
          name: 'ObdProvider',
        );
        _recoverEcuConnection();
      } else {
        // Pulse check: send a simple command to see if hardware is still responding
        try {
          String res = await _sendAndWait(
            "AT",
          ).timeout(const Duration(milliseconds: 500));
          if (res.isEmpty) {
            developer.log(
              '⚠️ Hardware not responding. Recovering...',
              name: 'ObdProvider',
            );
            _recoverEcuConnection();
          }
        } catch (_) {
          _recoverEcuConnection();
        }
      }
    } else if (_isGpsMode) {
      // Geolocator stream should ideally resume automatically,
      // but let's ensure it's active.
      if (_gpsSubscription == null) {
        await _initGlobalGpsTracking();
      }
    }
  }

  Future<void> _recoverEcuConnection() async {
    if (_recovering || _accSleeping || _disposed) return;
    _recovering = true;
    try {
      state = ObdConnectionState.initializing;
      developer.log(
        '🔄 Bluetooth restored. Waiting for hardware initialization...',
        name: 'ObdProvider',
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_isRealMode) return;
      bool isSuccess = await runHandshake();
      if (!_isRealMode) return;
      if (isSuccess) {
        state = ObdConnectionState.ready;
        _setPersistenceServiceEnabled(true);
        _startPollingLoop();
      } else {
        stopRealData();
      }
    } finally {
      _recovering = false;
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
      return await _commandCompleter!.future.timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      developer.log("Command timeout $command: $e", name: 'ObdLogic');
      return "";
    }
  }

  ObdData _parseResponse(String rawData, ObdData currentBatchData) {
    final cleanData = rawData.replaceAll('>', '').trim();
    if (cleanData.isEmpty || cleanData == "OK" || cleanData.contains("ELM327"))
      return currentBatchData;

    final parts = cleanData.split(RegExp(r'\s+'));
    try {
      if (parts.length >= 3 && parts[0] == "41" && parts[1] == "0D") {
        return currentBatchData.copyWith(speed: int.parse(parts[2], radix: 16));
      } else if (parts.length >= 4 && parts[0] == "41" && parts[1] == "0C") {
        final a = int.parse(parts[2], radix: 16);
        final b = int.parse(parts[3], radix: 16);
        return currentBatchData.copyWith(rpm: ((a * 256) + b) ~/ 4);
      } else if (parts.length >= 3 && parts[0] == "41" && parts[1] == "05") {
        return currentBatchData.copyWith(
          engineTemp: int.parse(parts[2], radix: 16) - 40,
        );
      } else if (cleanData.contains('V')) {
        final voltValue = double.tryParse(cleanData.replaceAll('V', ''));
        if (voltValue != null)
          return currentBatchData.copyWith(voltage: voltValue);
      }
    } catch (e) {
      developer.log("Parsing error: $e", name: 'ObdLogic');
    }
    return currentBatchData;
  }

  Future<void> toggleRealMode() async {
    if (_accSleeping) return;
    final prefs = await SharedPreferences.getInstance();

    if (!_connection.isConnected || (_connection.isReconnecting && !isRealMode))
      return;

    if (_isRealMode) {
      _obdWanted = false;
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
      _obdWanted = true;
      _reconnectLoop.start();
      await prefs.setBool('last_was_real_mode', true);
      state = ObdConnectionState.ready;
      _setPersistenceServiceEnabled(true);

      // Registrar evento de conexión
      String? deviceName;
      String? deviceAddress;
      if (currentConnection is BluetoothObdConnection) {
        final device = (currentConnection as BluetoothObdConnection)
            .provider
            .connectedDevice;
        deviceName = device?.name;
        deviceAddress = device?.address;
      }

      SyncService.instance.logEvent(
        'vehicle_connected',
        data: {
          'device_name': deviceName,
          'device_address': deviceAddress,
          'mode': 'obd2',
        },
      );

      _startPollingLoop();
      unawaited(_initGlobalGpsTracking());
    } else {
      state = ObdConnectionState.error;
    }
  }

  Future<void> _startPollingLoop() async {
    final generation = ++_pollGeneration;
    while (_isRealMode && generation == _pollGeneration) {
      if (_connection.isReconnecting ||
          state == ObdConnectionState.initializing) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      if (!_connection.isConnected) break;

      ObdData batchData = _data;
      String speedRes = await _sendAndWait("010D");
      if (!_isRealMode ||
          generation != _pollGeneration ||
          !_connection.isConnected)
        return;
      batchData = _parseResponse(speedRes, batchData);

      String rpmRes = await _sendAndWait("010C");
      if (!_isRealMode ||
          generation != _pollGeneration ||
          !_connection.isConnected)
        return;
      batchData = _parseResponse(rpmRes, batchData);

      String tempRes = await _sendAndWait("0105");
      if (!_isRealMode ||
          generation != _pollGeneration ||
          !_connection.isConnected)
        return;
      batchData = _parseResponse(tempRes, batchData);

      String voltRes = await _sendAndWait("ATRV");
      if (!_isRealMode ||
          generation != _pollGeneration ||
          !_connection.isConnected)
        return;
      batchData = _parseResponse(voltRes, batchData);

      if (_isRealMode && _connection.isConnected) {
        _data = batchData;
        notifyListeners();
      }
      final workshopRequest = _workshopRequest;
      if (workshopRequest != null && generation == _pollGeneration) {
        _workshopRequest = null;
        await workshopRequest(generation);
        if (generation != _pollGeneration || !_isRealMode) return;
      }
      if (_isRealMode) {
        int delay = 500;
        if (_isAdvancedMode) {
          delay = 20;
        } else if (_isCloneMode) {
          delay = 50;
        } else if (_isPerformanceMode) {
          delay = 100;
        }
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    if (_isRealMode && generation == _pollGeneration) stopRealData();
  }

  /// Queues a workshop session at the boundary of an existing telemetry batch.
  /// All requests use the same active ELM connection and response buffer.
  Future<T> runWorkshopDiagnostic<T>(
    Future<T> Function(Future<String> Function(String command) send) action, {
    required bool Function() isActive,
  }) {
    if (!_canRunWorkshop(_pollGeneration) ||
        _workshopRequest != null || _workshopRunning) {
      return Future.error(StateError('Conecta el adaptador en modo OBD II o espera el diagnóstico actual.'));
    }
    final result = Completer<T>();
    final timeout = Timer(const Duration(seconds: 14), () {
      _workshopRequest = null;
      result.completeError(StateError('El adaptador no liberó el canal de diagnóstico.'));
    });
    _workshopRequest = (generation) async {
      timeout.cancel();
      _workshopRunning = true;
      try {
        final value = await action((command) async {
          if (!isActive() || !_canRunWorkshop(generation)) {
            throw StateError('Se interrumpió la conexión de diagnóstico.');
          }
          final response = await _sendAndWait(command);
          if (!isActive() || !_canRunWorkshop(generation) || !response.contains('>')) {
            throw StateError('El adaptador dejó de responder durante el diagnóstico.');
          }
          return response;
        });
        result.complete(value);
      } catch (error, stack) {
        result.completeError(error, stack);
      } finally {
        _workshopRunning = false;
      }
    };
    return result.future;
  }

  bool _canRunWorkshop(int generation) =>
      !_disposed && !_accSleeping && _foreground && !_recovering &&
      _isRealMode && _connection.isConnected && !_connection.isReconnecting &&
      state == ObdConnectionState.ready && generation == _pollGeneration;

  void stopRealData() {
    if (state == ObdConnectionState.disconnected) return;
    _isRealMode = false;
    if (!_isGpsMode && _visualLocationConsumers == 0) _stopGpsTracking();
    _setPersistenceServiceEnabled(false);
    if (_commandCompleter?.isCompleted == false)
      _commandCompleter?.complete("");
    _data = const ObdData();
    state = ObdConnectionState.disconnected;
    notifyListeners();
  }

  Future<void> enterAccSleepMode() async {
    if (_accSleeping) return;
    _accSleeping = true;
    _reconnectLoop.stop();
    _pollGeneration++;
    _wasRealBeforeAccOff = _isRealMode;
    _wasGpsBeforeAccOff = _isGpsMode;
    _isPowerSavingMode = true;
    _isRealMode = false;
    _isGpsMode = false;
    if (_isDemoMode) stopDemoMode();
    onAccStateChanged?.call(true);
    ResourceService.instance.setSuspended(true);
    notifyListeners();

    await SyncService.instance.setAccSleeping(true);
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;
    if (_commandCompleter?.isCompleted == false) {
      _commandCompleter?.complete('');
    }
    if (_connection is BluetoothObdConnection) {
      await (_connection as BluetoothObdConnection).provider.setAccSleeping(
        true,
      );
    } else {
      await _connection.disconnect();
    }
    _data = const ObdData();
    state = ObdConnectionState.disconnected;
    await _setPersistenceServiceEnabled(false);
    try {
      await _persistenceChannel.invokeMethod('enterAccBackground');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> exitAccSleepMode() async {
    if (!_accSleeping) return;
    final prefs = await SharedPreferences.getInstance();
    _wasRealBeforeAccOff =
        _wasRealBeforeAccOff || (prefs.getBool('last_was_real_mode') ?? false);
    _wasGpsBeforeAccOff =
        _wasGpsBeforeAccOff || (prefs.getBool('last_was_gps_mode') ?? false);
    _accSleeping = false;
    onAccStateChanged?.call(false);
    ResourceService.instance.setSuspended(false);
    if (_foreground) _reconnectLoop.start();
    if (_connection is BluetoothObdConnection) {
      await (_connection as BluetoothObdConnection).provider.setAccSleeping(
        false,
      );
    }
    await SyncService.instance.setAccSleeping(false);
    await _initGlobalGpsTracking();
    _isPowerSavingMode = false;
    if (_wasGpsBeforeAccOff) {
      _wasGpsBeforeAccOff = false;
      await toggleGpsMode();
    }
    if (_wasRealBeforeAccOff) {
      _wasRealBeforeAccOff = false;
      _isRealMode = true;
      state = ObdConnectionState.initializing;
      try {
        if (!_connection.isConnected) await _connection.connect();
        await _recoverEcuConnection();
      } catch (error) {
        stopWithError(
          'No se pudo restaurar OBD después de activar ACC: $error',
        );
      }
    }
    notifyListeners();
  }

  Future<void> _setPersistenceServiceEnabled(bool enabled) async {
    try {
      await _persistenceChannel.invokeMethod(
        enabled ? 'startService' : 'stopService',
      );
    } on PlatformException catch (error) {
      developer.log(
        'Persistence service update failed: ${error.message}',
        name: 'ObdProvider',
      );
    }
  }

  /// Enables the optional foreground service selected by the user in Settings.
  /// Normal mode never requests a battery-optimization exemption.
  Future<void> setKeepAppActive(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_app_active', enabled);
    try {
      await _persistenceChannel.invokeMethod('setKeepAppActive', {
        'enabled': enabled,
      });
    } catch (_) {}
    if (enabled) {
      try {
        await _persistenceChannel.invokeMethod(
          'requestIgnoreBatteryOptimizations',
        );
      } catch (_) {}
      if (_isRealMode || _isGpsMode) {
        await _setPersistenceServiceEnabled(true);
      }
    } else {
      await _setPersistenceServiceEnabled(false);
    }
  }

  void stopWithError(String errorMessage) {
    stopRealData();
    _errorEventController.add(errorMessage);
    notifyListeners();
  }

  /// ======= GPS MODE (MODO SIN OBD) =========

  Future<void> toggleGpsMode() async {
    if (_accSleeping) return;
    _obdWanted = false;
    final prefs = await SharedPreferences.getInstance();

    if (_isRealMode) return;
    if (_isGpsMode) {
      stopGpsMode();
      await prefs.setBool('last_was_gps_mode', false);
      return;
    }

    if (_isDemoMode) stopDemoMode();

    _gpsSimulation.reset();
    _isGpsMode = true;
    await _initGlobalGpsTracking();
    if (_gpsSubscription == null) { _isGpsMode = false; return; }
    await prefs.setBool('last_was_gps_mode', true);
    state = ObdConnectionState.ready;
    _initMessage = "GPS ACTIVE";

    SyncService.instance.logEvent('vehicle_connected', data: {'mode': 'gps'});

    notifyListeners();
  }

  void stopGpsMode() {
    _isGpsMode = false;
    if (_visualLocationConsumers == 0) _stopGpsTracking();
    _data = const ObdData();
    state = ObdConnectionState.disconnected;
    notifyListeners();
  }

  /// ===== DEMO MODE =========

  Future<void> toggleDemoMode() async {
    if (_accSleeping) return;
    _obdWanted = false;
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
      _initMessage = "connecting"; // Key for localization
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

      // Adaptive Timing for stability on clones and high speed modes
      if (_isPerformanceMode || _isCloneMode || _isAdvancedMode) {
        await _sendAndWait("AT AT1");
      }

      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _initMessage = "error_not_responding"; // Generic key
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectLoop.stop();
    _isRealMode = false;
    _demoGenerator.stop();
    _gpsSubscription?.cancel();
    _gpsPositionController.close();
    _errorEventController.close();
    _rxSubscription?.cancel();
    super.dispose();
  }
}
