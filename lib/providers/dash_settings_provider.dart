import 'package:flutter/material.dart';

enum DashboardStyle { sporty, racing, modern, vehicle3D, purplePuff, racingHud, glowRed, hellishRed }
enum TemperatureUnit { celsius, fahrenheit }
enum Language { spanish, english }

class CustomGaugeConfig {
  final String id;
  final String type; // 'speed', 'rpm', 'temp', 'volt'
  Offset position;
  Size size;

  CustomGaugeConfig({required this.id, required this.type, required this.position, this.size = const Size(100, 100)});
}

class DashSettingsProvider extends ChangeNotifier {
  DashboardStyle _selectedStyle = DashboardStyle.sporty;
  DashboardStyle get selectedStyle => _selectedStyle;

  // Track which styles are "downloaded"
  final Set<DashboardStyle> _downloadedStyles = {DashboardStyle.sporty};
  Set<DashboardStyle> get downloadedStyles => _downloadedStyles;

  Color _accentColor = const Color(0xFF00E5FF);
  Color get accentColor => _accentColor;

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  final List<CustomGaugeConfig> _customGauges = [];
  List<CustomGaugeConfig> get customGauges => _customGauges;

  TemperatureUnit _tempUnit = TemperatureUnit.celsius;
  TemperatureUnit get tempUnit => _tempUnit;

  Language _language = Language.spanish;
  Language get language => _language;

  String? _backgroundImage = 'assets/images/png/car1.png';
  String? get backgroundImage => _backgroundImage;

  bool _isAssetBackground = true;
  bool get isAssetBackground => _isAssetBackground;

  // 3D Model Management
  String _modelPath = 'assets/models/OPTIMA2012.GLB';
  String get modelPath => _modelPath;

  // Gauge Visibility (Default styles)
  final Set<String> _visibleGauges = {'speed', 'rpm', 'coolant', 'voltage'};
  Set<String> get visibleGauges => _visibleGauges;

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  void addCustomGauge(String type) {
    _customGauges.add(CustomGaugeConfig(
      id: DateTime.now().toString(),
      type: type,
      position: const Offset(100, 100),
    ));
    notifyListeners();
  }

  void updateGaugePosition(String id, Offset newPos) {
    final index = _customGauges.indexWhere((g) => g.id == id);
    if (index != -1) {
      _customGauges[index].position = newPos;
      notifyListeners();
    }
  }

  void downloadStyle(DashboardStyle style) {
    _downloadedStyles.add(style);
    notifyListeners();
  }

  void setStyle(DashboardStyle style) {
    if (_downloadedStyles.contains(style)) {
      _selectedStyle = style;
      notifyListeners();
    }
  }

  void setModelPath(String path) {
    _modelPath = path;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  void setTempUnit(TemperatureUnit unit) {
    _tempUnit = unit;
    notifyListeners();
  }

  void setLanguage(Language lang) {
    _language = lang;
    notifyListeners();
  }

  void setBackgroundImage(String? path, {bool isAsset = true}) {
    _backgroundImage = path;
    _isAssetBackground = isAsset;
    notifyListeners();
  }

  double convertTemp(int celsius) {
    if (_tempUnit == TemperatureUnit.celsius) return celsius.toDouble();
    return (celsius * 9 / 5) + 32;
  }
}
