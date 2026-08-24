import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';
import '../services/resource_service.dart';

enum DashboardStyle {
  sporty,
  racing,
  modern,
  vehicle3D,
  purplePuff,
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
}

enum TemperatureUnit {
  celsius,
  fahrenheit,
}

enum Language {
  spanish,
  english,
}

class CustomGaugeConfig {
  final String id;
  final String type;
  Offset position;
  Size size;
  int design;
  String? logoPath;
  String? customImagePath;
  double customImageOpacity;

  CustomGaugeConfig({
    required this.id,
    required this.type,
    required this.position,
    this.size = const Size(100, 100),
    this.design = 0,
    this.logoPath,
    this.customImagePath,
    this.customImageOpacity = 1.0,
  });
}

class DashSettingsProvider extends ChangeNotifier {
  DashboardStyle _selectedStyle = DashboardStyle.sporty;

  Set<DashboardStyle> _downloadedStyles = {
    DashboardStyle.sporty,
    DashboardStyle.teslaRoad,
    DashboardStyle.teslaModel,
  };

  Color _accentColor = const Color(0xFF00E5FF);
  Color _needleColor = Colors.redAccent;
  Color _gaugeColor = Colors.white.withOpacity(0.05);

  bool _isEditMode = false;
  int _lastScreenIndex = 0;

  final List<CustomGaugeConfig> _customGauges = [];

  TemperatureUnit _tempUnit = TemperatureUnit.celsius;

  Language _language = Language.spanish;

  String? _backgroundImage = 'assets/images/png/car1.png';

  bool _isAssetBackground = true;

  String _modelPath = 'assets/Models/OPTIMA2012.glb';

  bool _isNoObdMode = false;

  bool _isPerformanceMode = false;

  bool _isAdvancedMode = false;
  bool _isPowerSavingMode = false;

  bool _showWelcomeGreeting = true;

  double _welcomeGreetingDuration = 5.0;

  int _welcomeDesign = 0;

  Color _lightColor = const Color(0xFF00E5FF);

  int _lightDesign = 0;

  double _simulatedFuelLevel = 100.0;

  bool _useSimulatedFuel = false;

  String? _profileImageUrl;

  List<String?> _teslaAppSlots = List<String?>.filled(6, null);

  Timer? _fuelTimer;
  Timer? _statsTimer;

  Vehicle? _selectedVehicle;

  // Estadísticas de conducción
  double _totalDistance = 0.0;
  int _totalTrips = 0;
  double _maxSpeed = 0.0;
  Duration _totalDriveTime = Duration.zero;
  double _avgSpeed = 0.0;
  
  // Nivel de conductor (Perfil)
  String get driverLevel {
    if (_totalDistance > 1000) return 'LEYENDA DEL ASFALTO';
    if (_totalDistance > 500) return 'EXPERTO DASHCORE';
    if (_totalDistance > 100) return 'CONDUCTOR AVANZADO';
    if (_totalDistance > 20) return 'ENTUSIASTA';
    return 'PRINCIPIANTE';
  }

  double get totalDistance => _totalDistance;
  int get totalTrips => _totalTrips;
  double get maxSpeed => _maxSpeed;
  Duration get totalDriveTime => _totalDriveTime;
  double get avgSpeed => _avgSpeed;

  bool _isDownloadingResources = false;
  double _downloadProgress = 0.0;
  String _downloadSizeMessage = 'Calculando...';

  DashboardStyle get selectedStyle => _selectedStyle;

  Set<DashboardStyle> get downloadedStyles => _downloadedStyles;

  Color get accentColor => _accentColor;
  Color get needleColor => _needleColor;
  Color get gaugeColor => _gaugeColor;

  bool get isEditMode => _isEditMode;
  int get lastScreenIndex => _lastScreenIndex;

  List<CustomGaugeConfig> get customGauges => _customGauges;

  TemperatureUnit get tempUnit => _tempUnit;

  Language get language => _language;

  String? get backgroundImage => _backgroundImage;

  bool get isAssetBackground => _isAssetBackground;

  String get modelPath => _modelPath;

