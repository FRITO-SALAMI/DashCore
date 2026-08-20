import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:dashcore/models/bluetooth_enums.dart';
import 'package:dashcore/services/bluetooth_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obd_device.dart';

class BluetoothProvider extends ChangeNotifier {
  final FlutterBlueClassic _bluetooth = FlutterBlueClassic();

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  ObdDevice? _connectedDevice;
  ObdDevice? get connectedDevice => _connectedDevice;

  final List<ObdDevice> _discoveredDevices = [];
  List<ObdDevice> get discoveredDevices => _discoveredDevices;

  final Map<String, BluetoothDevice> _deviceMap = {};

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSubscription;
  StreamSubscription<BluetoothDevice>? _scanSubscription;

  final _rxController = StreamController<String>.broadcast();
  Stream<String> get rxStream => _rxController.stream;

  int _connectionId = 0;

  String _connectionMessage = "READY";
  String get connectionMessage => _connectionMessage;

  String _backgroundMessage = "RECONNECTING";
  String get backgroundMessage => _backgroundMessage;

  bool _isReconnectingBackground = false;
  bool get isReconnectingBackground => _isReconnectingBackground;

  Timer? _scanTimer;

  bool _isHardwareOn = false;
  bool get isHardwareOn => _isHardwareOn;

  bool _isToggleOn = false;
  bool get isToggleOn => _isToggleOn;

  bool _pendingScan = false;

  BluetoothProvider() {
    _bluetooth.adapterStateNow.then((BluetoothAdapterState state) {
      _isHardwareOn = state == BluetoothAdapterState.on;
      if (_isHardwareOn) _autoReconnect();
      notifyListeners();
    });

    _bluetooth.adapterState.listen((BluetoothAdapterState state) {
      _isHardwareOn = state == BluetoothAdapterState.on;

      if (state == BluetoothAdapterState.off) {
        developer.log("⚠️ Bluetooth OFF", name: 'reBlue');
        _isToggleOn = false;
        disconnect();
        _stopScan();
        _discoveredDevices.clear();
        _deviceMap.clear();
      } else if (state == BluetoothAdapterState.on) {
        developer.log("✅ Bluetooth ON", name: 'reBlue');
        if (_pendingScan) {
          _pendingScan = false;
          startScan();
        } else {
          _autoReconnect();
        }
      }
      notifyListeners();
    });
  }

  Future<void> _autoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAddress = prefs.getString('last_obd_address');
    final lastName = prefs.getString('last_obd_name');

