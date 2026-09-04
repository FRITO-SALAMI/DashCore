import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';
import '../services/resource_service.dart';

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
}

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

  DashboardStyle _selectedStyle = DashboardStyle.sporty;
  Set<DashboardStyle> _downloadedStyles = {DashboardStyle.sporty};

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

  bool _isNoObdMode = false;
  bool _highPerformanceMode = false;
  bool _isPowerSavingMode = false;
  PerformanceMode _performanceMode = PerformanceMode.auto;
  bool _performanceMonitoringEnabled = false;

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

  String? _profileImageUrl;
  List<String?> _teslaAppSlots = List<String?>.filled(6, null);

  Timer? _fuelTimer;
  Timer? _statsTimer;
  Timer? _statsSaveTimer;
  DateTime? _lastDrivingSampleAt;
  bool _isAppActive = true;
  bool _statsDirty = false;

  Vehicle? _selectedVehicle;
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

  bool _isLowResourceDevice = false;
  String _deviceArchitecture = 'Desconocida';

  // ============================================================
  // GETTERS
  // ============================================================

  DashboardStyle get selectedStyle => _selectedStyle;

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

  bool get isNoObdMode => _isNoObdMode;

  bool get highPerformanceMode => _highPerformanceMode;

  bool get isPowerSavingMode => _isPowerSavingMode;

  PerformanceMode get performanceMode => _performanceMode;

  bool get performanceMonitoringEnabled => _performanceMonitoringEnabled;

  bool get isLowResourceDevice => _isLowResourceDevice;

  bool get isAppActive => _isAppActive;

  /// Maximum visual telemetry refresh rate. Expensive dashboards remain
  /// available on low-resource devices, but receive fewer UI updates.
  int get telemetryFramesPerSecond {
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

  bool get tempWarningEnabled => _tempWarningEnabled;

  bool get speedWarningEnabled => _speedWarningEnabled;

  Vehicle? get selectedVehicle => _selectedVehicle;

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

  Future<void> loadDownloadedGifs() async {
    _downloadedGifs = await ResourceService.instance.getLocalFiles('gifstore');
    notifyListeners();
  }

  Future<bool> downloadGifPack() async {
    _isDownloadingGifs = true;
    notifyListeners();
    try {
      const url = 'https://pvcfwpziojocogfctgbw.supabase.co/storage/v1/object/public/vehicles/config/gifstore.zip';
      final success = await ResourceService.instance.downloadAndUnzip(url, 'gifstore');
      if (success) {
        await loadDownloadedGifs();
      }
      return success;
    } finally {
      _isDownloadingGifs = false;
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
    _loadSettings();
    _loadRemoteVehicles();
    loadDownloadedGifs();
    _startFuelSimulation();
    _startStatsTimer();
    _detectDeviceCapabilities();
    _setupAuthListener();
  }

  Future<void> _loadRemoteVehicles() async {
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
          final modelName = ResourceService.instance.getFileNameFromUrl(modelUrl);
          final bgName = bgUrl != null ? ResourceService.instance.getFileNameFromUrl(bgUrl) : null;

          final localModel = await ResourceService.instance.getLocalFile(modelName, subDir: vehicle.id);
          final localBg = bgName != null ? await ResourceService.instance.getLocalFile(bgName, subDir: vehicle.id) : null;

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
      _availableVehicles = vehicles;

      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selected_vehicle_id');
      if (selectedId != null) {
        for (final vehicle in vehicles) {
          if (vehicle.id == selectedId) {
            _selectedVehicle = vehicle;
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
      _availableVehicles = const [];
    } finally {
      _vehiclesLoading = false;
      notifyListeners();
    }
  }

  void _setupAuthListener() {
    SupabaseService.instance.client?.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        syncProfileToSupabase();
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

      final isArm32 =
          androidInfo.supportedAbis.contains('armeabi-v7a') &&
          !androidInfo.supportedAbis.contains('arm64-v8a');

      _deviceArchitecture = isArm32 ? 'ARM 32-bit' : 'ARM 64-bit';

      _isLowResourceDevice = isOlder || isArm32;

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
      if (!isDriving) return;
      _totalDriveTime += const Duration(minutes: 1);
      _scheduleStatsSave();
      notifyListeners();
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
    ]);
  }

  void setAppActive(bool active) {
    if (_isAppActive == active) return;
    _isAppActive = active;
    if (!active) {
      _lastDrivingSampleAt = null;
      flushRuntimeStats();
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

    AnalyticsService.instance.updateConsent(
      granted: _analyticsConsent,
      version: _consentVersion,
    );

    notifyListeners();
  }

  void _loadLocalSettings(SharedPreferences prefs) {
    final styleIndex = prefs.getInt('selected_style_idx') ?? 0;

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

      _downloadedStyles.add(DashboardStyle.sporty);
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

    _isNoObdMode = prefs.getBool('is_no_obd_mode') ?? false;

    _highPerformanceMode = prefs.getBool('high_performance_mode') ?? false;

    _isPowerSavingMode = prefs.getBool('is_power_saving_mode') ?? false;

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

    _totalDistance = prefs.getDouble('stat_total_dist') ?? 0.0;

    _totalTrips = prefs.getInt('stat_total_trips') ?? 0;

    _maxSpeed = prefs.getDouble('stat_max_speed') ?? 0.0;

    _totalDriveTime = Duration(
      seconds: prefs.getInt('stat_total_time_sec') ?? 0,
    );

    _useSimulatedFuel = prefs.getBool('use_simulated_fuel') ?? false;

    _isTutorialActive = prefs.getBool('is_tutorial_active') ?? false;

    _tutorialStep = prefs.getInt('tutorial_step') ?? 0;

    if (_tutorialStep < 0 || _tutorialStep >= _totalTutorialSteps) {
      _tutorialStep = 0;
    }

    _profileImageUrl = prefs.getString('profile_image_url');

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
  }

  // ============================================================
  // SAVE SETTINGS
  // ============================================================

  Future<void> _saveLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _syncProfileToSupabase();

    await prefs.setInt('selected_style_idx', _selectedStyle.index);

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

    await prefs.setBool('is_no_obd_mode', _isNoObdMode);

    await prefs.setBool('high_performance_mode', _highPerformanceMode);

    await prefs.setBool('is_power_saving_mode', _isPowerSavingMode);

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

    await prefs.setBool('use_simulated_fuel', _useSimulatedFuel);

    await prefs.setBool('is_tutorial_active', _isTutorialActive);

    await prefs.setInt('tutorial_step', _tutorialStep);

    if (_profileImageUrl != null) {
      await prefs.setString('profile_image_url', _profileImageUrl!);
    }

    if (_selectedVehicle != null) {
      await prefs.setString('selected_vehicle_id', _selectedVehicle!.id);
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
  }

  // ============================================================
  // SUPABASE PROFILE
  // ============================================================

  Future<void> syncProfileToSupabase() async {
    final user = SupabaseService.instance.currentUser;
    final supabase = SupabaseService.instance.client;

    if (user == null || supabase == null) return;

    debugPrint('🚀 [SUPABASE SYNC] Attempting sync for user: ${user.id}');
    debugPrint('📊 [STATS] total_distance: $_totalDistance KM');
    debugPrint('📊 [STATS] max_speed: $_maxSpeed KM/H');

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'username':
            user.userMetadata?['display_name'] ??
            user.email?.split('@')[0] ??
            'CONDUCTOR',
        'total_distance': _totalDistance,
        'max_speed': _maxSpeed,
        'driver_level': driverLevel,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
      debugPrint('✅ [SUPABASE SYNC] Success: Stats synced');
    } catch (e) {
      debugPrint('❌ [SUPABASE SYNC] FAILED: $e');
      // No rethrow here to prevent crashing the app, but we print the error clearly
    }
  }

  void _syncProfileToSupabase() => syncProfileToSupabase();

  // ============================================================
  // GENERAL SETTINGS
  // ============================================================

  void toggleHighPerformanceMode(bool value) {
    _highPerformanceMode = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
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

  void setVehicleColor(String hex) {
    _vehicleColorHex = hex;
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
    final vehicle = _selectedVehicle;

    if (vehicle == null || vehicle.modelUrl == null || vehicle.modelUrl!.isEmpty) {
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

      final bgName = vehicle.backgroundUrl != null && vehicle.backgroundUrl!.isNotEmpty
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

      // 3. Download Shared Backgrounds (Carbon, car1, FondoHellisg)
      const sharedBaseUrl = 'https://pvcfwpziojocogfctgbw.supabase.co/storage/v1/object/public/vehicles/backgrounds';
      final sharedFiles = ['carbon_fiber.jpg', 'car1.png', 'FondoHellisg.jpg'];

      for (int i = 0; i < sharedFiles.length; i++) {
        final fileName = sharedFiles[i];
        await ResourceService.instance.downloadFile(
          '$sharedBaseUrl/$fileName',
          fileName,
          subDir: 'general',
        );
        _downloadProgress = 0.6 + (0.3 * (i + 1) / sharedFiles.length);
        notifyListeners();
      }

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
        _modelPath = 'file://$modelLocalPath';
        _backgroundImage = bgLocalPath;
        _isAssetBackground = false;

        _selectedVehicle = vehicle.copyWith(
          isDownloaded: true,
          modelPath: _modelPath,
          backgroundImage: _backgroundImage ?? '',
        );

        final index = _availableVehicles.indexWhere((v) => v.id == vehicle.id);
        if (index >= 0) _availableVehicles[index] = _selectedVehicle!;

        _isDownloadingResources = false;
        notifyListeners();
        _saveLocalSettings();
        return true;
      }

      throw Exception('Invalid file size after download');
    } catch (e) {
      debugPrint('Vehicle resource error: $e');

      // ATOMIC CLEANUP: Delete partial downloads on failure
      if (vehicle != null) {
        await ResourceService.instance.deleteVehicleDirectory(vehicle.id);
      }

      _isDownloadingResources = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // ALERTS
  // ============================================================

  void setTempAlertThreshold(double value) {
    _tempAlertThreshold = value;
    notifyListeners();
    _saveLocalSettings();
  }

  void setSpeedAlertThreshold(double value) {
    _speedAlertThreshold = value;
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

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    _selectedStyle = style;

    // Default background for NeonWorld
    if (style == DashboardStyle.neonWorld) {
      _resolveGeneralBackground('carbon_fiber.jpg', fallback: 'assets/images/png/carbon_fiber.jpg');
    }

    if (style == DashboardStyle.hellishRed) {
      _resolveGeneralBackground('FondoHellisg.jpg', fallback: 'assets/images/png/FondoHellisg.jpg');
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

  Future<void> _resolveGeneralBackground(String fileName, {required String fallback}) async {
    final local = await ResourceService.instance.getLocalFile(fileName, subDir: 'general');
    if (local != null) {
      _backgroundImage = local.path;
      _isAssetBackground = false;
    } else {
      _backgroundImage = fallback;
      _isAssetBackground = true;
    }
    notifyListeners();
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

  void setBackgroundImage(String path, {bool isAsset = true}) {
    _backgroundImage = path;
    _isAssetBackground = isAsset;

    notifyListeners();
    _saveLocalSettings();
  }

  void setCarbonBackground() {
    _resolveGeneralBackground('carbon_fiber.jpg', fallback: 'assets/images/png/carbon_fiber.jpg');
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
    if (style == DashboardStyle.sporty) {
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
    _fuelTimer?.cancel();
    _statsTimer?.cancel();
    _statsSaveTimer?.cancel();
    flushRuntimeStats();
    super.dispose();
  }
}
