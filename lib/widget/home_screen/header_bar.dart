import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dashcore/core/app_brand.dart';
import 'package:dashcore/screens/settings_screen.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoSection(colorScheme: colorScheme),
        _SettingsButton(colorScheme: colorScheme),
      ],
    );
  }
}

class _LogoSection extends StatelessWidget {
  final ColorScheme colorScheme;

  const _LogoSection({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        Container(
          width: AppBrand.logoWidth,
          height: AppBrand.logoHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainer,
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            AppBrand.logoAsset,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(width: 12),

        // Nombre + slogan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppBrand.appName,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: AppBrand.fontFamily,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              AppBrand.tagline,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: AppBrand.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(
                  alpha: 0.55,
                ),
                letterSpacing: 3.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SettingsButton({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withAlpha(80),
            colorScheme.surfaceContainer,
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainer,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showSettingsSheet(context),
            borderRadius: BorderRadius.circular(100),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/svg/dashboard/settings.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}