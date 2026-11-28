import 'package:flutter/material.dart';

import '../core/app_brand.dart';

/// The speedometer emblem from the installed app icon, cropped above its wordmark.
class DashboardBrandMark extends StatelessWidget {
  const DashboardBrandMark({super.key, this.width = 40});
  final double width;

  @override
  Widget build(BuildContext context) {
    final artworkSize = width / .76;
    return Semantics(
      image: true,
      label: AppBrand.appName,
      child: ClipRect(
        child: SizedBox(
          width: width,
          height: artworkSize * .38,
          child: OverflowBox(
            minWidth: artworkSize,
            maxWidth: artworkSize,
            minHeight: artworkSize,
            maxHeight: artworkSize,
            child: Transform.translate(
              offset: Offset(0, artworkSize * .13),
              child: Image.asset(
                AppBrand.logoAsset,
                width: artworkSize,
                height: artworkSize,
                cacheWidth: (artworkSize * 2.5).ceil(),
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
