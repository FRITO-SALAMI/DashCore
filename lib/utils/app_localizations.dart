import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';

class AppLocalizations {
  final Language language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    final lang = context.watch<DashSettingsProvider>().language;
    return AppLocalizations(lang);
  }

  static final Map<Language, Map<String, String>> _values = {
    Language.english: {
      'connection': 'Connection',
      'bluetooth': 'Bluetooth',
      'usb': 'USB',
      'scanning': 'Scanning...',
      'scan_complete': 'Scanning complete',
      'searching_adapter': 'Searching for your adapter...',
      'found_devices': 'Found {} devices',
      'start_scan': 'Start Scanning',
      'no_devices': 'No devices found',
      'check_ignition': 'Make sure the scanner is plugged in and the\nignition is turned on',
      'connected': 'Connected',
      'paired': 'Paired',
      'available': 'Available',
      'connecting_to': 'Connecting to {}...',
      'data_exchange': 'Data exchange...',
      'attempt': 'Attempt #{}',
      'cancel': 'Cancel',
      'error_not_responding': 'Error: \'{}\' is not responding',
      'bluetooth_required': 'Bluetooth access required',
      'bluetooth_denied_msg': 'Bluetooth permission was permanently denied. Please enable it from app settings.',
      'open_settings': 'Open settings',
      'home': 'HOME',
      'dashboard': 'DASHBOARD',
      'styles': 'STYLES',
      'settings': 'SETTINGS',
      'import': 'IMPORT',
      'export': 'EXPORT',
      'main_menu': 'MAIN MENU',
      'temp_unit': 'TEMPERATURE UNIT',
      'lang': 'LANGUAGE',
      'bg_image': 'BG IMAGE',
      'accent_color': 'ACCENT COLOR',
      'first_vehicle': 'Add your first vehicle',
      'no_cars': 'No Cars',
      'add_car': 'Add Car',
      'garage': 'Garage',
      'double_tap_close': 'DOUBLE TAP TO CLOSE',
      'edit': 'EDIT',
      'new_sketch': 'NEW SKETCH',
      'connecting': 'CONNECTING...',
      'reconnecting': 'RECONNECTING...',
    },
    Language.spanish: {
      'connection': 'Conexión',
      'bluetooth': 'Bluetooth',
      'usb': 'USB',
      'scanning': 'Escaneando...',
      'scan_complete': 'Escaneo completado',
      'searching_adapter': 'Buscando tu adaptador...',
      'found_devices': 'Se encontraron {} dispositivos',
      'start_scan': 'Iniciar Escaneo',
      'no_devices': 'No se encontraron dispositivos',
      'check_ignition': 'Asegúrate de que el escáner esté conectado\ny el motor encendido',
      'connected': 'Conectado',
      'paired': 'Emparejado',
      'available': 'Disponible',
      'connecting_to': 'Conectando a {}...',
      'data_exchange': 'Intercambio de datos...',
      'attempt': 'Intento #{}',
      'cancel': 'Cancelar',
      'error_not_responding': 'Error: \'{}\' no responde',
      'bluetooth_required': 'Acceso Bluetooth requerido',
      'bluetooth_denied_msg': 'El permiso de Bluetooth fue denegado permanentemente. Por favor actívalo en los ajustes.',
      'open_settings': 'Abrir ajustes',
      'home': 'INICIO',
      'dashboard': 'TABLERO',
      'styles': 'ESTILOS',
      'settings': 'AJUSTES',
      'import': 'IMPORTAR',
      'export': 'EXPORTAR',
      'main_menu': 'MENÚ PRINCIPAL',
      'temp_unit': 'UNIDAD DE TEMPERATURA',
      'lang': 'IDIOMA',
      'bg_image': 'IMAGEN DE FONDO',
      'accent_color': 'COLOR DE ACENTO',
      'first_vehicle': 'Añade tu primer vehículo',
      'no_cars': 'Sin Vehículos',
      'add_car': 'Añadir Auto',
      'garage': 'Garaje',
      'double_tap_close': 'DOBLE TOQUE PARA CERRAR',
      'edit': 'EDITAR',
      'new_sketch': 'NUEVO BOCETO',
      'connecting': 'CONECTANDO...',
      'reconnecting': 'RECONECTANDO...',
    },
  };

  String translate(String key, [List<String>? args]) {
    String value = _values[language]?[key] ?? key;
    if (args != null) {
      for (var arg in args) {
        value = value.replaceFirst('{}', arg);
      }
    }
    return value;
  }
}
