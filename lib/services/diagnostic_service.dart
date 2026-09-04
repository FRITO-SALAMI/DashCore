import 'dart:async';
import 'package:flutter/foundation.dart';

class DiagnosticService {
  static final List<String> _logs = [];
  static const int _maxLogs = 100;

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final entry = "[$timestamp] $message";
    _logs.add(entry);
    if (_logs.length > _maxLogs) _logs.removeAt(0);
    debugPrint(entry);
  }

  static String getFullReport() {
    return _logs.join("\n");
  }

  static void init() {
    FlutterError.onError = (details) {
      log("FLUTTER ERROR: ${details.exceptionAsString()}");
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      log("PLATFORM ERROR: $error");
      return true;
    };
  }
}
