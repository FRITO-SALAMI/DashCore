import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';

class ResourceService {
  ResourceService._();
  static final ResourceService instance = ResourceService._();
  bool _suspended = false;
  bool _extracting = false;
  final Set<http.Client> _clients = {};
  void setSuspended(bool value) {
    _suspended = value;
    if (value) {
      for (final client in _clients) {
        client.close();
      }
      _clients.clear();
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/dashcore/vehicles';
  }

  Future<File?> getLocalFile(String fileName, {String? subDir}) async {
    if (subDir != null && _sanitizeFileName(subDir) == null) return null;
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
    return await getLocalFile(fileName, subDir: subDir) != null;
  }

  Future<String?> downloadFile(
    String url,
    String fileName, {
    String? subDir,
    int maxBytes = 100 * 1024 * 1024,
  }) async {
    if (_suspended || (subDir != null && _sanitizeFileName(subDir) == null))
      return null;
    final sanitized = _sanitizeFileName(fileName);
    if (sanitized == null) {
      debugPrint('[VEHICLE] ERROR: Invalid filename $fileName');
      return null;
    }

    final fileNameParts = sanitized.split('.');
    if (fileNameParts.length > 1) {
      final extension = fileNameParts.last.toLowerCase();
      const allowedExtensions = {
        'glb',
        'gltf',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
        'zip',
      };
      if (!allowedExtensions.contains(extension)) {
        debugPrint(
          '[VEHICLE] ERROR: File extension not allowed for $sanitized',
        );
        return null;
      }
    } else {
      debugPrint(
        '[VEHICLE] INFO: Downloading file without extension: $sanitized',
      );
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
      if (size > maxBytes) {
        debugPrint(
          '[VEHICLE] ERROR: File is too large (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
        return null;
      }

      if (_suspended) return null;
      final client = http.Client();
      _clients.add(client);
      IOSink? sink;
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 20));

        debugPrint('[VEHICLE] HTTP status: ${response.statusCode}');
        if (response.statusCode != HttpStatus.ok) {
          debugPrint('[VEHICLE] ERROR downloading resource: Invalid response');
          return null;
        }

        if (await tempFile.exists()) await tempFile.delete();
        sink = tempFile.openWrite();
        var receivedBytes = 0;
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          if (_suspended) throw const FileSystemException('Download suspended');
          receivedBytes += chunk.length;
          if (receivedBytes > maxBytes) {
            throw const FileSystemException(
              'Downloaded resource exceeds 100 MB',
            );
          }
          sink.add(chunk);
          // Back pressure prevents a slow flash disk from growing an unbounded
          // queue of network chunks in the 32-bit process heap.
          await sink.flush();
        }
        await sink.flush();
        await sink.close();
        sink = null;

        if (receivedBytes == 0 ||
            (response.contentLength != null &&
                receivedBytes != response.contentLength)) {
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
        _clients.remove(client);
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
    if (_suspended) return -1;
    final client = http.Client();
    _clients.add(client);
    try {
      final response = await client
          .head(Uri.parse(url), headers: const {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '-1') ?? -1;
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    } finally {
      _clients.remove(client);
      client.close();
    }
    return -1;
  }

  String getFileNameFromUrl(String url) {
    if (url.isEmpty) return '';
    final rawName = url.split('/').last.split('?').first;
    return _sanitizeFileName(rawName) ?? '';
  }

  Future<void> deleteFile(String fileName, {String? subDir}) async {
    if (subDir != null && _sanitizeFileName(subDir) == null) return;
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
    if (_suspended ||
        _extracting ||
        _sanitizeFileName(destinationSubDir) == null)
      return false;
    _extracting = true;
    String? downloaded;
    try {
      final base = await getApplicationDocumentsDirectory();
      final destinationPath = '${base.path}/dashcore/$destinationSubDir';
      downloaded = await downloadFile(
        url,
        'pack.zip',
        subDir: 'pack_downloads',
      );
      if (downloaded == null || _suspended) return false;
      // Disk-backed decompression in an isolate keeps both the network payload
      // and decompression work off the UI heap/thread.
      await compute(extractResourcePack, [downloaded, destinationPath]);
      return true;
    } catch (e) {
      debugPrint('❌ Error unzipping: $e');
      return false;
    } finally {
      if (downloaded != null) {
        final file = File(downloaded);
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {
          /* Retry cleanup later. */
        }
      }
      _extracting = false;
    }
  }

  Future<List<File>> getLocalFiles(String subDir) async {
    if (_sanitizeFileName(subDir) == null) return [];
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/dashcore/$subDir');
      if (await dir.exists()) {
        return dir
            .list(recursive: true, followLinks: false)
            .where((f) => f is File)
            .cast<File>()
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteVehicleDirectory(String vehicleId) async {
    if (_sanitizeFileName(vehicleId) == null) return;
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

/// Validates the complete ZIP directory before creating any output files.
/// Kept public so malicious/truncated packs can be tested without a network.
void extractResourcePack(List<String> paths) {
  final input = InputFileStream(paths[0]);
  try {
    final archive = ZipDecoder().decodeStream(input);
    if (archive.length > 512)
      throw const FormatException('Too many ZIP entries');
    var expandedBytes = 0;
    for (final entry in archive) {
      final name = entry.name.replaceAll('\\', '/');
      expandedBytes += entry.size;
      if (entry.isSymbolicLink ||
          name.startsWith('/') ||
          name.contains(':') ||
          name.split('/').contains('..') ||
          entry.size > 64 * 1024 * 1024 ||
          expandedBytes > 256 * 1024 * 1024) {
        throw const FormatException('Unsafe or oversized ZIP entry');
      }
    }
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final output = OutputFileStream('${paths[1]}/${entry.name}');
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
    }
  } finally {
    input.closeSync();
  }
}
