import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'bottom_bar_config.dart';

class BottomBarItem extends StatelessWidget {
  const BottomBarItem({
    super.key,
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final BottomBarItemData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color activeColor = colorScheme.primary;
    final Color inactiveColor = colorScheme.onSurfaceVariant;

    final Color currentColor =
    isActive ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,

              width: isActive ? 44 : 40,
              height: isActive ? 44 : 40,

              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),

              child: Center(
                child: AnimatedScale(
                  scale: isActive ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,

                  child: SvgPicture.asset(
                    data.iconPath,
                    width: 23,
                    height: 23,
                    colorFilter: ColorFilter.mode(
                      currentColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,

              style: TextStyle(
                color: currentColor,
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w500,
                letterSpacing: 0.2,
              ),

              child: Text(
                data.label,
                textScaler: TextScaler.noScaling,
              ),
            ),

            const SizedBox(height: 4),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,

              width: isActive ? 18 : 0,
              height: 2,

              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}