    if (lastAddress != null && lastName != null && !_isConnected && !_isConnecting) {
      developer.log("🔄 Auto-reconnecting to $lastName ($lastAddress)", name: 'reBlue');
      
      final device = ObdDevice(name: lastName, address: lastAddress, isBle: false);
      
      // Try to find it in bonded devices first
      final bonded = await _bluetooth.bondedDevices;
      if (bonded != null) {
        for (var d in bonded) {
          if (d.address == lastAddress) {
             _deviceMap[d.address] = d;
             connectToDevice(device);
             return;
          }
        }
      }
      
      // If not bonded, it might need a scan or it won't connect directly.
      // For now, we only auto-reconnect if it was bonded or recently seen.
    }
  }

  void _addDeviceToList(BluetoothDevice device) {
    if (_deviceMap.containsKey(device.address)) return;

    _deviceMap[device.address] = device;
    _discoveredDevices.add(
      ObdDevice(
        name: device.name ?? "Unknown Device",
        address: device.address,
        isBle: false,
      ),
    );
  }

  Future<BluetoothScanResult> startScan() async {
    if (_isScanning) return BluetoothScanResult.started;

    developer.log("Requesting permissions", name: 'reBlue');
    final permissionStatus = await requestBluetoothPermissions();

    if (permissionStatus == BluetoothPermissionStatus.permanentlyDenied) {
      return BluetoothScanResult.permanentlyDenied;
    }

    if (permissionStatus != BluetoothPermissionStatus.granted) {
      _isScanning = false;
      notifyListeners();
      return BluetoothScanResult.notStarted;
    }

    if (!_isHardwareOn) {
      _pendingScan = true;
      try {
        _bluetooth.turnOn();
      } catch (e) {
        developer.log("turnOn error: $e", name: 'reBlue', error: e);
      }
      return BluetoothScanResult.notStarted;
    }

    _isToggleOn = true;
    _isScanning = true;
    _pendingScan = false;

    _discoveredDevices.clear();
    _deviceMap.clear();

    notifyListeners();

    try {
      final bonded = await _bluetooth.bondedDevices;
      if (bonded != null) {
        for (final device in bonded) {
          _addDeviceToList(device);
        }
      }

      _bluetooth.startScan();
      developer.log("Scan started", name: 'reBlue');

      await _scanSubscription?.cancel();
      _scanSubscription = _bluetooth.scanResults.listen(
        (BluetoothDevice device) {
          if (!_deviceMap.containsKey(device.address)) {
            _addDeviceToList(device);
            notifyListeners();
          }
        },
        onError: (err) {
          developer.log("Scan stream error", name: 'reBlue', error: err);
          _stopScan();
        },
      );

      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 15), () {
        if (_isScanning) {
          _stopScan();
        }
      });
    } catch (e) {
      developer.log("Scan error: $e", name: 'reBlue', error: e);
      _isScanning = false;
      notifyListeners();
      return BluetoothScanResult.notStarted;
    }

    return BluetoothScanResult.started;
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    _bluetooth.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connectToDevice(ObdDevice device) async {
    if (_isConnected && _connectedDevice?.address == device.address) {
      return true;
    }
    if (_isConnecting) return false;

    _connectionId++;
    final int currentId = _connectionId;
    _isConnecting = true;
    _connectionMessage = "CONNECTING TO ${device.name}...";
    notifyListeners();

    await disconnect();

    if (currentId != _connectionId) return false;

    final physicalDevice = _deviceMap[device.address];
    if (physicalDevice == null) {
      // Try to get bonded device directly if map is empty (auto-reconnect case)
      final bonded = await _bluetooth.bondedDevices;
      BluetoothDevice? found;
      if (bonded != null) {
        for (var d in bonded) {
          if (d.address == device.address) {
            found = d;
            break;
          }
        }
      }
      
      if (found == null) {
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      _deviceMap[found.address] = found;
    }

    final targetDevice = _deviceMap[device.address]!;

    for (int i = 1; i <= 3; i++) {
      try {
        await _bluetooth.bondDevice(targetDevice.address);
        if (currentId != _connectionId) return false;

        _connectionMessage = i > 1 ? "ATTEMPT #$i" : "EXCHANGING DATA...";
        notifyListeners();

        final newSocket = await _bluetooth
            .connect(targetDevice.address)
            .timeout(const Duration(seconds: 5));

        if (currentId != _connectionId) {
          await newSocket?.finish();
          return false;
        }

        _connection = newSocket;
        _connectedDevice = device;
        _isConnected = true;
        _setupListen();

        // Save for auto-reconnect
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_obd_address', device.address);
        await prefs.setString('last_obd_name', device.name);

        if (currentId == _connectionId) {
          _isConnecting = false;
        }
        notifyListeners();
        return true;
      } catch (e) {
        if (currentId != _connectionId) return false;
        if (i < 3) {
          await Future.delayed(const Duration(seconds: 2));
        } else {
          _isConnected = false;
          _connectedDevice = null;
          _isConnecting = false;
          notifyListeners();
          return false;
        }
      }
    }

    _isConnecting = false;
    notifyListeners();
    return false;
  }

  void _setupListen() {
    _inputSubscription = _connection!.input!.listen(
      (Uint8List data) {
        final incoming = String.fromCharCodes(data);
        _rxController.add(incoming);
      },
      onDone: () => disconnect(isIntentional: false),
      onError: (e) => disconnect(isIntentional: false),
      cancelOnError: true,
    );
  }

  void sendCommand(String command) {
    if (!_isConnected || _connection == null) return;
    try {
      _connection!.output.add(Uint8List.fromList('$command\r'.codeUnits));
    } catch (e) {
      developer.log("Command error", name: 'reBlue');
    }
  }

  Future<void> disconnect({bool isIntentional = true}) async {
    try {
      await _inputSubscription?.cancel();
      await _connection?.finish();
      _connection = null;
    } catch (e) {}

    if (isIntentional) {
      _isConnected = false;
      _connectedDevice = null;
      _isConnecting = false;
      notifyListeners();
    } else {
      _startBackgroundReconnect();
    }
  }

  Future<void> _startBackgroundReconnect() async {
    if (_connectedDevice == null) return;
    _connectionId++;
    final int currentId = _connectionId;
    _isReconnectingBackground = true;
    notifyListeners();

    final physicalDevice = _deviceMap[_connectedDevice!.address];
    if (physicalDevice == null) {
      _isReconnectingBackground = false;
      disconnect(isIntentional: true);
      return;
    }

    for (int i = 1; i <= 3; i++) {
      try {
        await Future.delayed(const Duration(seconds: 4));
        if (currentId != _connectionId) return;

        final socket = await _bluetooth.connect(physicalDevice.address).timeout(const Duration(seconds: 5));
        if (currentId != _connectionId) {
          await socket?.finish();
          return;
        }

        _connection = socket;
        _isConnected = true;
        _isReconnectingBackground = false;
        _setupListen();
        notifyListeners();
        return;
      } catch (e) {
        if (i == 3) {
          _isReconnectingBackground = false;
          await disconnect();
        }
      }
    }
  }

  void cancelConnection() {
    _connectionId++;
    _isConnecting = false;
    _isReconnectingBackground = false;
    disconnect();
    notifyListeners();
  }

  Future<void> turnOffBluetooth() async {
    _isToggleOn = false;
    cancelConnection();
    await disconnect();
    await _stopScan();
    _discoveredDevices.clear();
    _deviceMap.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopScan();
    disconnect();
    super.dispose();
  }
}
