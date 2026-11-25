import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dash_settings_provider.dart';

class DashboardBackground extends StatelessWidget {
  final String? backgroundImage;
  final bool isAssetBackground;
  final double opacity;

  const DashboardBackground({
    super.key,
    required this.backgroundImage,
    this.isAssetBackground = true,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    final image = backgroundImage;

    if (image == null || image.isEmpty || image == 'COLOR_BLACK') {
      return const SizedBox.shrink();
    }

    if (image == 'CARBON_LOCAL' || image == 'STARS_LOCAL') {
      return Positioned.fill(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: RepaintBoundary(
            child: CustomPaint(painter: _LocalTexture(image == 'STARS_LOCAL')),
          ),
        ),
      );
    }

    if (image == 'DARK_TENUE') {
      return Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xCC000000), Color(0xFF000000)],
              radius: 1.5,
            ),
          ),
        ),
      );
    }

    // MP4 is intentionally restricted to the DashCore Video style. Decoding
    // it behind 3D/animated dashboards exhausts GPU memory on 32-bit devices.
    if (_isVideo(image)) return const SizedBox.shrink();

    return Positioned.fill(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: _buildImage(context, image),
      ),
    );
  }

  bool _isVideo(String path) {
    final value = path.toLowerCase();
    return value.endsWith('.mp4') ||
        value.endsWith('.webm') ||
        value.endsWith('.mov');
  }

  Widget _buildImage(BuildContext context, String image) {
    final lowResource = context.select<DashSettingsProvider?, bool>(
      (settings) => settings?.isLowResourceDevice ?? false,
    );
    final reduceMotion =
        context.select<DashSettingsProvider?, bool>(
          (settings) => settings?.reduceMotion ?? false,
        ) ||
        MediaQuery.disableAnimationsOf(context);
    final uri = Uri.tryParse(image);
    final ImageProvider source = isAssetBackground
        ? AssetImage(image)
        : uri?.scheme == 'http' || uri?.scheme == 'https'
        ? NetworkImage(image)
        : FileImage(uri?.scheme == 'file' ? File.fromUri(uri!) : File(image));
    return TickerMode(
      enabled: !reduceMotion,
      child: Image(
        image: ResizeImage(
          source,
          width: lowResource ? 960 : 1440,
          height: lowResource ? 540 : 900,
          policy: ResizeImagePolicy.fit,
        ),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _LocalTexture extends CustomPainter {
  const _LocalTexture(this.stars);
  final bool stars;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94AABE)
      ..strokeWidth = 1;
    if (stars) {
      for (var i = 0; i < 80; i++) {
        canvas.drawCircle(
          Offset(
            (i * 137.51 % 997) / 997 * size.width,
            (i * 83.17 % 503) / 503 * size.height,
          ),
          i % 9 == 0 ? 1.5 : .7,
          paint,
        );
      }
    } else {
      for (double x = -size.height; x < size.width; x += 12) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LocalTexture oldDelegate) =>
      stars != oldDelegate.stars;
}
