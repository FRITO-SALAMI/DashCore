import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../providers/obd_provider.dart';
import 'analytics_service.dart';

class PerformanceMonitorService {
  PerformanceMonitorService._();

  static final instance = PerformanceMonitorService._();
  static const _platform = MethodChannel('io.dashcore.app/launcher');

  Timer? _timer;
  ObdProvider? _obd;
  int _frames = 0;
  int _slowFrames = 0;
  Duration _frameSpan = Duration.zero;

  void start(ObdProvider obd) {
    _obd = obd;
    if (_timer != null) return;
    SchedulerBinding.instance.addTimingsCallback(_recordFrames);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _sendSample());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    SchedulerBinding.instance.removeTimingsCallback(_recordFrames);
    _obd = null;
    _resetFrames();
  }

  void _recordFrames(List<FrameTiming> timings) {
    for (final timing in timings) {
      final total = timing.totalSpan;
      _frames++;
      _frameSpan += total;
      if (total > const Duration(milliseconds: 16)) _slowFrames++;
    }
  }

  Future<void> _sendSample() async {
    try {
      final native = await _platform.invokeMapMethod<String, dynamic>(
            'getPerformanceSnapshot',
          ) ??
          const <String, dynamic>{};
      final averageFrameMs = _frames == 0
          ? 0.0
          : _frameSpan.inMicroseconds / _frames / 1000.0;
      await AnalyticsService.instance.logEvent('performance_sample', data: {
        ...native,
        'frames': _frames,
        'slow_frames': _slowFrames,
        'average_frame_ms': averageFrameMs,
        'estimated_fps': averageFrameMs > 0 ? 1000 / averageFrameMs : 0,
        'gps_active': _obd?.isGpsMode ?? false,
        'obd_active': _obd?.isRealMode ?? false,
        'obd_state': _obd?.state.name,
      });
    } finally {
      _resetFrames();
    }
  }

  void _resetFrames() {
    _frames = 0;
    _slowFrames = 0;
    _frameSpan = Duration.zero;
  }
}
