import '../core/backend_config.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ffi' show IntPtr, sizeOf;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_model.dart';
import '../models/obd_data.dart';
import '../utils/display_format.dart';
export '../utils/display_format.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/resource_service.dart';
import '../services/manual_vehicle_service.dart';

enum DashboardStyle {
  sporty,
  racing,
  modern,
  vehicle3D,
  purpleMaps,
  racingHud,
  glowRed,
  hellishRed,
  teslaStyle,
  classicSport,
  raceCluster,
  retroLcd,
  evCluster,
  teslaRoad,
  teslaModel,
  sketch,
  neonWorld,
  dashcore,
  myStyle,
  dashcorevideo,
  gifSpeedo,
  mp4Player,
  orbitWorld,
  freeDashboard,
  nightDrive,
  apexGt,
  carbonPulse,
  roadAtlas,
}

const builtInDashboardStyles = {
  DashboardStyle.sporty,
  DashboardStyle.nightDrive,
  DashboardStyle.apexGt,
  DashboardStyle.carbonPulse,
  DashboardStyle.roadAtlas,
};

enum TemperatureUnit { celsius, fahrenheit }

enum Language { spanish, english }

enum PerformanceMode { auto, ultra, high, balanced, powerSaving }

class CustomGaugeConfig {
  final String id;
  final String type;
  Offset position;
  Size size;
  int design;
  bool visible;
  bool locked;
  String? logoPath;
  String? customImagePath;
  double customImageOpacity;

  CustomGaugeConfig({
    required this.id,
    required this.type,
    required this.position,
    this.size = const Size(100, 100),
    this.design = 0,
    this.visible = true,
    this.locked = false,
    this.logoPath,
    this.customImagePath,
    this.customImageOpacity = 1.0,
  });

  CustomGaugeConfig copyWith({
    Offset? position,
    Size? size,
    int? design,
    bool? visible,
    bool? locked,
  }) {
    return CustomGaugeConfig(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      design: design ?? this.design,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      logoPath: logoPath,
      customImagePath: customImagePath,
      customImageOpacity: customImageOpacity,
    );
  }
}

class DashSettingsProvider extends ChangeNotifier {
  // ============================================================
  // DASHBOARD
  // ============================================================

  DashboardStyle _selectedStyle = DashboardStyle.nightDrive;
  bool _roadAtlasVehicleOnRight = false;
  Set<DashboardStyle> _downloadedStyles = {...builtInDashboardStyles};

  Color _accentColor = const Color(0xFF00E5FF);
  Color _needleColor = Colors.redAccent;
  Color _gaugeColor = Colors.white.withOpacity(0.05);
  Color _mapColor = const Color(0xFF9C27B0);
  Color _lightColor = const Color(0xFF00E5FF);
  int _lightDesign = 0;

  // ============================================================
  // COLORES DISPONIBLES
  // ============================================================

