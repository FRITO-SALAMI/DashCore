import 'dart:io';
import 'package:flutter/material.dart';

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

    if (image == null ||
        image.isEmpty ||
        image == 'COLOR_BLACK') {
      return const SizedBox.shrink();
    }

    if (image == 'DARK_TENUE') {
      return Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Color(0xCC000000),
                Color(0xFF000000),
              ],
              radius: 1.5,
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: _buildImage(image),
      ),
    );
  }

  Widget _buildImage(String image) {
    if (isAssetBackground) {
      return Image.asset(
        image,
        key: ValueKey('gif_asset_$image'),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'DashCore Asset Error: $image\n$error',
          );

          return const SizedBox.expand(
            child: ColoredBox(
              color: Colors.black,
            ),
          );
        },
      );
    }

    if (image.startsWith('http://') ||
        image.startsWith('https://')) {
      return Image.network(
        image,
        key: ValueKey('gif_network_$image'),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'DashCore Network Background Error: $image\n$error',
          );

          return const SizedBox.shrink();
        },
      );
    }

    final filePath = image.startsWith('file://')
        ? image.substring(7)
        : image;

    return Image.file(
      File(filePath),
      key: ValueKey('gif_file_$filePath'),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          'DashCore File Background Error: $filePath\n$error',
        );

        return const SizedBox.shrink();
      },
    );
  }
}
