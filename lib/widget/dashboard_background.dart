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

    if (image == 'CARBON_LOCAL' ||
        RegExp(
          r'carbon|car1\.png|defaultpreview',
          caseSensitive: false,
        ).hasMatch(image)) {
      return Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.55),
              radius: 1.15,
              colors: [
                const Color(
                  0xFF466078,
                ).withValues(alpha: opacity.clamp(0.0, .28)),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
    }

    if (image == 'STARS_LOCAL') {
      return Positioned.fill(
        child: Opacity(
          opacity: opacity.clamp(0.65, 1.0),
          child: RepaintBoundary(
            child: CustomPaint(painter: const _LocalStars()),
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

class _LocalStars extends CustomPainter {
  const _LocalStars();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawRect(
      Offset.zero & size,
      paint
        ..shader = const RadialGradient(
          center: Alignment(-.4, .1),
          radius: .95,
          colors: [Color(0xFF142C43), Color(0xFF111728), Color(0xFF02050B)],
          stops: [0, .4, 1],
        ).createShader(Offset.zero & size),
    );
    paint.shader = null;
    for (var i = 0; i < 230; i++) {
      paint.color =
          (i % 12 == 0 ? const Color(0xFFEFD7B5) : const Color(0xFFCFDEF1))
              .withValues(alpha: .14 + i % 9 * .07);
      canvas.drawCircle(
        Offset((i * .618034 % 1) * size.width, (i * .414214 % 1) * size.height),
        i % 23 == 0 ? 1.3 : .4 + (i % 3) * .18,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LocalStars oldDelegate) => false;
}