  static const List<Color> availableColors = [
    Color(0xFF00E5FF),
    Color(0xFF2196F3),
    Color(0xFF3F51B5),
    Color(0xFF673AB7),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFFFF1744),
    Color(0xFFFF5722),
    Color(0xFFFF9800),
    Color(0xFFFFC107),
    Color(0xFFFFEB3B),
    Color(0xFF8BC34A),
    Color(0xFF4CAF50),
    Color(0xFF00C853),
    Color(0xFF009688),
    Color(0xFF00BFA5),
    Color(0xFFFFFFFF),
    Color(0xFFB0BEC5),
  ];

  static const List<String> availableColorNames = [
    'Cyan Accent',
    'Blue',
    'Indigo',
    'Deep Purple',
    'Purple',
    'Pink',
    'Red Accent',
    'Deep Orange',
    'Orange',
    'Amber',
    'Yellow',
    'Light Green',
    'Green',
    'Green Accent',
    'Teal',
    'Teal Accent',
    'White',
    'Blue Grey',
  ];

  // ============================================================
  // GETTERS DE COLORES DISPONIBLES
  // ============================================================

  List<Color> get availableAccentColors => availableColors;

  List<Color> get availableNeedleColors => availableColors;

  List<Color> get availableGaugeColors => availableColors;

  List<Color> get availableMapColors => availableColors;

  List<Color> get availableLightColors => availableColors;

  bool _isEditMode = false;
  int _lastScreenIndex = 0;

  final List<CustomGaugeConfig> _customGauges = [];

  TemperatureUnit _tempUnit = TemperatureUnit.celsius;
  Language _language = Language.spanish;

  String? _backgroundImage;
  bool _isAssetBackground = true;

  String _modelPath = '';
  String _vehicleColorHex = '#FFFFFF';
  String _vehicleCameraOrbit = '0deg 75deg 5m';
  double _vehicleCameraZoom = 1.0;

  bool _isNoObdMode = false;
  bool _highPerformanceMode = false;
  bool _isCloneMode = false;
  bool _isAdvancedObdMode = false;

  bool _use24HourFormat = true;
  DistanceUnit _distanceUnit = DistanceUnit.kilometers;
  bool get use24HourFormat => _use24HourFormat;
  DistanceUnit get distanceUnit => _distanceUnit;
  String get speedUnitLabel =>
      _distanceUnit == DistanceUnit.miles ? 'MPH' : 'KM/H';
  String get distanceUnitLabel =>
      _distanceUnit == DistanceUnit.miles ? 'MI' : 'KM';
  double displaySpeed(num kmh) => fromKilometers(kmh, _distanceUnit);
  double displayDistance(num km) => fromKilometers(km, _distanceUnit);
  double speedToKmh(num value) => toKilometers(value, _distanceUnit);
  double get displaySpeedAlertThreshold => displaySpeed(_speedAlertThreshold);
  String formatTime(int hour, int minute) =>
      clockLabel(hour, minute, _use24HourFormat);
  ObdData displayData(ObdData raw) => raw.copyWith(
    speed: displaySpeed(raw.speed).round(),
    odometer: displayDistance(raw.odometer).round(),
  );
  void setUse24HourFormat(bool value) {
    _use24HourFormat = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void setDistanceUnit(DistanceUnit value) {
    _distanceUnit = value;
    notifyListeners();
    _saveLocalSettings();
  }

  bool get reduceMotion =>
      reduceOrbitMotion ||
      (_isLowResourceDevice && _performanceMode == PerformanceMode.auto);
  bool get reduceOrbitMotion =>
      _isPowerSavingMode || _performanceMode == PerformanceMode.powerSaving;
  bool _isPowerSavingMode = false;
  PerformanceMode _performanceMode = PerformanceMode.auto;
  bool _performanceMonitoringEnabled = false;
  bool _keepAppActive = false;

  bool _showWelcomeGreeting = true;
  double _welcomeGreetingDuration = 5.0;
  int _welcomeDesign = 0;

  bool _showFuelGauge = false;
  double _simulatedFuelLevel = 100.0;
  bool _useSimulatedFuel = false;

  double _tempAlertThreshold = 105.0;
  double _speedAlertThreshold = 120.0;
  bool _tempWarningEnabled = true;
  bool _speedWarningEnabled = true;
  List<String> _alertSoundPaths = const [];
  String? _selectedAlertSoundPath;
  bool _isDownloadingAlertSounds = false;

  static const String alertSoundsZipUrl =
      '${BackendConfig.storageUrl}/vehicles/sounds/alert_sounds.zip';

  String? _profileImageUrl;
  List<String?> _teslaAppSlots = List<String?>.filled(6, null);

  Timer? _fuelTimer;
  Timer? _statsTimer;
  Timer? _statsSaveTimer;
  bool _dashboardVisible = true;

  void setDashboardVisible(bool visible) {
    if (visible == _dashboardVisible) return;
    _dashboardVisible = visible;
    if (!visible) unawaited(_probeInternetAndSync());
  }
  DateTime? _lastDrivingSampleAt;
  bool _isAppActive = true;
  bool _statsDirty = false;
  bool _statsPendingSync = false;
  bool _restoringAccountSettings = false;
  Timer? _cloudSettingsSaveTimer;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _localSettingsSaveTimer;
  Completer<void>? _localSettingsSaveCompleter;
  bool _disposed = false;

  Vehicle? _selectedVehicle;
  String? _vehicleLogoPath;
  List<Vehicle> _availableVehicles = const [];
  bool _vehiclesLoading = true;

  bool _analyticsConsent = false;
  String _consentVersion = '1.0';
  DateTime? _consentTimestamp;

  bool _hasUpdateAvailable = false;

  // ============================================================
  // TUTORIAL SIMPLE
  // ============================================================

  bool _isTutorialActive = false;

  int _tutorialStep = 0;

  static const int _totalTutorialSteps = 14;

  // ============================================================
  // DESCARGAS
  // ============================================================

  bool _isDownloadingResources = false;
  double _downloadProgress = 0.0;
  String _downloadSizeMessage = 'Calculando...';

  // ============================================================
  // STATS
  // ============================================================

  double _totalDistance = 0.0;
  int _totalTrips = 0;
  double _maxSpeed = 0.0;
  Duration _totalDriveTime = Duration.zero;

  // ============================================================
  // DEVICE
  // ============================================================

  bool _isLowResourceDevice = Platform.isAndroid && sizeOf<IntPtr>() == 4;
  String _deviceArchitecture = 'Desconocida';

  // ============================================================
  // GETTERS
  // ============================================================

  DashboardStyle get selectedStyle => _selectedStyle;
  bool get roadAtlasVehicleOnRight => _roadAtlasVehicleOnRight;

  void flipRoadAtlasPanels() {
    _roadAtlasVehicleOnRight = !_roadAtlasVehicleOnRight;
    notifyListeners();
    _saveLocalSettings();
  }

  Set<DashboardStyle> get downloadedStyles => _downloadedStyles;

  Color get accentColor => _accentColor;

  Color get needleColor => _needleColor;

  Color get gaugeColor => _gaugeColor;

  Color get mapColor => _mapColor;

  Color get lightColor => _lightColor;

  int get lightDesign => _lightDesign;

  bool get isEditMode => _isEditMode;

  int get lastScreenIndex => _lastScreenIndex;

  List<CustomGaugeConfig> get customGauges => _customGauges;

  TemperatureUnit get tempUnit => _tempUnit;

  Language get language => _language;

  String? get backgroundImage => _backgroundImage;

  bool get isAssetBackground => _isAssetBackground;

  String get modelPath => _modelPath;

  String get vehicleColorHex => _vehicleColorHex;
  String get vehicleCameraOrbit => _vehicleCameraOrbit;
  double get vehicleCameraZoom => _vehicleCameraZoom;

  bool get isNoObdMode => _isNoObdMode;

  bool get highPerformanceMode => _highPerformanceMode;

  bool get isCloneMode => _isCloneMode;

  bool get isAdvancedObdMode => _isAdvancedObdMode;

  bool get isPowerSavingMode => _isPowerSavingMode;

  PerformanceMode get performanceMode => _performanceMode;

  bool get performanceMonitoringEnabled => _performanceMonitoringEnabled;
  bool get diagnosticsConsent => _analyticsConsent;
  bool get keepAppActive => _keepAppActive;

  bool get isLowResourceDevice => _isLowResourceDevice;

  bool get isAppActive => _isAppActive;

  /// Maximum visual telemetry refresh rate. Expensive dashboards remain
  /// available on low-resource devices, but receive fewer UI updates.
  int get telemetryFramesPerSecond {
    if (reduceMotion) return 5;
    switch (_performanceMode) {
      case PerformanceMode.auto:
        return _isLowResourceDevice ? 15 : 20;
      case PerformanceMode.powerSaving:
        return 10;
      case PerformanceMode.balanced:
        return 15;
      case PerformanceMode.high:
      case PerformanceMode.ultra:
        return 20;
    }
  }

  String get deviceArchitecture => _deviceArchitecture;

  bool get showWelcomeGreeting => _showWelcomeGreeting;

  double get welcomeGreetingDuration => _welcomeGreetingDuration;

  int get welcomeDesign => _welcomeDesign;

  bool get showFuelGauge => _showFuelGauge;

  double get simulatedFuelLevel => _simulatedFuelLevel;

  bool get useSimulatedFuel => _useSimulatedFuel;

  double get tempAlertThreshold => _tempAlertThreshold;

  double get speedAlertThreshold => _speedAlertThreshold;
  List<String> get alertSoundPaths => List.unmodifiable(_alertSoundPaths);
  String? get selectedAlertSoundPath => _selectedAlertSoundPath;
  bool get isDownloadingAlertSounds => _isDownloadingAlertSounds;
  String alertSoundLabel(String path) =>
      'SONIDO ${_alertSoundPaths.indexOf(path) + 1}';

  bool get tempWarningEnabled => _tempWarningEnabled;

  bool get speedWarningEnabled => _speedWarningEnabled;

  Vehicle? get selectedVehicle => _selectedVehicle;
  String? get vehicleLogoPath => _vehicleLogoPath;

  bool get isTutorialActive => _isTutorialActive;

  int get tutorialStep => _tutorialStep;

  int get totalTutorialSteps => _totalTutorialSteps;

  bool get hasUpdateAvailable => _hasUpdateAvailable;

  bool get isLoggedIn => SupabaseService.instance.isLoggedIn;

  bool get isDownloadingResources => _isDownloadingResources;

  double get downloadProgress => _downloadProgress;

  String get downloadSizeMessage => _downloadSizeMessage;

  double get totalDistance => _totalDistance;

  int get totalTrips => _totalTrips;

  double get maxSpeed => _maxSpeed;

  Duration get totalDriveTime => _totalDriveTime;

  String? get profileImageUrl => _profileImageUrl;

  List<String?> get teslaAppSlots => _teslaAppSlots;

  List<Vehicle> get availableVehicles => List.unmodifiable(_availableVehicles);
  bool get vehiclesLoading => _vehiclesLoading;

  bool get sketchExists => _customGauges.isNotEmpty;

  bool _isDownloadingGifs = false;
  List<File> _downloadedGifs = [];

  bool get isDownloadingGifs => _isDownloadingGifs;
  List<File> get downloadedGifs => _downloadedGifs;
  bool _isDownloadingVideos = false;
  List<File> _downloadedVideos = [];
  String? _selectedVideoPath;
  bool get isDownloadingVideos => _isDownloadingVideos;
  List<File> get downloadedVideos => _downloadedVideos;
  String? get selectedVideoPath => _selectedVideoPath;

  void setVideoStyleSource(String path) {
    _selectedVideoPath = path;
    notifyListeners();
    _saveLocalSettings();
  }

  Future<void> loadDownloadedGifs() async {
    _downloadedGifs = await ResourceService.instance.getLocalFiles('gifstore');
    notifyListeners();
  }

  Future<bool> downloadGifPack() async {
    _isDownloadingGifs = true;
    notifyListeners();
    try {
      const url = '${BackendConfig.storageUrl}/vehicles/config/gifstore.zip';
      final success = await ResourceService.instance.downloadAndUnzip(
        url,
        'gifstore',
      );
      if (success) {
        await loadDownloadedGifs();
      }
      return success;
    } finally {
      _isDownloadingGifs = false;
      notifyListeners();
    }
  }

  Future<void> loadDownloadedVideos() async {
    _downloadedVideos = await ResourceService.instance.getLocalFiles(
      'videostore',
    );
    notifyListeners();
  }

  Future<bool> downloadVideoPack() async {
    _isDownloadingVideos = true;
    notifyListeners();
    try {
      const base = '${BackendConfig.storageUrl}/vehicles/config';
      final first = await ResourceService.instance.downloadAndUnzip(
        '$base/PackVideo1.zip',
        'videostore',
      );
      final second = await ResourceService.instance.downloadAndUnzip(
        '$base/Packvideo2.zip',
        'videostore',
      );
      if (first || second) await loadDownloadedVideos();
      return first && second;
    } finally {
      _isDownloadingVideos = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DRIVER LEVEL
  // ============================================================

  String get driverLevel {
    if (_totalDistance > 1000) return 'LEYENDA DEL ASFALTO';
    if (_totalDistance > 500) return 'EXPERTO DASHCORE';
    if (_totalDistance > 100) return 'CONDUCTOR AVANZADO';
    if (_totalDistance > 20) return 'ENTUSIASTA';
    return 'PRINCIPIANTE';
  }

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  DashSettingsProvider() {
    _loadSettings().then((_) async {
      await restoreAccountSettings();
      _probeInternetAndSync();
    });
    _loadRemoteVehicles();
    loadDownloadedGifs();
    loadDownloadedVideos();
    _startFuelSimulation();
    _startStatsTimer();
    _detectDeviceCapabilities();
    _setupAuthListener();
  }

  int _vehicleLoadGeneration = 0;
  Future<void> _loadRemoteVehicles() async {
    final generation = ++_vehicleLoadGeneration;
    _vehiclesLoading = true;
    notifyListeners();
    try {
      debugPrint('[VEHICLE] Loading catalog from Supabase...');
      final rows = await SupabaseService.instance.getVehicles();

      if (rows.isEmpty) {
        debugPrint('[VEHICLE] Catalog is empty. Check RLS and is_active flag.');
      } else {
        debugPrint('[VEHICLE] Found ${rows.length} vehicles.');
      }

      final vehicles = <Vehicle>[];
      for (final row in rows) {
        var vehicle = Vehicle.fromSupabase(row);
        final modelUrl = vehicle.modelUrl;
        final bgUrl = vehicle.backgroundUrl;

        if (modelUrl != null && modelUrl.isNotEmpty) {
          final modelName = ResourceService.instance.getFileNameFromUrl(
            modelUrl,
          );
          final bgName = bgUrl != null
              ? ResourceService.instance.getFileNameFromUrl(bgUrl)
              : null;

          var localModel = await ResourceService.instance.getLocalFile(
            modelName,
            subDir: vehicle.id,
          );
          if (localModel != null) {
            final remoteSize = (row['model_bytes'] as num?)?.toInt() ?? -1;
            final localSize = await localModel.length();
            if (remoteSize > 0 && remoteSize != localSize) {
              // The storage object may have been replaced under the same URL
              // (for example Optima2012.glb). Do not keep selecting the stale
              // local copy; the catalog will offer the new download.
              localModel = null;
            }
          }
          final localBg = bgName != null
              ? await ResourceService.instance.getLocalFile(
                  bgName,
                  subDir: vehicle.id,
                )
              : null;

          // Only mark as downloaded if both model and background (if required) exist locally
          bool hasAllLocal = localModel != null;
          if (bgUrl != null && bgUrl.isNotEmpty && localBg == null) {
            hasAllLocal = false;
          }

          if (hasAllLocal) {
            vehicle = vehicle.copyWith(
              isDownloaded: true,
              modelPath: 'file://${localModel!.path}',
              backgroundImage: localBg?.path ?? vehicle.backgroundImage,
            );
          }
        }
        vehicles.add(vehicle);
      }
      vehicles.addAll(await ManualVehicleService.load(includeCloud: true));
      if (generation != _vehicleLoadGeneration || _disposed) return;
      _availableVehicles = vehicles;
      if (_selectedVehicle?.isCustom == true &&
          !vehicles.any((v) => v.id == _selectedVehicle!.id)) {
        _selectedVehicle = null;
        _modelPath = '';
        _backgroundImage = null;
      }

      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selected_vehicle_id');
      if (selectedId != null) {
        for (final vehicle in vehicles) {
          if (vehicle.id == selectedId) {
            _selectedVehicle = vehicle;
            unawaited(_resolveVehicleLogo(vehicle, downloadIfMissing: false));
            if (vehicle.isDownloaded) {
              _modelPath = vehicle.modelPath;
              _backgroundImage = vehicle.backgroundImage;
              _isAssetBackground = false;
            }
            break;
          }
        }
      }
    } catch (error) {
      debugPrint('❌ [VEHICLE] Catalog error: $error');
      final manual = await ManualVehicleService.load();
      if (generation == _vehicleLoadGeneration && !_disposed)
        _availableVehicles = manual;
    } finally {
      if (generation == _vehicleLoadGeneration && !_disposed) {
        _vehiclesLoading = false;
        notifyListeners();
      }
    }
  }

  void _setupAuthListener() {
    _authSubscription = SupabaseService.instance.client?.auth.onAuthStateChange
        .listen((data) {
          if (data.event == AuthChangeEvent.signedOut ||
              data.event == AuthChangeEvent.signedIn ||
              data.event == AuthChangeEvent.initialSession) {
            // Do not retain a private vehicle from a previous account in the visible stage.
            if (_selectedVehicle?.isCustom == true) {
              _selectedVehicle = null;
              _modelPath = '';
              _backgroundImage = null;
            }
            _availableVehicles = _availableVehicles
                .where((v) => !v.isCustom)
                .toList();
            unawaited(_loadRemoteVehicles());
          }
          if ((data.event == AuthChangeEvent.signedIn ||
                  data.event == AuthChangeEvent.initialSession) &&
              data.session?.user != null) {
            restoreAccountSettings().then((_) => syncProfileToSupabase());
          }
          notifyListeners();
        });
  }

  // ============================================================
  // DEVICE DETECTION
  // ============================================================

  Future<void> _detectDeviceCapabilities() async {
    final deviceInfo = DeviceInfoPlugin();

    if (!Platform.isAndroid) return;

    try {
      final androidInfo = await deviceInfo.androidInfo;

      final isOlder = androidInfo.version.sdkInt < 28;

      // A 32-bit APK may run on a 64-bit OS: inspect the current process.
      final isArm32 = sizeOf<IntPtr>() == 4;
      Map<String, dynamic>? capabilities;
      try {
        capabilities = await const MethodChannel(
          'io.dashcore.app/launcher',
        ).invokeMapMethod<String, dynamic>('getRenderCapabilities');
      } catch (_) {}

      _deviceArchitecture = isArm32 ? 'ARM 32-bit' : 'ARM 64-bit';

      _isLowResourceDevice =
          isOlder ||
          isArm32 ||
          capabilities?['lowRam'] == true ||
          ((capabilities?['maxHeapMb'] as num?)?.toInt() ?? 1024) < 192;
      if (_isLowResourceDevice && !isArm32) {
        PaintingBinding.instance.imageCache
          ..maximumSizeBytes = 24 * 1024 * 1024
          ..maximumSize = 60;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Device detection error: $e');
    }
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  void setPerformanceMode(PerformanceMode mode) {
    _performanceMode = mode;
    notifyListeners();
    _saveLocalSettings();
  }

  void setPerformanceMonitoringEnabled(bool enabled) {
    if (_performanceMonitoringEnabled == enabled) return;
    _performanceMonitoringEnabled = enabled;
    notifyListeners();
    _saveLocalSettings();
  }

  void setDiagnosticsConsent(bool enabled) {
    _analyticsConsent = enabled;
    _performanceMonitoringEnabled = enabled;
    SyncService.instance.recordConsent(
      accepted: enabled,
      version: _consentVersion,
    );
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // STATS
  // ============================================================

  void _startStatsTimer() {
    _statsTimer?.cancel();

    _statsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final lastSample = _lastDrivingSampleAt;
      final isDriving =
          _isAppActive &&
          lastSample != null &&
          DateTime.now().difference(lastSample) < const Duration(seconds: 15);
      if (isDriving) {
        _totalDriveTime += const Duration(minutes: 1);
        _scheduleStatsSave();
        notifyListeners();
      }
      if (_statsPendingSync) _probeInternetAndSync();
    });
  }

  void updateStats(double speed, double distanceDelta) {
    if (!_isAppActive ||
        speed < 3 ||
        distanceDelta <= 0 ||
        distanceDelta > 0.5) {
      return;
    }

    _lastDrivingSampleAt = DateTime.now();
    if (speed > _maxSpeed) {
      _maxSpeed = speed;
    }

    _totalDistance += distanceDelta;
    _statsPendingSync = true;

    _scheduleStatsSave();
  }

  void _scheduleStatsSave() {
    _statsDirty = true;
    _statsSaveTimer ??= Timer(const Duration(seconds: 30), () {
      _statsSaveTimer = null;
      flushRuntimeStats();
    });
  }

  Future<void> flushRuntimeStats() async {
    if (!_statsDirty) return;
    _statsDirty = false;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble('stat_total_dist', _totalDistance),
      prefs.setInt('stat_total_trips', _totalTrips),
      prefs.setDouble('stat_max_speed', _maxSpeed),
      prefs.setInt('stat_total_time_sec', _totalDriveTime.inSeconds),
      prefs.setBool('stats_pending_sync', _statsPendingSync),
    ]);
  }

  void setAppActive(bool active) {
    if (_isAppActive == active) return;
    _isAppActive = active;
    if (!active) {
      _lastDrivingSampleAt = null;
      _fuelTimer?.cancel();
      _statsTimer?.cancel();
      _statsSaveTimer?.cancel();
      _statsSaveTimer = null;
      flushRuntimeStats();
    } else {
      _startStatsTimer();
      _startFuelSimulation();
    }
    notifyListeners();
  }

  void incrementTrips() {
    _totalTrips++;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _loadLocalSettings(prefs);

    _analyticsConsent = prefs.getBool('analytics_consent') ?? false;

    SyncService.instance.recordConsent(
      accepted: _analyticsConsent,
      version: _consentVersion,
    );

    notifyListeners();
  }

  void _loadLocalSettings(SharedPreferences prefs) {
    _roadAtlasVehicleOnRight = prefs.getBool('road_atlas_vehicle_right') ?? false;
    final styleIndex =
        prefs.getInt('selected_style_idx') ?? DashboardStyle.nightDrive.index;

    if (styleIndex >= 0 && styleIndex < DashboardStyle.values.length) {
      _selectedStyle = DashboardStyle.values[styleIndex];
    }

    final downloadedList = prefs.getStringList('downloaded_styles');

    if (downloadedList != null) {
      _downloadedStyles = downloadedList
          .map(
            (n) => DashboardStyle.values.firstWhere(
              (s) => s.name == n,
              orElse: () => DashboardStyle.sporty,
            ),
          )
          .toSet();

      _downloadedStyles.addAll(builtInDashboardStyles);
    }

    final tempIndex = prefs.getInt('temp_unit_idx') ?? 0;

    if (tempIndex >= 0 && tempIndex < TemperatureUnit.values.length) {
      _tempUnit = TemperatureUnit.values[tempIndex];
    }

    final languageIndex = prefs.getInt('language_idx') ?? 0;

    if (languageIndex >= 0 && languageIndex < Language.values.length) {
      _language = Language.values[languageIndex];
    }

    final performanceIndex = prefs.getInt('performance_mode_idx') ?? 0;

    if (performanceIndex >= 0 &&
        performanceIndex < PerformanceMode.values.length) {
      _performanceMode = PerformanceMode.values[performanceIndex];
    }
    _performanceMonitoringEnabled =
        prefs.getBool('performance_monitoring_enabled') ?? false;

    _accentColor = Color(
      prefs.getInt('accent_color') ?? const Color(0xFF00E5FF).value,
    );

    _needleColor = Color(
      prefs.getInt('needle_color') ?? Colors.redAccent.value,
    );

    _gaugeColor = Color(
      prefs.getInt('gauge_color') ?? Colors.white.withOpacity(0.05).value,
    );

    _mapColor = Color(prefs.getInt('map_color') ?? 0xFF9C27B0);

    _lightColor = Color(prefs.getInt('light_color') ?? 0xFF00E5FF);

    _lightDesign = prefs.getInt('light_design') ?? 0;

    _lastScreenIndex = prefs.getInt('last_screen_index') ?? 0;

    _backgroundImage = prefs.getString('background_image') ?? _backgroundImage;

    _isAssetBackground = prefs.getBool('is_asset_background') ?? true;

    _modelPath = prefs.getString('model_path') ?? _modelPath;

    _vehicleColorHex = prefs.getString('vehicle_color_hex') ?? '#FFFFFF';
    _vehicleCameraOrbit =
        prefs.getString('vehicle_camera_orbit') ?? '0deg 75deg 5m';
    _vehicleCameraZoom = prefs.getDouble('vehicle_camera_zoom') ?? 1.0;

    _isNoObdMode = prefs.getBool('is_no_obd_mode') ?? false;

    _highPerformanceMode = prefs.getBool('is_performance_mode') ?? false;

    _isCloneMode = prefs.getBool('is_clone_mode') ?? false;

    _isAdvancedObdMode = prefs.getBool('is_advanced_mode') ?? false;

    _isPowerSavingMode = prefs.getBool('is_power_saving_mode') ?? false;
    _keepAppActive = prefs.getBool('keep_app_active') ?? false;
    _use24HourFormat = prefs.getBool('use_24_hour_format') ?? true;
    _distanceUnit = prefs.getString('distance_unit') == 'miles'
        ? DistanceUnit.miles
        : DistanceUnit.kilometers;

    _showWelcomeGreeting = prefs.getBool('show_welcome_greeting') ?? true;

    _welcomeGreetingDuration =
        prefs.getDouble('welcome_greeting_duration') ?? 5.0;

    _welcomeDesign = prefs.getInt('welcome_design') ?? 0;

    _showFuelGauge = prefs.getBool('show_fuel_gauge') ?? false;

    _simulatedFuelLevel = prefs.getDouble('simulated_fuel_level') ?? 100.0;

    _tempAlertThreshold = prefs.getDouble('temp_alert_threshold') ?? 105.0;

    _speedAlertThreshold = prefs.getDouble('speed_alert_threshold') ?? 120.0;

    _tempWarningEnabled = prefs.getBool('temp_warning_enabled') ?? true;

    _speedWarningEnabled = prefs.getBool('speed_warning_enabled') ?? true;
    _selectedAlertSoundPath = prefs.getString('selected_alert_sound_path');
    refreshAlertSounds();

    _totalDistance = prefs.getDouble('stat_total_dist') ?? 0.0;

    _totalTrips = prefs.getInt('stat_total_trips') ?? 0;

    _maxSpeed = prefs.getDouble('stat_max_speed') ?? 0.0;

    _totalDriveTime = Duration(
      seconds: prefs.getInt('stat_total_time_sec') ?? 0,
    );
    _statsPendingSync = prefs.getBool('stats_pending_sync') ?? false;

    _useSimulatedFuel = prefs.getBool('use_simulated_fuel') ?? false;

    _isTutorialActive = prefs.getBool('is_tutorial_active') ?? false;

    _tutorialStep = prefs.getInt('tutorial_step') ?? 0;

    if (_tutorialStep < 0 || _tutorialStep >= _totalTutorialSteps) {
      _tutorialStep = 0;
    }

    _profileImageUrl = prefs.getString('profile_image_url');
    _selectedVideoPath = prefs.getString('selected_video_path');
    if (_selectedVideoPath != null && !File(_selectedVideoPath!).existsSync()) {
      _selectedVideoPath = null;
      unawaited(prefs.remove('selected_video_path'));
    }
    if (_profileImageUrl != null && !File(_profileImageUrl!).existsSync()) {
      _profileImageUrl = null;
      unawaited(prefs.remove('profile_image_url'));
    }

    // The remote catalog resolves the selected vehicle and its cached files.

    final savedGauges = prefs.getStringList('custom_gauges');

    if (savedGauges != null) {
      _customGauges.clear();

      for (final gStr in savedGauges) {
        try {
          final m = jsonDecode(gStr);

          _customGauges.add(
            CustomGaugeConfig(
              id: m['id'],
              type: m['type'],
              position: Offset(
                (m['x'] ?? 0).toDouble(),
                (m['y'] ?? 0).toDouble(),
              ),
              size: Size(
                (m['w'] ?? 100).toDouble(),
                (m['h'] ?? 100).toDouble(),
              ),
              design: m['design'] ?? 0,
              visible: m['visible'] ?? true,
              locked: m['locked'] ?? false,
            ),
          );
        } catch (e) {
          debugPrint('Custom gauge load error: $e');
        }
      }
    }

    final savedTeslaSlots = prefs.getStringList('tesla_app_slots');

    if (savedTeslaSlots != null && savedTeslaSlots.length == 6) {
      _teslaAppSlots = savedTeslaSlots
          .map<String?>((v) => v.isEmpty ? null : v)
          .toList();
    }

    final evGlbStr = prefs.getString('ev_cluster_glb_config');
    if (evGlbStr != null) {
      try {
        final m = jsonDecode(evGlbStr);
        _evClusterGlbConfig = CustomGaugeConfig(
          id: 'ev_glb',
          type: 'glb',
          position: Offset(m['x'], m['y']),
          size: Size(m['w'], m['h']),
        );
      } catch (_) {}
    }
  }

  // ============================================================
  // SAVE SETTINGS
  // ============================================================

  Future<void> _saveLocalSettings() async {
    if (_disposed) return;
    _localSettingsSaveTimer?.cancel();
    final done = _localSettingsSaveCompleter ??= Completer<void>();
    _localSettingsSaveTimer = Timer(
      const Duration(milliseconds: 350),
      () async {
        _localSettingsSaveTimer = null;
        _localSettingsSaveCompleter = null;
        try {
          await _persistLocalSettings();
        } finally {
          if (!done.isCompleted) done.complete();
        }
      },
    );
    return done.future;
  }

  Future<void> _persistLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('selected_style_idx', _selectedStyle.index);
    await prefs.setBool('road_atlas_vehicle_right', _roadAtlasVehicleOnRight);

    await prefs.setStringList(
      'downloaded_styles',
      _downloadedStyles.map((s) => s.name).toList(),
    );

    await prefs.setInt('temp_unit_idx', _tempUnit.index);

    await prefs.setInt('language_idx', _language.index);

    await prefs.setInt('performance_mode_idx', _performanceMode.index);

    await prefs.setBool(
      'performance_monitoring_enabled',
      _performanceMonitoringEnabled,
    );
    await prefs.setBool('analytics_consent', _analyticsConsent);

    await prefs.setInt('accent_color', _accentColor.value);

    await prefs.setInt('needle_color', _needleColor.value);

    await prefs.setInt('gauge_color', _gaugeColor.value);

    await prefs.setInt('map_color', _mapColor.value);

    await prefs.setInt('light_color', _lightColor.value);

    await prefs.setInt('light_design', _lightDesign);

    if (_backgroundImage != null) {
      await prefs.setString('background_image', _backgroundImage!);
    }

    await prefs.setBool('is_asset_background', _isAssetBackground);

    await prefs.setString('model_path', _modelPath);

    await prefs.setString('vehicle_color_hex', _vehicleColorHex);
    await prefs.setString('vehicle_camera_orbit', _vehicleCameraOrbit);
    await prefs.setDouble('vehicle_camera_zoom', _vehicleCameraZoom);

    await prefs.setBool('is_no_obd_mode', _isNoObdMode);

    await prefs.setBool('is_performance_mode', _highPerformanceMode);

    await prefs.setBool('is_clone_mode', _isCloneMode);

    await prefs.setBool('is_advanced_mode', _isAdvancedObdMode);

    await prefs.setBool('is_power_saving_mode', _isPowerSavingMode);
    await prefs.setBool('keep_app_active', _keepAppActive);
    await prefs.setBool('use_24_hour_format', _use24HourFormat);
    await prefs.setString('distance_unit', _distanceUnit.name);

    await prefs.setBool('show_welcome_greeting', _showWelcomeGreeting);

    await prefs.setDouble(
      'welcome_greeting_duration',
      _welcomeGreetingDuration,
    );

    await prefs.setInt('welcome_design', _welcomeDesign);

    await prefs.setBool('show_fuel_gauge', _showFuelGauge);

    await prefs.setDouble('simulated_fuel_level', _simulatedFuelLevel);

    await prefs.setDouble('temp_alert_threshold', _tempAlertThreshold);

    await prefs.setDouble('speed_alert_threshold', _speedAlertThreshold);

    await prefs.setBool('temp_warning_enabled', _tempWarningEnabled);

    await prefs.setBool('speed_warning_enabled', _speedWarningEnabled);
    if (_selectedAlertSoundPath != null) {
      await prefs.setString(
        'selected_alert_sound_path',
        _selectedAlertSoundPath!,
      );
    }

    await prefs.setBool('use_simulated_fuel', _useSimulatedFuel);

    await prefs.setBool('is_tutorial_active', _isTutorialActive);

    await prefs.setInt('tutorial_step', _tutorialStep);

    if (_profileImageUrl != null) {
      await prefs.setString('profile_image_url', _profileImageUrl!);
    }

    if (_selectedVehicle != null) {
      await prefs.setString('selected_vehicle_id', _selectedVehicle!.id);
    } else {
      await prefs.remove('selected_vehicle_id');
    }

    final gList = _customGauges.map((g) {
      return jsonEncode({
        'id': g.id,
        'type': g.type,
        'x': g.position.dx,
        'y': g.position.dy,
        'w': g.size.width,
        'h': g.size.height,
        'design': g.design,
        'visible': g.visible,
        'locked': g.locked,
      });
    }).toList();

    await prefs.setStringList('custom_gauges', gList);

    await prefs.setStringList(
      'tesla_app_slots',
      _teslaAppSlots.map((v) => v ?? '').toList(),
    );

    if (_evClusterGlbConfig != null) {
      await prefs.setString(
        'ev_cluster_glb_config',
        jsonEncode({
          'x': _evClusterGlbConfig!.position.dx,
          'y': _evClusterGlbConfig!.position.dy,
          'w': _evClusterGlbConfig!.size.width,
          'h': _evClusterGlbConfig!.size.height,
        }),
      );
    }

    if (_selectedVideoPath != null) {
      await prefs.setString('selected_video_path', _selectedVideoPath!);
    }
    _scheduleCloudSettingsSave();
  }

  Map<String, dynamic> _accountSettingsData() => {
    'selected_style_idx': _selectedStyle.index,
    'downloaded_styles': _downloadedStyles.map((s) => s.name).toList(),
    'temp_unit_idx': _tempUnit.index,
    'language_idx': _language.index,
    'performance_mode_idx': _performanceMode.index,
    'performance_monitoring_enabled': _performanceMonitoringEnabled,
    'accent_color': _accentColor.value,
    'needle_color': _needleColor.value,
    'gauge_color': _gaugeColor.value,
    'map_color': _mapColor.value,
    'light_color': _lightColor.value,
    'light_design': _lightDesign,
    'vehicle_color_hex': _vehicleColorHex,
    'vehicle_camera_orbit': _vehicleCameraOrbit,
    'vehicle_camera_zoom': _vehicleCameraZoom,
    'is_no_obd_mode': _isNoObdMode,
    'is_performance_mode': _highPerformanceMode,
    'is_clone_mode': _isCloneMode,
    'is_advanced_mode': _isAdvancedObdMode,
    'is_power_saving_mode': _isPowerSavingMode,
    'keep_app_active': _keepAppActive,
    'use_24_hour_format': _use24HourFormat,
    'distance_unit': _distanceUnit.name,
    'show_welcome_greeting': _showWelcomeGreeting,
    'welcome_greeting_duration': _welcomeGreetingDuration,
    'welcome_design': _welcomeDesign,
    'show_fuel_gauge': _showFuelGauge,
    'simulated_fuel_level': _simulatedFuelLevel,
    'use_simulated_fuel': _useSimulatedFuel,
    'temp_alert_threshold': _tempAlertThreshold,
    'speed_alert_threshold': _speedAlertThreshold,
    'temp_warning_enabled': _tempWarningEnabled,
    'speed_warning_enabled': _speedWarningEnabled,
    'selected_vehicle_id': _selectedVehicle?.id,
    'tesla_app_slots': _teslaAppSlots.map((v) => v ?? '').toList(),
    'custom_gauges': _customGauges
        .map(
          (g) => jsonEncode({
            'id': g.id,
            'type': g.type,
            'x': g.position.dx,
            'y': g.position.dy,
            'w': g.size.width,
            'h': g.size.height,
            'design': g.design,
            'visible': g.visible,
            'locked': g.locked,
          }),
        )
        .toList(),
    'ev_cluster_glb_config': _evClusterGlbConfig != null
        ? jsonEncode({
            'x': _evClusterGlbConfig!.position.dx,
            'y': _evClusterGlbConfig!.position.dy,
            'w': _evClusterGlbConfig!.size.width,
            'h': _evClusterGlbConfig!.size.height,
          })
        : null,
  };

  CustomGaugeConfig? _evClusterGlbConfig;
  CustomGaugeConfig? get evClusterGlbConfig => _evClusterGlbConfig;

  void updateEvClusterGlb(Offset pos, Size size) {
    _evClusterGlbConfig = CustomGaugeConfig(
      id: 'ev_glb',
      type: 'glb',
      position: pos,
      size: size,
    );
    notifyListeners();
    _saveLocalSettings();
  }

  void _scheduleCloudSettingsSave() {
    if (_disposed || _restoringAccountSettings || !isLoggedIn) return;
    _cloudSettingsSaveTimer?.cancel();
    _cloudSettingsSaveTimer = Timer(const Duration(milliseconds: 700), () {
      SupabaseService.instance.saveUserSettings(_accountSettingsData());
    });
  }

  Future<void> restoreAccountSettings() async {
    if (!isLoggedIn || _restoringAccountSettings) return;
    _restoringAccountSettings = true;
    try {
      final remote = await SupabaseService.instance.loadUserSettings();
      if (remote == null || remote.isEmpty) {
        await SupabaseService.instance.saveUserSettings(_accountSettingsData());
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      for (final entry in remote.entries) {
        final value = entry.value;
        if (value == null) continue;
        if (value is bool) await prefs.setBool(entry.key, value);
        if (value is int) await prefs.setInt(entry.key, value);
        if (value is double) await prefs.setDouble(entry.key, value);
        if (value is String) await prefs.setString(entry.key, value);
        if (value is List) {
          await prefs.setStringList(entry.key, value.map((e) => '$e').toList());
        }
      }
      _loadLocalSettings(prefs);
      notifyListeners();
    } finally {
      _restoringAccountSettings = false;
    }
  }

  Future<void> resetPersonalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final preserved = {
      'onboarding_done',
      'privacy_accepted',
      'analytics_consent',
      for (final key in prefs.getKeys())
        if (key.startsWith('manual_vehicles_v2_') ||
            key.startsWith('vehicles_catalog_'))
          key,
    };
    final values = <String, Object?>{
      for (final key in preserved) key: prefs.get(key),
    };
    await prefs.clear();
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is bool) await prefs.setBool(entry.key, value);
      if (value is String) await prefs.setString(entry.key, value);
    }
    _selectedStyle = DashboardStyle.nightDrive;
    _roadAtlasVehicleOnRight = false;
    _downloadedStyles = {...builtInDashboardStyles};
    _accentColor = const Color(0xFF00E5FF);
    _needleColor = Colors.redAccent;
    _gaugeColor = Colors.white.withOpacity(0.05);
    _mapColor = const Color(0xFF9C27B0);
    _lightColor = const Color(0xFF00E5FF);
    _lightDesign = 0;
    _tempUnit = TemperatureUnit.celsius;
    _language = Language.spanish;
    _performanceMode = PerformanceMode.auto;
    _performanceMonitoringEnabled = values['analytics_consent'] == true;
    _backgroundImage = null;
    _isAssetBackground = true;
    _modelPath = '';
    _vehicleColorHex = '#FFFFFF';
    _isNoObdMode = _highPerformanceMode = _isCloneMode = false;
    _isAdvancedObdMode = _isPowerSavingMode = _keepAppActive = false;
    _use24HourFormat = true;
    _distanceUnit = DistanceUnit.kilometers;
    _showWelcomeGreeting = true;
    _welcomeGreetingDuration = 5;
    _welcomeDesign = 0;
    _showFuelGauge = _useSimulatedFuel = false;
    _simulatedFuelLevel = 100;
    _tempAlertThreshold = 105;
    _speedAlertThreshold = 120;
    _tempWarningEnabled = _speedWarningEnabled = true;
    _selectedAlertSoundPath = null;
    _selectedVehicle = null;
    _selectedVideoPath = null;
    _teslaAppSlots = List<String?>.filled(6, null);
    _customGauges.clear();
    notifyListeners();
    await _saveLocalSettings();
    if (isLoggedIn) {
      await SupabaseService.instance.saveUserSettings(_accountSettingsData());
    }
  }

  // ============================================================
  // SUPABASE PROFILE
  // ============================================================

  DateTime? _lastStatsSyncAt;

  Future<void> _probeInternetAndSync() async {
    if (_dashboardVisible || !_statsPendingSync || !_isAppActive) return;
    try {
      final addresses = await InternetAddress.lookup(
        Uri.parse(BackendConfig.url).host,
      ).timeout(const Duration(seconds: 4));
      if (!_dashboardVisible && addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty) {
        await syncProfileToSupabase(showProgress: true);
      }
    } catch (_) {
      // Sigue pendiente y se reintentará sin mostrar el aviso.
    }
  }

  Future<void> syncProfileToSupabase({bool showProgress = false}) async {
    if (!_isAppActive) return;
    final user = SupabaseService.instance.currentUser;
    final supabase = SupabaseService.instance.client;

    if (user == null || supabase == null) return;

    final now = DateTime.now();
    if (_lastStatsSyncAt != null &&
        now.difference(_lastStatsSyncAt!) < const Duration(minutes: 1)) {
      return;
    }
    _lastStatsSyncAt = now;
    if (_statsPendingSync && showProgress) {
      SyncService.instance.setRankingSyncing(true);
    }

    debugPrint('🚀 [SUPABASE SYNC] Attempting sync for user: ${user.id}');
    debugPrint('📊 [STATS] total_distance: $_totalDistance KM');
    debugPrint('📊 [STATS] max_speed: $_maxSpeed KM/H');

    try {
      final result = await SupabaseService.instance.syncDrivingStats(
        totalDistance: _totalDistance,
        maxSpeed: _maxSpeed,
      );
      if (result == null) {
        if (showProgress) SyncService.instance.setRankingSyncing(false);
        return;
      }

      final serverDistance = (result['total_distance'] as num?)?.toDouble();
      final serverMaxSpeed = (result['max_speed'] as num?)?.toDouble();
      if (serverDistance != null && serverDistance > _totalDistance) {
        _totalDistance = serverDistance;
      }
      if (serverMaxSpeed != null && serverMaxSpeed > _maxSpeed) {
        _maxSpeed = serverMaxSpeed;
      }

      if (result['accepted'] == true) {
        _statsPendingSync = false;
        _statsDirty = true;
        await flushRuntimeStats();
        if (showProgress) SyncService.instance.setRankingSyncing(false);
        debugPrint('✅ [SUPABASE SYNC] Success: Stats synced');
      } else {
        SyncService.instance.setRankingSyncing(false);
        debugPrint(
          'ℹ️ [SUPABASE SYNC] Rejected safely: ${result['error_code']}',
        );
      }
    } catch (e) {
      _statsPendingSync = true;
      _lastStatsSyncAt = null;
      if (showProgress) SyncService.instance.setRankingSyncing(false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stats_pending_sync', true);
      debugPrint('❌ [SUPABASE SYNC] FAILED: $e');
      // No rethrow here to prevent crashing the app, but we print the error clearly
    }
  }

  // ============================================================
  // GENERAL SETTINGS
  // ============================================================

  void toggleHighPerformanceMode(bool value) {
    _highPerformanceMode = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void toggleCloneMode(bool value) {
    _isCloneMode = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void toggleAdvancedObdMode(bool value) {
    _isAdvancedObdMode = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void setKeepAppActive(bool value) {
    _keepAppActive = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    if (vehicle.paintColorHex != null) _vehicleColorHex = vehicle.paintColorHex!;
    unawaited(_resolveVehicleLogo(vehicle, downloadIfMissing: false));
    SyncService.instance.updateSelectedVehicle(vehicle.id);
    if (vehicle.isDownloaded) {
      _modelPath = vehicle.modelPath;
      _backgroundImage = vehicle.backgroundImage;
      _isAssetBackground = vehicle.backgroundImage.startsWith('assets/');
    } else {
      // Clear resources if not downloaded to avoid reusing old ones
      _modelPath = '';
      _backgroundImage = null;
      _isAssetBackground = true;
    }

    notifyListeners();
    _saveLocalSettings();
  }

  Future<void> registerManualVehicle(Vehicle vehicle) async {
    _availableVehicles = [
      ..._availableVehicles.where((v) => v.id != vehicle.id),
      vehicle,
    ];
    await ManualVehicleService.save(_availableVehicles);
    selectVehicle(vehicle);
  }

  void setVehicleColor(String hex) {
    _vehicleColorHex = hex;
    final vehicle = _selectedVehicle;
    if (vehicle != null && vehicle.isCustom) {
      final updated = vehicle.copyWith(paintColorHex: hex);
      _selectedVehicle = updated;
      _availableVehicles = _availableVehicles
          .map((entry) => entry.id == updated.id ? updated : entry).toList();
      unawaited(ManualVehicleService.save(_availableVehicles));
    }
    notifyListeners();
    _saveLocalSettings();
  }

  void setVehicleCameraState(String orbit, double zoom) {
    _vehicleCameraOrbit = orbit;
    _vehicleCameraZoom = zoom;
    notifyListeners();
    _saveLocalSettings();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
    _saveLocalSettings();
  }

  void setNeedleColor(Color color) {
    _needleColor = color;
    notifyListeners();
    _saveLocalSettings();
  }

  void setGaugeColor(Color color) {
    _gaugeColor = color;
    notifyListeners();
    _saveLocalSettings();
  }

  void setMapColor(Color color) {
    _mapColor = color;
    notifyListeners();
    _saveLocalSettings();
  }

  void setLightDesign(int design) {
    _lightDesign = design;
    notifyListeners();
    _saveLocalSettings();
  }

  void setLightColor(Color color) {
    _lightColor = color;
    notifyListeners();
    _saveLocalSettings();
  }

  void setTeslaAppSlot(int index, String? packageName) {
    if (index >= 0 && index < 6) {
      _teslaAppSlots[index] = packageName;
      notifyListeners();
      _saveLocalSettings();
    }
  }

  // ============================================================
  // VEHICLE RESOURCES
  // ============================================================

  Future<bool> downloadVehicleResources() async {
    if (_isDownloadingResources) return false;
    final vehicle = _selectedVehicle;

    if (vehicle == null ||
        vehicle.modelUrl == null ||
        vehicle.modelUrl!.isEmpty) {
      debugPrint('[VEHICLE] Download aborted: No vehicle or modelUrl');
      return false;
    }

    _isDownloadingResources = true;
    _downloadProgress = 0.05;
    _downloadSizeMessage = 'Calculando tamaño...';

    notifyListeners();

    try {
      final modelName = ResourceService.instance.getFileNameFromUrl(
        vehicle.modelUrl!,
      );

      final bgName =
          vehicle.backgroundUrl != null && vehicle.backgroundUrl!.isNotEmpty
          ? ResourceService.instance.getFileNameFromUrl(vehicle.backgroundUrl!)
          : null;

      final size = await ResourceService.instance.getRemoteFileSize(
        vehicle.modelUrl!,
      );

      final sizeMb = size > 0
          ? (size / (1024 * 1024)).toStringAsFixed(1)
          : (size == -1 ? 'Desconocido' : '0.0');

      _downloadSizeMessage = 'Peso: $sizeMb MB';

      _downloadProgress = 0.1;

      notifyListeners();

      // 1. Download GLB
      final modelLocalPath = await ResourceService.instance.downloadFile(
        vehicle.modelUrl!,
        modelName,
        subDir: vehicle.id,
      );

      if (modelLocalPath == null) {
        throw Exception('Model download failed');
      }

      _downloadProgress = 0.4;
      notifyListeners();

      // 2. Download Vehicle Background (if exists)
      String? bgLocalPath;
      if (bgName != null && vehicle.backgroundUrl != null) {
        bgLocalPath = await ResourceService.instance.downloadFile(
          vehicle.backgroundUrl!,
          bgName,
          subDir: vehicle.id,
        );

        if (bgLocalPath == null) {
          throw Exception('Background download failed');
        }
      }

      _downloadProgress = 0.6;
      notifyListeners();

      // Download only the chosen vehicle. Other themes need no shared bitmap pack.
      _downloadProgress = 1.0;

      // VALIDATION: Ensure model exists and has content
      final dFile = File(modelLocalPath);
      final modelExists = await dFile.exists() && await dFile.length() > 0;

      bool bgValid = true;
      if (bgLocalPath != null) {
        final bgFile = File(bgLocalPath);
        bgValid = await bgFile.exists() && await bgFile.length() > 0;
      }

      if (modelExists && bgValid) {
        final downloadedVehicle = vehicle.copyWith(
          isDownloaded: true,
          modelPath: Uri.file(modelLocalPath).toString(),
          backgroundImage: bgLocalPath ?? '',
        );
        if (_selectedVehicle?.id == vehicle.id) {
          _selectedVehicle = downloadedVehicle;
          _modelPath = downloadedVehicle.modelPath;
          _backgroundImage = bgLocalPath;
          _isAssetBackground = false;
        }

        final index = _availableVehicles.indexWhere((v) => v.id == vehicle.id);
        if (index >= 0) _availableVehicles[index] = downloadedVehicle;

        _isDownloadingResources = false;
        notifyListeners();
        _saveLocalSettings();
        return true;
      }

      throw Exception('Invalid file size after download');
    } catch (e) {
      debugPrint('Vehicle resource error: $e');

      // ATOMIC CLEANUP: Delete partial downloads on failure
      await ResourceService.instance.deleteVehicleDirectory(vehicle.id);

      _isDownloadingResources = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // ALERTS
  // ============================================================

  void setTempAlertThreshold(double value) {
    _tempWarningEnabled = true;
    _tempAlertThreshold = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void setSpeedAlertThreshold(double value) {
    _speedWarningEnabled = true;
    _speedAlertThreshold = value;
    notifyListeners();
    _saveLocalSettings();
  }

  Future<void> refreshAlertSounds() async {
    final files = await ResourceService.instance.getLocalFiles('sounds');
    const allowed = {'.mp3', '.wav', '.ogg', '.m4a', '.aac'};
    final paths =
        files
            .where(
              (file) =>
                  allowed.any((ext) => file.path.toLowerCase().endsWith(ext)),
            )
            .map((file) => file.path)
            .toList()
          ..sort();
    _alertSoundPaths = paths;
    if (_selectedAlertSoundPath != null &&
        !paths.contains(_selectedAlertSoundPath)) {
      _selectedAlertSoundPath = null;
    }
    notifyListeners();
  }

  Future<bool> downloadAlertSounds() async {
    if (_isDownloadingAlertSounds) return false;
    _isDownloadingAlertSounds = true;
    notifyListeners();
    final ok = await ResourceService.instance.downloadAndUnzip(
      alertSoundsZipUrl,
      'sounds',
    );
    if (ok) await refreshAlertSounds();
    _isDownloadingAlertSounds = false;
    notifyListeners();
    return ok && _alertSoundPaths.isNotEmpty;
  }

  void selectAlertSound(String path) {
    if (!_alertSoundPaths.contains(path)) return;
    _selectedAlertSoundPath = path;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // TUTORIAL
  // ============================================================

  void startTutorial() {
    _isTutorialActive = true;
    _tutorialStep = 0;

    notifyListeners();
    _saveLocalSettings();
  }

  void setTutorialActive(bool active) {
    _isTutorialActive = active;

    if (!active) {
      _tutorialStep = 0;
    }

    notifyListeners();
    _saveLocalSettings();
  }

  void setTutorialStep(int step) {
    if (!_isTutorialActive) return;

    _tutorialStep = step.clamp(0, _totalTutorialSteps - 1);

    notifyListeners();
    _saveLocalSettings();
  }

  void nextTutorialStep() {
    if (!_isTutorialActive) return;

    if (_tutorialStep < _totalTutorialSteps - 1) {
      _tutorialStep++;

      notifyListeners();
      _saveLocalSettings();

      return;
    }

    finishTutorial();
  }

  void previousTutorialStep() {
    if (!_isTutorialActive) return;

    if (_tutorialStep > 0) {
      _tutorialStep--;

      notifyListeners();
      _saveLocalSettings();
    }
  }

  void finishTutorial() {
    _isTutorialActive = false;
    _tutorialStep = 0;

    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // STYLES
  // ============================================================

  void downloadStyle(DashboardStyle style) {
    _downloadedStyles.add(style);

    notifyListeners();
    _saveLocalSettings();
  }

  void setStyle(DashboardStyle style) {
    if (!_downloadedStyles.contains(style)) {
      return;
    }

    _selectedStyle = style;

    if (style == DashboardStyle.sporty) {
      final vehicleBackground = _selectedVehicle?.backgroundImage;
      if (vehicleBackground != null && vehicleBackground.isNotEmpty) {
        _backgroundImage = vehicleBackground;
        _isAssetBackground = vehicleBackground.startsWith('assets/');
      }
    } else if (style != DashboardStyle.orbitWorld &&
        style != DashboardStyle.hellishRed &&
        style != DashboardStyle.dashcorevideo &&
        style != DashboardStyle.mp4Player) {
      setCarbonBackground();
    }

    if (style == DashboardStyle.orbitWorld) {
      // Orbit has a lightweight procedural sky immediately.
      // Procedural background is now the primary choice for ORBIT.
      _backgroundImage = 'ORBIT_LIVING_STARS';
      _isAssetBackground = false;
      // unawaited(setStarsBackground()); // Removed per user request to use dynamic background
    }

    if (style == DashboardStyle.hellishRed) {
      _backgroundImage = 'DARK_TENUE';
      _isAssetBackground = false;
    }

    if (style != DashboardStyle.gifSpeedo &&
        _backgroundImage != null &&
        _backgroundImage!.contains('gifstore')) {
      _backgroundImage = _selectedVehicle?.backgroundImage;

      _isAssetBackground = _backgroundImage?.startsWith('assets/') ?? true;

      if (_backgroundImage == null) {
        _backgroundImage = 'assets/images/png/car1.png';
        _isAssetBackground = true;
      }
    }

    notifyListeners();
    _saveLocalSettings();
  }

  Future<void> setStarsBackground() async {
    _backgroundImage = 'STARS_LOCAL';
    _isAssetBackground = false;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  void setLanguage(Language lang) {
    _language = lang;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // TEMPERATURE
  // ============================================================

  void setTempUnit(TemperatureUnit unit) {
    _tempUnit = unit;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // FUEL
  // ============================================================

  void toggleShowFuelGauge(bool value) {
    _showFuelGauge = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void toggleUseSimulatedFuel(bool value) {
    _useSimulatedFuel = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void setSimulatedFuelLevel(double value) {
    _simulatedFuelLevel = value.clamp(0.0, 100.0);

    _useSimulatedFuel = true;

    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // OBD / POWER
  // ============================================================

  void toggleNoObdMode(bool value) {
    _isNoObdMode = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void togglePowerSavingMode(bool value) {
    _isPowerSavingMode = value;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // WELCOME
  // ============================================================

  void toggleWelcomeGreeting(bool value) {
    _showWelcomeGreeting = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void setWelcomeGreetingDuration(double seconds) {
    _welcomeGreetingDuration = seconds.clamp(3.0, 15.0);

    notifyListeners();
    _saveLocalSettings();
  }

  void setWelcomeDesign(int design) {
    _welcomeDesign = design;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // SCREEN
  // ============================================================

  void setLastScreenIndex(int index) {
    _lastScreenIndex = index;
    notifyListeners();
    _saveLocalSettings();
  }

  void setHasUpdateAvailable(bool value) {
    _hasUpdateAvailable = value;
    notifyListeners();
  }

  void saveAllSettings() {
    _saveLocalSettings();
  }

  void setProfileImageUrl(String path) {
    _profileImageUrl = path;
    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  void setBackgroundImage(String path, {bool? isAsset}) {
    _backgroundImage = path;
    _isAssetBackground = isAsset ?? path.startsWith('assets/');

    if (path.toLowerCase().endsWith('.gif') && !_isAssetBackground) {
      PaintingBinding.instance.imageCache.evict(FileImage(File(path)));
    }

    notifyListeners();
    _saveLocalSettings();
  }

  void setCarbonBackground() {
    _backgroundImage = 'CARBON_LOCAL';
    _isAssetBackground = false;
    notifyListeners();
    _saveLocalSettings();
  }

  Future<void> _resolveVehicleLogo(
    Vehicle vehicle, {
    required bool downloadIfMissing,
  }) async {
    final brand = vehicle.brand.toLowerCase();
    String? name;
    if (brand.contains('honda')) name = 'HONDA.png';
    if (brand.contains('hyundai')) name = 'Hyundai.png';
    if (brand.contains('kia')) {
      final model = vehicle.name.toLowerCase();
      name = model.contains('k5') || model.contains('optima')
          ? 'KIA2.png'
          : 'KIA1.png';
    }
    if (name == null) {
      _vehicleLogoPath = null;
      notifyListeners();
      return;
    }
    var local = await ResourceService.instance.getLocalFile(
      name,
      subDir: 'logocar',
    );
    if (local == null && downloadIfMissing) {
      // Only a selected brand is requested; no eager four-logo pack.
      final path = await ResourceService.instance.downloadFile(
        '${BackendConfig.storageUrl}/vehicles/logocar/$name',
        name,
        subDir: 'logocar',
        maxBytes: 3 * 1024 * 1024,
      );
      if (path != null) local = File(path);
    }
    _vehicleLogoPath = local?.path;
    notifyListeners();
  }

  // ============================================================
  // TEMPERATURE CONVERSION
  // ============================================================

  double convertTemp(int celsius) {
    if (_tempUnit == TemperatureUnit.celsius) {
      return celsius.toDouble();
    }

    return (celsius * 9 / 5) + 32;
  }

  // ============================================================
  // FUEL SIMULATION
  // ============================================================

  void _startFuelSimulation() {
    _fuelTimer?.cancel();

    _fuelTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_useSimulatedFuel || _simulatedFuelLevel <= 0) {
        return;
      }

      _simulatedFuelLevel -= 0.1;

      if (_simulatedFuelLevel < 0) {
        _simulatedFuelLevel = 0;
      }

      notifyListeners();
    });
  }

  // ============================================================
  // CUSTOM STYLE
  // ============================================================

  void saveAsMyStyle() {
    if (_selectedStyle == DashboardStyle.sketch) {
      _selectedStyle = DashboardStyle.myStyle;

      _downloadedStyles.add(DashboardStyle.myStyle);

      notifyListeners();
      _saveLocalSettings();
    }
  }

  void removeDownloadedStyle(DashboardStyle style) {
    if (builtInDashboardStyles.contains(style)) {
      return;
    }

    _downloadedStyles.remove(style);

    if (_selectedStyle == style) {
      _selectedStyle = DashboardStyle.sporty;
    }

    notifyListeners();
    _saveLocalSettings();
  }

  // ============================================================
  // SKETCH / EDIT MODE
  // ============================================================

  void createNewSketch() {
    if (_customGauges.isNotEmpty) {
      _customGauges.clear();
    }

    _selectedStyle = DashboardStyle.sketch;
    _backgroundImage = null;
    _isAssetBackground = true;
    _isEditMode = true;

    notifyListeners();
    _saveLocalSettings();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;

    notifyListeners();
  }

  // ============================================================
  // CUSTOM GAUGES
  // ============================================================

  void addCustomGauge(String type) {
    _customGauges.add(
      CustomGaugeConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        position: const Offset(100, 100),
      ),
    );

    notifyListeners();
  }

  void updateGaugePosition(String id, Offset pos) {
    final i = _customGauges.indexWhere((g) => g.id == id);

    if (i != -1) {
      _customGauges[i].position = pos;
      notifyListeners();
    }
  }

  void updateGaugeSize(String id, Size size) {
    final i = _customGauges.indexWhere((g) => g.id == id);

    if (i != -1) {
      _customGauges[i].size = size;
      notifyListeners();
    }
  }

  void updateGaugeDesign(String id, int design) {
    final i = _customGauges.indexWhere((g) => g.id == id);

    if (i != -1) {
      _customGauges[i].design = design;
      notifyListeners();
    }
  }

  void updateGaugeCustomization(
    String id, {
    String? logoPath,
    String? customImagePath,
    double? customImageOpacity,
  }) {
    final i = _customGauges.indexWhere((g) => g.id == id);

    if (i != -1) {
      if (logoPath != null) {
        _customGauges[i].logoPath = logoPath;
      }

      if (customImagePath != null) {
        _customGauges[i].customImagePath = customImagePath;
      }

      if (customImageOpacity != null) {
        _customGauges[i].customImageOpacity = customImageOpacity;
      }

      notifyListeners();
    }
  }

  void removeCustomGauge(String id) {
    _customGauges.removeWhere((g) => g.id == id);

    notifyListeners();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _disposed = true;
    if (_localSettingsSaveTimer != null) unawaited(_persistLocalSettings());
    _localSettingsSaveTimer?.cancel();
    if (_localSettingsSaveCompleter?.isCompleted == false)
      _localSettingsSaveCompleter!.complete();
    _fuelTimer?.cancel();
    _statsTimer?.cancel();
    _statsSaveTimer?.cancel();
    _cloudSettingsSaveTimer?.cancel();
    _authSubscription?.cancel();
    flushRuntimeStats();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