  bool get isNoObdMode => _isNoObdMode;

  bool get isPerformanceMode => _isPerformanceMode;

  bool get isAdvancedMode => _isAdvancedMode;
  bool get isPowerSavingMode => _isPowerSavingMode;

  bool get showWelcomeGreeting => _showWelcomeGreeting;

  double get welcomeGreetingDuration => _welcomeGreetingDuration;

  int get welcomeDesign => _welcomeDesign;

  Color get lightColor => _lightColor;

  int get lightDesign => _lightDesign;

  double get simulatedFuelLevel => _simulatedFuelLevel;

  bool get useSimulatedFuel => _useSimulatedFuel;

  List<String?> get teslaAppSlots => _teslaAppSlots;

  String? get profileImageUrl => _profileImageUrl;

  Vehicle? get selectedVehicle => _selectedVehicle;

  bool get isDownloadingResources => _isDownloadingResources;
  double get downloadProgress => _downloadProgress;
  String get downloadSizeMessage => _downloadSizeMessage;

  List<Vehicle> _availableVehicles = [...defaultVehicles];

  List<Vehicle> get availableVehicles => _availableVehicles;

  DashSettingsProvider() {
    _loadSettings();
    _startFuelSimulation();
    _startStatsTimer();
    loadAvailableVehicles();
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Simular que si la app está abierta, el tiempo de conducción aumenta si hay velocidad
      // Esto se refinará al recibir datos OBD reales en el provider de OBD
      _saveLocalSettings();
    });
  }

  void updateStats(double speed, double distanceDelta) {
    if (speed > _maxSpeed) _maxSpeed = speed;
    _totalDistance += distanceDelta;
    
    // Recalcular promedio aproximado
    if (_totalDistance > 0) {
      // Muy simplificado para este ejemplo
    }
    notifyListeners();
  }

  void incrementTrips() {
    _totalTrips++;
    notifyListeners();
    _saveLocalSettings();
  }

  Future<void> loadAvailableVehicles() async {
    try {
      final supabaseVehicles = await SupabaseService.instance.getVehicles();
      if (supabaseVehicles.isNotEmpty) {
        final List<Vehicle> vehicles = [];
        
        for (var data in supabaseVehicles) {
          final modelUrl = data['model_url'] ?? '';
          final modelFile = ResourceService.instance.getFileNameFromUrl(modelUrl);
          final isDownloaded = await ResourceService.instance.isFileDownloaded(modelFile);
          
          String modelPath = modelUrl;
          String bgPath = data['background_url'] ?? '';
          
          if (isDownloaded) {
            final localModel = await ResourceService.instance.getLocalFile(modelFile);
            if (localModel != null) {
              modelPath = localModel.path;
              // Add file:// prefix for model_viewer_plus on Android/iOS
              if (!modelPath.startsWith('assets/') && !modelPath.startsWith('http')) {
                 modelPath = 'file://$modelPath';
              }
            }
            
            final bgFile = ResourceService.instance.getFileNameFromUrl(bgPath);
            final localBg = await ResourceService.instance.getLocalFile(bgFile);
            if (localBg != null) bgPath = localBg.path;
          }
          
          vehicles.add(Vehicle.fromSupabase(
            data, 
            downloaded: isDownloaded,
            localModel: isDownloaded ? modelPath : null,
            localBg: isDownloaded ? bgPath : null,
          ));
        }
        
        _availableVehicles = vehicles;
        
        // Update current selected vehicle if it was from Supabase
        if (_selectedVehicle != null) {
          final updated = _availableVehicles.firstWhere(
            (v) => v.id == _selectedVehicle!.id,
            orElse: () => _selectedVehicle!,
          );
          _selectedVehicle = updated;
          _modelPath = updated.modelPath;
          _backgroundImage = updated.backgroundImage;
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  @override
  void dispose() {
    _fuelTimer?.cancel();
    super.dispose();
  }

  void _startFuelSimulation() {
    _fuelTimer?.cancel();

    _fuelTimer = Timer.periodic(
      const Duration(seconds: 30),
          (timer) {
        if (!_useSimulatedFuel || _simulatedFuelLevel <= 0) {
          return;
        }

        _simulatedFuelLevel -= 0.1;

        if (_simulatedFuelLevel < 0) {
          _simulatedFuelLevel = 0;
        }

        notifyListeners();
        _saveLocalSettings();
      },
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _loadLocalSettings(prefs);
      
      // Initial check for selected vehicle resources
      await _refreshSelectedVehicleState();

      await _loadSupabaseSettings();
      
      // Final check after Supabase load
      await _refreshSelectedVehicleState();

      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<void> _refreshSelectedVehicleState() async {
    if (_selectedVehicle == null) return;

    debugPrint('[VEHICLE] Selected vehicle: ${_selectedVehicle!.name}');
    debugPrint('[VEHICLE] Model URL: ${_selectedVehicle!.modelUrl}');

    if (!_selectedVehicle!.modelPath.startsWith('assets/')) {
      final modelFileStr = ResourceService.instance.getFileNameFromUrl(_selectedVehicle!.modelUrl ?? '');
      debugPrint('[VEHICLE] Checking local model: $modelFileStr');
      
      final exists = await ResourceService.instance.isFileDownloaded(modelFileStr);
      debugPrint('[VEHICLE] Local model exists: $exists');

      if (exists) {
        final localFileRes = await ResourceService.instance.getLocalFile(modelFileStr);
        if (localFileRes != null && await localFileRes.length() > 0) {
          // Use absolute path with file:/// prefix
          _modelPath = 'file://${localFileRes.path}';
          debugPrint('[VEHICLE] Using LOCAL model path: $_modelPath');
          
          _selectedVehicle = _selectedVehicle!.copyWith(
            modelPath: _modelPath,
            isDownloaded: true,
          );
        } else {
          debugPrint('[VEHICLE] Local model is corrupted or empty. Marking for re-download.');
          _selectedVehicle = _selectedVehicle!.copyWith(isDownloaded: false);
        }
      } else {
        _modelPath = _selectedVehicle!.modelUrl ?? _selectedVehicle!.modelPath;
        _selectedVehicle = _selectedVehicle!.copyWith(isDownloaded: false);
      }
    } else {
      debugPrint('[VEHICLE] Using ASSET model: ${_selectedVehicle!.modelPath}');
      _selectedVehicle = _selectedVehicle!.copyWith(isDownloaded: true);
    }
    
    notifyListeners();
    debugPrint('[VEHICLE] Notifying listeners. isDownloaded: ${_selectedVehicle!.isDownloaded}');
  }

  void _loadLocalSettings(SharedPreferences prefs) {
    final styleIndex = prefs.getInt('selected_style_idx');

    if (styleIndex != null &&
        styleIndex >= 0 &&
        styleIndex < DashboardStyle.values.length) {
      _selectedStyle = DashboardStyle.values[styleIndex];
    }

    final downloadedList = prefs.getStringList('downloaded_styles');

    if (downloadedList != null) {
      _downloadedStyles = downloadedList
          .map(_styleFromName)
          .whereType<DashboardStyle>()
          .toSet();

      _downloadedStyles.add(DashboardStyle.sporty);
    }

    final tempIndex = prefs.getInt('temp_unit_idx') ?? 0;

    if (tempIndex >= 0 &&
        tempIndex < TemperatureUnit.values.length) {
      _tempUnit = TemperatureUnit.values[tempIndex];
    }

    final languageIndex = prefs.getInt('language_idx') ?? 0;

    if (languageIndex >= 0 &&
        languageIndex < Language.values.length) {
      _language = Language.values[languageIndex];
    }

    final accentValue = prefs.getInt('accent_color');
    if (accentValue != null) {
      _accentColor = Color(accentValue);
    }

    _needleColor = Color(prefs.getInt('needle_color') ?? Colors.redAccent.value);
    _gaugeColor = Color(prefs.getInt('gauge_color') ?? Colors.white.withOpacity(0.05).value);
    _lastScreenIndex = prefs.getInt('last_screen_index') ?? 0;

    _backgroundImage =
        prefs.getString('background_image') ?? _backgroundImage;

    _isAssetBackground =
        prefs.getBool('is_asset_background') ?? true;

    _modelPath =
        prefs.getString('model_path') ?? _modelPath;

    _isNoObdMode =
        prefs.getBool('is_no_obd_mode') ?? false;

    _isPerformanceMode =
        prefs.getBool('is_performance_mode') ?? false;

    _isAdvancedMode =
        prefs.getBool('is_advanced_mode') ?? false;

    _isPowerSavingMode =
        prefs.getBool('is_power_saving_mode') ?? false;

    _showWelcomeGreeting =
        prefs.getBool('show_welcome_greeting') ?? true;

    _welcomeGreetingDuration =
        prefs.getDouble('welcome_greeting_duration') ?? 5.0;

    _welcomeDesign = prefs.getInt('welcome_design') ?? 0;

    _lightColor = Color(
      prefs.getInt('light_color') ?? 0xFF00E5FF,
    );

    _lightDesign =
        prefs.getInt('light_design') ?? 0;

    _simulatedFuelLevel =
        prefs.getDouble('simulated_fuel_level') ?? 100.0;

    _totalDistance = prefs.getDouble('stat_total_dist') ?? 0.0;
    _totalTrips = prefs.getInt('stat_total_trips') ?? 0;
    _maxSpeed = prefs.getDouble('stat_max_speed') ?? 0.0;
    _avgSpeed = prefs.getDouble('stat_avg_speed') ?? 0.0;
    _totalDriveTime = Duration(seconds: prefs.getInt('stat_total_time_sec') ?? 0);

    _useSimulatedFuel =
        prefs.getBool('use_simulated_fuel') ?? false;

    final savedTeslaSlots =
    prefs.getStringList('tesla_app_slots');

    if (savedTeslaSlots != null &&
        savedTeslaSlots.length == 6) {
      _teslaAppSlots = savedTeslaSlots
          .map<String?>(
            (value) => value.isEmpty ? null : value,
      )
          .toList();
    } else {
      _teslaAppSlots =
      List<String?>.filled(6, null);
    }

    final savedGauges = prefs.getStringList('custom_gauges');
    if (savedGauges != null) {
      _customGauges.clear();
      for (var gaugeStr in savedGauges) {
        try {
          final map = jsonDecode(gaugeStr);
          _customGauges.add(CustomGaugeConfig(
            id: map['id'],
            type: map['type'],
            position: Offset(map['x'], map['y']),
            size: Size(map['w'], map['h']),
            design: map['design'] ?? 0,
            logoPath: map['logoPath'],
            customImagePath: map['customImagePath'],
            customImageOpacity: (map['customImageOpacity'] ?? 1.0).toDouble(),
          ));
        } catch (e) {
          debugPrint('Error loading gauge: $e');
        }
      }
    }

    final vehicleId =
    prefs.getString('selected_vehicle_id');

    if (vehicleId != null) {
      _selectedVehicle = defaultVehicles.firstWhere(
            (vehicle) => vehicle.id == vehicleId,
        orElse: () => defaultVehicles.first,
      );
    }
  }

  Future<void> _loadSupabaseSettings() async {
    if (!SupabaseService.instance.isLoggedIn) {
      return;
    }

    try {
      final styles =
      await SupabaseService.instance.loadUserStyles();

      if (styles.isNotEmpty) {
        _downloadedStyles = styles
            .map(_styleFromName)
            .whereType<DashboardStyle>()
            .toSet();

        _downloadedStyles.add(DashboardStyle.sporty);
      }

      final data =
      await SupabaseService.instance.loadUserSettings();

      if (data == null) {
        await _syncSupabase();
        return;
      }

      final styleName = data['selected_style'];

      if (styleName is String) {
        final style = _styleFromName(styleName);

        if (style != null &&
            _downloadedStyles.contains(style)) {
          _selectedStyle = style;
        }
      }

      final accentValue = data['accent_color'];

      if (accentValue is int) {
        _accentColor = Color(accentValue);
      } else if (accentValue is String) {
        final parsedColor = _parseColor(accentValue);

        if (parsedColor != null) {
          _accentColor = parsedColor;
        }
      }

      final tempUnit = data['temp_unit'];

      if (tempUnit is String) {
        _tempUnit = _tempUnitFromName(tempUnit);
      }

      final language = data['language'];

      if (language is String) {
        _language = language == 'en'
            ? Language.english
            : _languageFromName(language);
      }

      final backgroundPath =
      data['background_path'];

      if (backgroundPath is String) {
        _backgroundImage = backgroundPath;

        _isAssetBackground =
            backgroundPath.startsWith('assets/') ||
                backgroundPath == 'COLOR_BLACK';
      }

      final modelPath = data['model_path'];

      if (modelPath is String &&
          modelPath.isNotEmpty) {
        _modelPath = modelPath;
      }

      _profileImageUrl = data['avatar_url'];

      final teslaSlots = data['tesla_app_slots'];
      if (teslaSlots is List) {
         _teslaAppSlots = teslaSlots.map((e) => e?.toString()).toList();
         while (_teslaAppSlots.length < 6) {
           _teslaAppSlots.add(null);
         }
      }

      await _saveLocalSettings();
    } catch (_) {
      // Se mantienen los datos locales.
    }
  }

  Color? _parseColor(String value) {
    var colorString = value.trim();

    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }

    if (colorString.length == 6) {
      colorString = 'FF$colorString';
    }

    if (colorString.length != 8) {
      return null;
    }

    final parsedValue = int.tryParse(
      colorString,
      radix: 16,
    );

    if (parsedValue == null) {
      return null;
    }

    return Color(parsedValue);
  }

  DashboardStyle? _styleFromName(String name) {
    for (final style in DashboardStyle.values) {
      if (style.name == name) {
        return style;
      }
    }

    return null;
  }

  TemperatureUnit _tempUnitFromName(String name) {
    return TemperatureUnit.values.firstWhere(
          (unit) => unit.name == name,
      orElse: () => TemperatureUnit.celsius,
    );
  }

  Language _languageFromName(String name) {
    if (name == 'en') {
      return Language.english;
    }

    return Language.values.firstWhere(
          (language) => language.name == name,
      orElse: () => Language.spanish,
    );
  }

  Future<void> _saveSettings() async {
    await _saveLocalSettings();
    await _syncSupabase();
  }

  Future<void> _saveLocalSettings() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt('last_screen_index', _lastScreenIndex);
    await prefs.setInt('needle_color', _needleColor.value);
    await prefs.setInt('gauge_color', _gaugeColor.value);

    await prefs.setInt(
      'selected_style_idx',
      _selectedStyle.index,
    );

    await prefs.setStringList(
      'downloaded_styles',
      _downloadedStyles
          .map((style) => style.name)
          .toList(),
    );

    await prefs.setInt(
      'temp_unit_idx',
      _tempUnit.index,
    );

    await prefs.setInt(
      'language_idx',
      _language.index,
    );

    await prefs.setInt(
      'accent_color',
      _accentColor.value,
    );

    if (_backgroundImage != null) {
      await prefs.setString(
        'background_image',
        _backgroundImage!,
      );
    } else {
      await prefs.remove('background_image');
    }

    await prefs.setBool(
      'is_asset_background',
      _isAssetBackground,
    );

    await prefs.setString(
      'model_path',
      _modelPath,
    );

    await prefs.setBool(
      'is_no_obd_mode',
      _isNoObdMode,
    );

    await prefs.setBool(
      'is_performance_mode',
      _isPerformanceMode,
    );

    await prefs.setBool(
      'is_advanced_mode',
      _isAdvancedMode,
    );

    await prefs.setBool(
      'is_power_saving_mode',
      _isPowerSavingMode,
    );

    await prefs.setBool(
      'show_welcome_greeting',
      _showWelcomeGreeting,
    );

    await prefs.setDouble(
      'welcome_greeting_duration',
      _welcomeGreetingDuration,
    );

    await prefs.setInt(
      'welcome_design',
      _welcomeDesign,
    );

    await prefs.setInt(
      'light_color',
      _lightColor.value,
    );

    await prefs.setInt(
      'light_design',
      _lightDesign,
    );

    await prefs.setDouble(
      'simulated_fuel_level',
      _simulatedFuelLevel,
    );

    await prefs.setDouble('stat_total_dist', _totalDistance);
    await prefs.setInt('stat_total_trips', _totalTrips);
    await prefs.setDouble('stat_max_speed', _maxSpeed);
    await prefs.setDouble('stat_avg_speed', _avgSpeed);
    await prefs.setInt('stat_total_time_sec', _totalDriveTime.inSeconds);

    await prefs.setBool(
      'use_simulated_fuel',
      _useSimulatedFuel,
    );

    await prefs.setStringList(
      'tesla_app_slots',
      _teslaAppSlots
          .map((value) => value ?? '')
          .toList(),
    );

    final gaugeList = _customGauges.map((g) => jsonEncode({
      'id': g.id,
      'type': g.type,
      'x': g.position.dx,
      'y': g.position.dy,
      'w': g.size.width,
      'h': g.size.height,
      'design': g.design,
      'logoPath': g.logoPath,
      'customImagePath': g.customImagePath,
      'customImageOpacity': g.customImageOpacity,
    })).toList();
    await prefs.setStringList('custom_gauges', gaugeList);

    if (_profileImageUrl != null) {
      await prefs.setString('profile_image_url', _profileImageUrl!);
    }

    if (_selectedVehicle != null) {
      await prefs.setString(
        'selected_vehicle_id',
        _selectedVehicle!.id,
      );
    } else {
      await prefs.remove('selected_vehicle_id');
    }
  }

  Future<void> _syncSupabase() async {
    if (!SupabaseService.instance.isLoggedIn) {
      return;
    }

    try {
      await SupabaseService.instance.saveUserSettings({
        'selected_style': _selectedStyle.name,
        'accent_color':
        '#${_accentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'temp_unit': _tempUnit.name,
        'language':
        _language == Language.spanish ? 'es' : 'en',
        'background_path': _backgroundImage,
        'model_path': _modelPath,
        'avatar_url': _profileImageUrl,
        'tesla_app_slots': _teslaAppSlots,
      });

      await SupabaseService.instance.saveUserStyles(
        _downloadedStyles
            .map((style) => style.name)
            .toList(),
      );
    } catch (_) {
      // Supabase no disponible.
    }
  }

  void setLastScreenIndex(int index) {
    _lastScreenIndex = index;
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

  void toggleNoObdMode(bool value) {
    _isNoObdMode = value;
    notifyListeners();
    _saveSettings();
  }

  void togglePerformanceMode(bool value) {
    _isPerformanceMode = value;
    notifyListeners();
    _saveSettings();
  }

  void toggleAdvancedMode(bool value) {
    _isAdvancedMode = value;
    notifyListeners();
    _saveSettings();
  }

  void togglePowerSavingMode(bool value) {
    _isPowerSavingMode = value;
    notifyListeners();
    _saveSettings();
  }

  void toggleWelcomeGreeting(bool value) {
    _showWelcomeGreeting = value;
    notifyListeners();
    _saveSettings();
  }

  void setWelcomeGreetingDuration(double seconds) {
    _welcomeGreetingDuration = seconds.clamp(3.0, 15.0);
    notifyListeners();
    _saveSettings();
  }

  void setWelcomeDesign(int design) {
    _welcomeDesign = design;
    notifyListeners();
    _saveSettings();
  }

  void setLightColor(Color color) {
    _lightColor = color;
    notifyListeners();
    _saveSettings();
  }

  void setLightDesign(int design) {
    _lightDesign = design;
    notifyListeners();
    _saveSettings();
  }

  void setSimulatedFuelLevel(double value) {
    _simulatedFuelLevel =
        value.clamp(0.0, 100.0).toDouble();

    _useSimulatedFuel = true;

    notifyListeners();
    _saveSettings();
  }

  void toggleUseSimulatedFuel(bool value) {
    _useSimulatedFuel = value;
    notifyListeners();
    _saveSettings();
  }

  void setTeslaAppSlot(
      int index,
      String? packageName,
      ) {
    if (index < 0 || index >= 6) {
      return;
    }

    _teslaAppSlots[index] = packageName;

    notifyListeners();
    _saveSettings();
  }

  void setProfileImageUrl(String? url) {
    _profileImageUrl = url;
    notifyListeners();
    _saveSettings();
  }

  void selectVehicle(Vehicle vehicle) async {
    _selectedVehicle = vehicle;
    
    // Si es un asset (comienza con assets/), no necesita descarga.
    if (vehicle.modelPath.startsWith('assets/')) {
      _backgroundImage = vehicle.backgroundImage;
      _modelPath = vehicle.modelPath;
      _isAssetBackground = true;
      _selectedVehicle = vehicle.copyWith(isDownloaded: true);
    } else {
      // Es un vehículo de Supabase. Comprobamos si ya está descargado.
      final modelFile = ResourceService.instance.getFileNameFromUrl(vehicle.modelUrl ?? '');
      final bgFile = ResourceService.instance.getFileNameFromUrl(vehicle.backgroundUrl ?? '');
      
      final isModelDown = await ResourceService.instance.isFileDownloaded(modelFile);
      
      if (isModelDown) {
        final modelF = await ResourceService.instance.getLocalFile(modelFile);
        final localBg = await ResourceService.instance.getLocalFile(bgFile);
        
        _modelPath = modelF?.path ?? vehicle.modelPath;
        
        // Add file:// prefix for model_viewer_plus
        if (!_modelPath.startsWith('assets/') && !_modelPath.startsWith('http')) {
           _modelPath = 'file://$_modelPath';
        }

        _backgroundImage = localBg?.path ?? vehicle.backgroundImage;
        _isAssetBackground = false;
        
        _selectedVehicle = vehicle.copyWith(
          isDownloaded: true,
          modelPath: _modelPath,
          backgroundImage: _backgroundImage!,
        );
      } else {
        // No está descargado. Mantendremos las URLs y esperaremos a la acción del usuario.
        _selectedVehicle = vehicle.copyWith(isDownloaded: false);
      }
    }

    notifyListeners();
    _saveSettings();
  }

  Future<bool> downloadVehicleResources() async {
    final vehicle = _selectedVehicle;
    if (vehicle == null || vehicle.modelUrl == null) {
      return true;
    }

    debugPrint('[VEHICLE] Starting download process for: ${vehicle.name}');
    _isDownloadingResources = true;
    _downloadProgress = 0.05;
    _downloadSizeMessage = 'Calculando tamaño...';
    notifyListeners();

    try {
      final modelName = ResourceService.instance.getFileNameFromUrl(vehicle.modelUrl!);
      final bgName = ResourceService.instance.getFileNameFromUrl(vehicle.backgroundUrl ?? '');

      // Get actual size
      final size = await ResourceService.instance.getRemoteFileSize(vehicle.modelUrl!);
      final sizeMb = size > 0 ? (size / (1024 * 1024)).toStringAsFixed(1) : '50.0';
      _downloadSizeMessage = 'Peso: $sizeMb MB';
      
      _downloadProgress = 0.1;
      notifyListeners();

      // Download Model
      final modelPath = await ResourceService.instance.downloadFile(vehicle.modelUrl!, modelName);
      if (modelPath == null) throw Exception("Failed to download model file");
      
      _downloadProgress = 0.7;
      notifyListeners();

      // Download Background
      String? bgPath;
      if (vehicle.backgroundUrl != null && vehicle.backgroundUrl!.isNotEmpty) {
        bgPath = await ResourceService.instance.downloadFile(vehicle.backgroundUrl!, bgName);
      }

      _downloadProgress = 1.0;
      
      // Verification
      final downloadedFile = File(modelPath);
      if (await downloadedFile.exists() && await downloadedFile.length() > 0) {
        _modelPath = 'file://$modelPath';
        _backgroundImage = bgPath ?? _backgroundImage;
        _isAssetBackground = false;
        
        _selectedVehicle = vehicle.copyWith(
          isDownloaded: true,
          modelPath: _modelPath,
          backgroundImage: _backgroundImage!,
        );
        
        debugPrint('[VEHICLE] Download completed successfully. Local path: $_modelPath');
        _isDownloadingResources = false;
        notifyListeners();
        _saveSettings();
        return true;
      } else {
        throw Exception("Downloaded file is invalid or empty");
      }
    } catch (e) {
      debugPrint('[VEHICLE] ERROR during download: $e');
      _isDownloadingResources = false;
      notifyListeners();
      return false;
    }
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  void addCustomGauge(String type) {
    Size defaultSize = const Size(120, 80);

    if (type == 'music_hub') {
      defaultSize = const Size(220, 70);
    }

    _customGauges.add(
      CustomGaugeConfig(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(),
        type: type,
        position: const Offset(100, 100),
        size: defaultSize,
        design: 0,
      ),
    );

    notifyListeners();
  }

  void updateGaugeDesign(
      String id,
      int design,
      ) {
    final index = _customGauges.indexWhere(
          (gauge) => gauge.id == id,
    );

    if (index == -1) {
      return;
    }

    _customGauges[index].design = design;
    notifyListeners();
  }

  void updateGaugePosition(
      String id,
      Offset newPos,
      ) {
    final index = _customGauges.indexWhere(
          (gauge) => gauge.id == id,
    );

    if (index == -1) {
      return;
    }

    _customGauges[index].position = newPos;
    notifyListeners();
  }

  void updateGaugeSize(
      String id,
      Size newSize,
      ) {
    final index = _customGauges.indexWhere(
          (gauge) => gauge.id == id,
    );

    if (index == -1) {
      return;
    }

    _customGauges[index].size = newSize;
    notifyListeners();
  }

  void updateGaugeCustomization(
    String id, {
    String? logoPath,
    String? customImagePath,
    double? customImageOpacity,
  }) {
    final index = _customGauges.indexWhere((gauge) => gauge.id == id);
    if (index == -1) return;

    if (logoPath != null) _customGauges[index].logoPath = logoPath;
    if (customImagePath != null) _customGauges[index].customImagePath = customImagePath;
    if (customImageOpacity != null) _customGauges[index].customImageOpacity = customImageOpacity;

    notifyListeners();
  }

  void removeCustomGauge(String id) {
    _customGauges.removeWhere(
          (gauge) => gauge.id == id,
    );

    notifyListeners();
  }

  void downloadStyle(DashboardStyle style) {
    _downloadedStyles.add(style);

    notifyListeners();
    _saveSettings();
  }

  void setStyle(DashboardStyle style) {
    if (!_downloadedStyles.contains(style)) {
      return;
    }

    _selectedStyle = style;

    notifyListeners();
    _saveSettings();
  }

  void setModelPath(String path) {
    _modelPath = path;

    notifyListeners();
    _saveSettings();
  }

  void setAccentColor(Color color) {
    _accentColor = color;

    notifyListeners();
    _saveSettings();
  }

  void setTempUnit(TemperatureUnit unit) {
    _tempUnit = unit;

    notifyListeners();
    _saveSettings();
  }

  void setLanguage(Language lang) {
    _language = lang;

    notifyListeners();
    _saveSettings();
  }

  void setBackgroundImage(
      String? path, {
        bool isAsset = true,
      }) {
    _backgroundImage = path;

    if (path == 'COLOR_BLACK') {
      _isAssetBackground = true;
    } else if (path != null &&
        !path.startsWith('assets/')) {
      _isAssetBackground = false;
    } else {
      _isAssetBackground = isAsset;
    }

    notifyListeners();
    _saveSettings();
  }

  double convertTemp(int celsius) {
    if (_tempUnit == TemperatureUnit.celsius) {
      return celsius.toDouble();
    }

    return (celsius * 9 / 5) + 32;
  }
}
