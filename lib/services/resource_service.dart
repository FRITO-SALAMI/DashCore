import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ResourceService {
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File?> getLocalFile(String fileName) async {
    final path = await _localPath;
    final file = File('$path/$fileName');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<bool> isFileDownloaded(String fileName) async {
    if (fileName.isEmpty) return false;
    final path = await _localPath;
    return File('$path/$fileName').exists();
  }

  Future<String?> downloadFile(String url, String fileName) async {
    final path = await _localPath;
    final finalFile = File('$path/$fileName');
    final tempFile = File('$path/$fileName.tmp');

    try {
      debugPrint('[VEHICLE] Downloading model from: $url');
      final response = await http.get(Uri.parse(url));
      
      debugPrint('[VEHICLE] HTTP status: ${response.statusCode}');
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        debugPrint('[VEHICLE] Downloaded bytes: ${response.bodyBytes.length}');
        
        await tempFile.writeAsBytes(response.bodyBytes);
        
        // Atomic rename
        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        await tempFile.rename(finalFile.path);
        
        debugPrint('[VEHICLE] Model saved and validated: ${finalFile.path}');
        return finalFile.path;
      } else {
        debugPrint('[VEHICLE] ERROR downloading model: Invalid response or empty body');
        return null;
      }
    } catch (e) {
      debugPrint('[VEHICLE] ERROR downloading model: $e');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return null;
    }
  }

  Future<int> getRemoteFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '0') ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return 0;
  }

  String getFileNameFromUrl(String url) {
    if (url.isEmpty) return '';
    return url.split('/').last.split('?').first;
  }

  Future<void> deleteFile(String fileName) async {
    final path = await _localPath;
    final file = File('$path/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
