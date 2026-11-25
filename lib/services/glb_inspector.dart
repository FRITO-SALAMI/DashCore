import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class GlbProfile {
  const GlbProfile(this.bytes, this.vertices, this.unsupportedExtensions);
  final int bytes, vertices;
  final List<String> unsupportedExtensions;
  bool get expensive => bytes > 12 * 1024 * 1024 || vertices > 200000;
}

/// Reads the header and JSON directory, never the complete binary payload.
Future<GlbProfile> inspectGlb(File file) async {
  final length = await file.length();
  if (length > 100 * 1024 * 1024) throw const FormatException('El GLB supera 100 MB');
  final input = await file.open();
  try {
    final header = await input.read(20);
    if (header.length != 20 || ascii.decode(header.sublist(0, 4), allowInvalid: true) != 'glTF') {
      throw const FormatException('El archivo no es un GLB válido');
    }
    final data = ByteData.sublistView(header);
    if (data.getUint32(4, Endian.little) != 2 || data.getUint32(8, Endian.little) != length || data.getUint32(16, Endian.little) != 0x4e4f534a) {
      throw const FormatException('GLB incompleto o versión no compatible');
    }
    final jsonLength = data.getUint32(12, Endian.little);
    if (jsonLength > 4 * 1024 * 1024 || jsonLength + 20 > length) throw const FormatException('Directorio GLB inválido');
    final metadata = jsonDecode(utf8.decode(await input.read(jsonLength))) as Map<String, dynamic>;
    for (final resource in [...?metadata['buffers'] as List?, ...?metadata['images'] as List?]) {
      final uri = (resource as Map)['uri']?.toString();
      if (uri != null && !uri.startsWith('data:')) throw const FormatException('Importa un GLB autónomo, sin archivos externos');
    }
    final accessors = metadata['accessors'] as List? ?? const [];
    final used = <int>{};
    for (final mesh in metadata['meshes'] as List? ?? const []) {
      for (final primitive in (mesh as Map)['primitives'] as List? ?? const []) {
        final index = (primitive as Map)['attributes']?['POSITION'];
        if (index is int) used.add(index);
      }
    }
    var vertices = 0;
    for (final index in used) {
      if (index >= 0 && index < accessors.length) vertices += ((accessors[index] as Map)['count'] as num?)?.toInt() ?? 0;
    }
    final required = (metadata['extensionsRequired'] as List? ?? const []).cast<String>();
    return GlbProfile(length, vertices, required.where({'EXT_meshopt_compression', 'KHR_texture_basisu'}.contains).toList());
  } finally { await input.close(); }
}
