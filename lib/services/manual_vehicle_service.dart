import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_model.dart';
import 'glb_inspector.dart';
import 'local_vehicle_segmentation.dart';
import 'supabase_service.dart';

class ManualVehicleService {
  static String get _key =>
      'manual_vehicles_v2_${SupabaseService.instance.currentUser?.id ?? 'guest'}';
  static Future<List<Vehicle>> load({bool includeCloud = false}) async {
    final key = _key;
    final userId = SupabaseService.instance.currentUser?.id;
    final prefs = await SharedPreferences.getInstance();
    try {
      final local = (jsonDecode(prefs.getString(key) ?? '[]') as List)
          .map(
            (row) => Vehicle(
              id: row['id'],
              name: row['name'],
              brand: row['brand'],
              year: row['version'],
              backgroundImage: row['background'] ?? '',
              modelPath: row['model'] ?? '',
              artworkPath: row['artwork'],
              rearArtworkPath: row['rearArtwork'],
              paintColorHex: row['paintColor'],
              isCustom: true,
              isDownloaded: true,
            ),
          )
          .toList();
      if (includeCloud && userId != null) {
        try {
          final client = SupabaseService.instance.client!;
          if (local.isNotEmpty)
            await client
                .from('user_vehicles')
                .upsert(
                  local
                      .map(
                        (v) => {
                          'user_id': userId,
                          'id': v.id,
                          'name': v.name,
                          'brand': v.brand,
                          'version': v.year,
                        },
                      )
                      .toList(),
                  onConflict: 'user_id,id',
                )
                .timeout(const Duration(seconds: 5));
          final rows = await client
              .from('user_vehicles')
              .select('id,name,brand,version')
              .eq('user_id', userId)
              .limit(100)
              .timeout(const Duration(seconds: 5));
          if (SupabaseService.instance.currentUser?.id != userId) return [];
          final ids = local.map((v) => v.id).toSet();
          for (final row in rows) {
            if (!ids.contains(row['id']))
              local.add(
                Vehicle(
                  id: row['id'],
                  name: row['name'],
                  brand: row['brand'],
                  year: row['version'],
                  backgroundImage: '',
                  modelPath: '',
                  isCustom: true,
                  isDownloaded: true,
                ),
              );
          }
          await _saveForKey(key, local);
        } catch (_) {
          /* Cached vehicles remain available offline. */
        }
      }
      return local;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Vehicle> vehicles) =>
      _saveForKey(_key, vehicles);
  static Future<void> _saveForKey(String key, List<Vehicle> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(
        vehicles
            .where((v) => v.isCustom)
            .map(
              (v) => {
                'id': v.id,
                'name': v.name,
                'brand': v.brand,
                'version': v.year,
                'model': v.modelPath,
                'background': v.backgroundImage,
                'artwork': v.artworkPath,
                'rearArtwork': v.rearArtworkPath,
                'paintColor': v.paintColorHex,
              },
            )
            .toList(),
      ),
    );
  }

