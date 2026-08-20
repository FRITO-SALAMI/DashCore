import 'package:flutter/material.dart';

import 'bottom_bar_config.dart';
import 'bottom_bar_item.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const double _height = 82.0;

  final int currentIndex;
  final void Function(int index) onItemSelected;

  static const List<BottomBarItemData> _navItems = [
    BottomBarItemData(
      iconPath: 'assets/images/svg/bottomBar/home.svg',
      label: 'Home',
    ),
    BottomBarItemData(
      iconPath: 'assets/images/svg/bottomBar/dashboard.svg',
      label: 'Dashboard',
    ),
    BottomBarItemData(
      iconPath: 'assets/images/svg/bottomBar/connection.svg',
      label: 'Connection',
    ),
    BottomBarItemData(
      iconPath: 'assets/images/svg/bottomBar/garage.svg',
      label: 'Garage',
    ),
    BottomBarItemData(
      iconPath: 'assets/images/svg/bottomBar/dtc.svg',
      label: 'DTC',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _navItems.length,
                (index) {
              return Expanded(
                child: BottomBarItem(
                  data: _navItems[index],
                  isActive: currentIndex == index,
                  onTap: () => onItemSelected(index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}