import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class LocalVehicleSegmentation {
  static const _side = 320;
  static const _channel = MethodChannel('io.dashcore.app/local_vehicle_art');

  static Future<ui.Image?> cutout(ui.Image photo) async {
    if (!Platform.isAndroid) return null;
    final source = ui.Rect.fromLTWH(
      0,
      0,
      photo.width.toDouble(),
      photo.height.toDouble(),
    );
    const input = ui.Rect.fromLTWH(0, 0, 320, 320);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      photo,
      source,
      input,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final sample = recorder.endRecording();
    ui.Image? resized;
    ui.Image? mask;
    try {
      resized = await sample.toImage(_side, _side);
      final bytes = await resized.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (bytes == null) return null;
      final alpha = await _channel.invokeMethod<Uint8List>(
        'segmentVehicle',
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (alpha == null || alpha.length != _side * _side) return null;
      final rgba = Uint8List(alpha.length * 4);
      for (var i = 0; i < alpha.length; i++) {
        rgba[i * 4 + 3] = alpha[i];
      }
      final decoded = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        rgba,
        _side,
        _side,
        ui.PixelFormat.rgba8888,
        decoded.complete,
      );
      mask = await decoded.future;
      final output = ui.PictureRecorder();
      final canvas = ui.Canvas(output)..saveLayer(source, ui.Paint());
      canvas.drawImage(photo, ui.Offset.zero, ui.Paint());
      canvas.drawImageRect(
        mask,
        input,
        source,
        ui.Paint()
          ..blendMode = ui.BlendMode.dstIn
          ..filterQuality = ui.FilterQuality.medium,
      );
      canvas.restore();
      final picture = output.endRecording();
      try {
        return await picture.toImage(photo.width, photo.height);
      } finally {
        picture.dispose();
      }
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } finally {
      mask?.dispose();
      resized?.dispose();
      sample.dispose();
    }
  }
}
