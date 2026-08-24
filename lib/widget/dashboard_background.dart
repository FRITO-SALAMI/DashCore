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
        child: isAssetBackground
            ? Image.asset(
                backgroundImage!,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(backgroundImage!),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
