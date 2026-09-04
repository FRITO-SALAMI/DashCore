import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';

class ResourceService {
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/dashcore/vehicles';
  }

  Future<File?> getLocalFile(String fileName, {String? subDir}) async {
    final sanitized = _sanitizeFileName(fileName);
    if (sanitized == null) return null;

    final base = await _localPath;
    final path = subDir != null ? '$base/$subDir' : base;
    final file = File('$path/$sanitized');
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    return null;
  }

  Future<bool> isFileDownloaded(String fileName, {String? subDir}) async {
    final sanitized = _sanitizeFileName(fileName);
    if (sanitized == null) return false;

    final base = await _localPath;
    final path = subDir != null ? '$base/$subDir' : base;
    return File('$path/$sanitized').exists();
  }

  Future<String?> downloadFile(String url, String fileName, {String? subDir}) async {
    final sanitized = _sanitizeFileName(fileName);
    if (sanitized == null) {
      debugPrint('[VEHICLE] ERROR: Invalid filename $fileName');
      return null;
    }

    final fileNameParts = sanitized.split('.');
    if (fileNameParts.length > 1) {
      final extension = fileNameParts.last.toLowerCase();
      const allowedExtensions = {'glb', 'gltf', 'png', 'jpg', 'jpeg', 'webp'};
      if (!allowedExtensions.contains(extension)) {
        debugPrint('[VEHICLE] ERROR: File extension not allowed for $sanitized');
        return null;
      }
    } else {
      debugPrint('[VEHICLE] INFO: Downloading file without extension: $sanitized');
    }

    final base = await _localPath;
    final path = subDir != null ? '$base/$subDir' : base;

    // Ensure directory exists
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final finalFile = File('$path/$sanitized');
    final tempFile = File('$path/$sanitized.tmp');

    try {
      debugPrint('[VEHICLE] Downloading resource from: $url');

      // Check remote size before downloading (100MB limit)
      final size = await getRemoteFileSize(url);
      if (size > 100 * 1024 * 1024) {
        debugPrint(
          '[VEHICLE] ERROR: File is too large (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
        return null;
      }

      final client = http.Client();
      IOSink? sink;
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request);

        debugPrint('[VEHICLE] HTTP status: ${response.statusCode}');
        if (response.statusCode != HttpStatus.ok) {
          debugPrint('[VEHICLE] ERROR downloading resource: Invalid response');
          return null;
        }

        if (await tempFile.exists()) await tempFile.delete();
        sink = tempFile.openWrite();
        var receivedBytes = 0;
        const maxBytes = 100 * 1024 * 1024;
        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          if (receivedBytes > maxBytes) {
            throw const FileSystemException('Downloaded resource exceeds 100 MB');
          }
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
        sink = null;

        if (receivedBytes == 0) {
          debugPrint('[VEHICLE] ERROR downloading resource: Empty body');
          return null;
        }

        debugPrint('[VEHICLE] Downloaded bytes: $receivedBytes');

        // Atomic rename
        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        await tempFile.rename(finalFile.path);

        debugPrint('[VEHICLE] Resource saved and validated: ${finalFile.path}');
        return finalFile.path;
      } finally {
        await sink?.close();
        client.close();
      }
    } catch (e) {
      debugPrint('[VEHICLE] ERROR downloading resource: $e');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      return null;
    }
  }

  Future<int> getRemoteFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '-1') ?? -1;
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return -1;
  }

  String getFileNameFromUrl(String url) {
    if (url.isEmpty) return '';
    final rawName = url.split('/').last.split('?').first;
    return _sanitizeFileName(rawName) ?? '';
  }

  Future<void> deleteFile(String fileName, {String? subDir}) async {
    final sanitized = _sanitizeFileName(fileName);
    if (sanitized == null) return;

    final base = await _localPath;
    final path = subDir != null ? '$base/$subDir' : base;
    final file = File('$path/$sanitized');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> downloadAndUnzip(String url, String destinationSubDir) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final destinationPath = '${base.path}/dashcore/$destinationSubDir';

      // 1. Download to temporary file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;

      final bytes = response.bodyBytes;

      // 2. Decode the ZIP
      final archive = ZipDecoder().decodeBytes(bytes);

      // 3. Extract contents
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('$destinationPath/$filename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory('$destinationPath/$filename').create(recursive: true);
        }
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error unzipping: $e');
      return false;
    }
  }

  Future<List<File>> getLocalFiles(String subDir) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/dashcore/$subDir');
      if (await dir.exists()) {
        return dir.listSync().whereType<File>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteVehicleDirectory(String vehicleId) async {
    if (vehicleId.isEmpty) return;
    final base = await _localPath;
    final dir = Directory('$base/$vehicleId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Sanitiza el nombre de archivo para prevenir Path Traversal.
  String? _sanitizeFileName(String fileName) {
    if (fileName.isEmpty) return null;

    // Evitar navegación de directorios y caracteres prohibidos
    if (fileName.contains('..') ||
        fileName.contains('/') ||
        fileName.contains('\\') ||
        fileName == '.' ||
        fileName == '..') {
      return null;
    }

    // Opcionalmente: Permitir solo alfanuméricos, guiones y un punto
    // Regex para validar formato seguro de nombre de archivo
    final safeRegex = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
    if (!safeRegex.hasMatch(fileName)) {
      return null;
    }

    return fileName;
  }
}
