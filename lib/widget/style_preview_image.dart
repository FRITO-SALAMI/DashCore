import '../core/backend_config.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/resource_service.dart';

class StylePreviewImage extends StatefulWidget {
  const StylePreviewImage(this.fileName, {super.key});
  final String fileName;
  @override
  State<StylePreviewImage> createState() => _StylePreviewImageState();
}

class _StylePreviewImageState extends State<StylePreviewImage> {
  late Future<File?> _local;
  void _resolve() {
    _local = ResourceService.instance.getLocalFile(
      widget.fileName,
      subDir: 'style_previews',
    );
  }

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant StylePreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName) _resolve();
  }

  Widget _fallback() => const ColoredBox(
    color: Color(0xFF11151C),
    child: Center(
      child: Icon(Icons.dashboard_customize, color: Colors.white24),
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: _local,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return _fallback();
      final file = snapshot.data;
      if (file != null)
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 480,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      return Image.network(
        '${BackendConfig.storageUrl}/style-previews/preview_store/${widget.fileName}',
        fit: BoxFit.cover,
        cacheWidth: 480,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    },
  );
}
