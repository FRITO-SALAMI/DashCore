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
    if (backgroundImage == null || backgroundImage == 'COLOR_BLACK' || backgroundImage!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (isAssetBackground) {
      return Image.asset(
        backgroundImage!,
        fit: BoxFit.cover,
      );
    }

    if (backgroundImage!.startsWith('http')) {
      return Image.network(
        backgroundImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    return Image.file(
      File(backgroundImage!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