  static Future<void> removeLocalForAccount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'manual_vehicles_v2_$userId';
    List rows;
    try {
      rows = jsonDecode(prefs.getString(key) ?? '[]') as List;
    } catch (_) {
      rows = [];
    }
    final base = await getApplicationDocumentsDirectory();
    final root = Directory('${base.path}/dashcore/vehicles').absolute.path;
    for (final row in rows) {
      final id = row is Map ? row['id'] : null;
      if (id is! String || !RegExp(r'^custom_[a-zA-Z0-9_]{1,64}$').hasMatch(id))
        continue;
      final directory = Directory('$root${Platform.pathSeparator}$id').absolute;
      if (!directory.path.startsWith('$root${Platform.pathSeparator}'))
        continue;
      try {
        if (await directory.exists()) await directory.delete(recursive: true);
      } catch (_) {
        /* Can retry local cleanup. */
      }
    }
    await prefs.remove(key);
  }

  static Future<Vehicle> create({
    required String name,
    required String brand,
    String? year,
    String? glbPath,
    String? paintColorHex,
  }) async {
    if (name.trim().isEmpty ||
        name.length > 100 ||
        brand.trim().isEmpty ||
        brand.length > 80)
      throw const FormatException('Introduce marca y modelo válidos');
    final id =
        'custom_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32).toRadixString(16)}';
    String model = '';
    if (glbPath != null) {
      final file = File(glbPath);
      await inspectGlb(file);
      final base = await getApplicationDocumentsDirectory();
      final directory = Directory('${base.path}/dashcore/vehicles/$id');
      await directory.create(recursive: true);
      model = (await file.copy('${directory.path}/model.glb')).path;
    }
    final vehicle = Vehicle(
      id: id,
      name: name.trim(),
      brand: brand.trim(),
      year: year?.trim(),
      backgroundImage: '',
      modelPath: model,
      isCustom: true,
      isDownloaded: true,
      paintColorHex: paintColorHex,
    );
    final vehicles = await load();
    await save([...vehicles, vehicle]);
    await syncMetadata(vehicle);
    return vehicle;
  }

  static Future<void> syncMetadata(Vehicle vehicle) async {
    final service = SupabaseService.instance;
    final user = service.currentUser;
    if (user == null) return;
    try {
      await service.client!
          .from('user_vehicles')
          .upsert({
            'user_id': user.id,
            'id': vehicle.id,
            'name': vehicle.name,
            'brand': vehicle.brand,
            'version': vehicle.year,
          }, onConflict: 'user_id,id')
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      /* Local vehicles remain usable offline. */
    }
  }

  static Future<Vehicle> attachPhoto(
    Vehicle vehicle,
    File source, {
    bool rear = false,
    bool cutout = false,
  }) async {
    if (await source.length() > 15 * 1024 * 1024)
      throw const FormatException('La foto supera 15 MB');
    // Re-encoding strips EXIF/GPS metadata before any optional cloud upload.
    final buffer = await ui.ImmutableBuffer.fromFilePath(source.path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        final scale = min(
          1.0,
          min(1280 / descriptor.width, 1024 / descriptor.height),
        );
        final codec = await descriptor.instantiateCodec(
          targetWidth: max(1, (descriptor.width * scale).round()),
          targetHeight: max(1, (descriptor.height * scale).round()),
        );
        try {
          final frame = await codec.getNextFrame();
          try {
            final png = await frame.image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (png == null)
              throw const FormatException('No se pudo leer la foto');
            final base = await getApplicationDocumentsDirectory();
            final file = File(
              '${base.path}/dashcore/vehicles/${vehicle.id}/${rear ? 'source_rear' : 'source'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(
              png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
            );
            ui.Image? segment;
            try {
              if (cutout)
                segment = await LocalVehicleSegmentation.cutout(frame.image);
              final styled = await _renderSportPhoto(
                segment ?? frame.image,
                file.parent,
                segment == null
                    ? (rear ? 'sport_rear' : 'sport')
                    : (rear ? 'cutout_rear' : 'cutout'),
                transparent: segment != null,
              );
              return rear
                  ? vehicle.copyWith(rearArtworkPath: styled.path)
                  : vehicle.copyWith(artworkPath: styled.path);
            } catch (_) {
              return rear
                  ? vehicle.copyWith(rearArtworkPath: file.path)
                  : vehicle.copyWith(artworkPath: file.path);
            } finally {
              segment?.dispose();
            }
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  static Future<File> _renderSportPhoto(
    ui.Image photo,
    Directory directory,
    String name, {
    required bool transparent,
  }) async {
    const frame = ui.Rect.fromLTWH(0, 0, 768, 384);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    const cyan = ui.Color(0xFF4FBFE9);
    final panel = ui.RRect.fromRectAndRadius(
      frame.deflate(6),
      const ui.Radius.circular(22),
    );
    if (!transparent)
      canvas.drawRRect(
        panel,
        paint
          ..shader = ui.Gradient.linear(
            frame.topLeft,
            frame.bottomRight,
            const [
              ui.Color(0xFF152B40),
              ui.Color(0xFF080F18),
              ui.Color(0xFF10273B),
            ],
          ),
      );
    final scale = min(736 / photo.width, 350 / photo.height);
    final bounds = ui.Rect.fromCenter(
      center: frame.center,
      width: photo.width * scale,
      height: photo.height * scale,
    );
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(bounds, const ui.Radius.circular(12)),
    );
    paint
      ..shader = null
      ..filterQuality = ui.FilterQuality.medium;
    canvas.drawImageRect(
      photo,
      ui.Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
      bounds,
      paint,
    );
    if (!transparent)
      canvas.drawRect(
        bounds,
        paint
          ..shader = ui.Gradient.linear(
            bounds.topCenter,
            bounds.bottomCenter,
            const [ui.Color(0x00121F2E), ui.Color(0x40121F2E)],
          ),
      );
    canvas.restore();
    paint
      ..shader = null
      ..color = cyan
      ..strokeWidth = 3
      ..strokeCap = ui.StrokeCap.round;
    if (!transparent) {
      canvas.drawLine(const ui.Offset(22, 16), const ui.Offset(72, 16), paint);
      canvas.drawLine(
        const ui.Offset(696, 368),
        const ui.Offset(746, 368),
        paint,
      );
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(768, 384);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null)
          throw StateError('No se pudo guardar el acabado deportivo');
        return await File('${directory.path}/$name.png').writeAsBytes(
          png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        );
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  static Future<bool> artworkServiceAvailable() async {
    try {
      final response = await SupabaseService.instance.client!.functions
          .invoke('stylize-vehicle', body: {'action': 'status'})
          .timeout(const Duration(seconds: 5));
      return response.data is Map && response.data['available'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Vehicle> generateArtwork(Vehicle vehicle) async {
    final service = SupabaseService.instance;
    final user = service.currentUser;
    final path = vehicle.artworkPath;
    if (user == null)
      throw StateError('Inicia sesión para generar tu vehículo');
    if (path == null) throw StateError('Selecciona una foto primero');
    if (!await artworkServiceAvailable())
      throw StateError('El servicio de IA libre aún no está conectado');
    final file = File('${File(path).parent.path}/source.png');
    if (!await file.exists())
      throw StateError('Selecciona una foto original primero');
    if (await file.length() > 10 * 1024 * 1024)
      throw const FormatException('Reduce el tamaño de la foto');
    final remote = '${user.id}/${vehicle.id}/source.png';
    await syncMetadata(vehicle);
    await service.client!.storage
        .from('user-vehicles')
        .upload(
          remote,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );
    await service.client!
        .from('user_vehicles')
        .update({'photo_path': remote})
        .eq('user_id', user.id)
        .eq('id', vehicle.id);
    final response = await service.client!.functions
        .invoke(
          'stylize-vehicle',
          body: {'vehicle_id': vehicle.id, 'consent': true},
        )
        .timeout(const Duration(seconds: 135));
    if (response.status != 200 ||
        response.data is! Map ||
        response.data['artwork_path'] is! String) {
      throw StateError(
        'La generación no está disponible. Tu foto local sigue guardada.',
      );
    }
    final artworkPath = '${user.id}/${vehicle.id}/artwork.png';
    if (response.data['artwork_path'] != artworkPath) {
      throw StateError('No se pudo verificar la imagen generada');
    }
    final download = await service.client!.storage
        .from('user-vehicles')
        .download(artworkPath);
    final target = File('${file.parent.path}/artwork.png');
    await target.writeAsBytes(download);
    return vehicle.copyWith(artworkPath: target.path);
  }
}
