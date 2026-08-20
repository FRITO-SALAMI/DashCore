import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/services/realdash_import_service.dart';
import 'package:dashcore/utils/app_localizations.dart';

class HiddenMenuOverlay extends StatelessWidget {
  final int currentIndex;
  final void Function(int index) onItemSelected;
  final VoidCallback onClose;

  const HiddenMenuOverlay({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            onDoubleTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: -280, end: 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Positioned(
                left: value,
                top: 0,
                bottom: 0,
                width: 280,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1012).withValues(alpha: 0.98),
                    border: const Border(
                      right: BorderSide(
                        color: Colors.white10,
                        width: 1,
                      ),
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              25,
                              30,
                              25,
                              30,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DASHCORE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                ),
                                Text(
                                  loc
                                      .translate('main_menu')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _SideMenuItem(
                                    icon:
                                        'assets/images/svg/bottomBar/home.svg',
                                    label: loc
                                        .translate('dashboard')
                                        .toUpperCase(),
                                    isSelected: currentIndex == 0,
                                    onTap: () {
                                      onItemSelected(0);
                                      onClose();
                                    },
                                  ),

                                  _SideMenuItem(
                                    icon:
                                        'assets/images/svg/bottomBar/connection.svg',
                                    label: loc
                                        .translate('connection')
                                        .toUpperCase(),
                                    isSelected: currentIndex == 2,
                                    onTap: () {
                                      onItemSelected(1);
                                      onClose();
                                    },
                                  ),

                                  _SideMenuItem(
                                    icon:
                                        'assets/images/svg/bottomBar/dashboard.svg',
                                    label: loc
                                        .translate('styles')
                                        .toUpperCase(),
                                    isSelected: currentIndex == 4,
                                    onTap: () {
                                      onItemSelected(2);
                                      onClose();
                                    },
                                  ),

                                  _SideMenuItem(
                                    icon: Icons.shopping_cart_rounded,
                                    label: 'TIENDA',
                                    isSelected: currentIndex == 5,
                                    onTap: () {
                                      onItemSelected(3);
                                      onClose();
                                    },
                                  ),

                                  _SideMenuItem(
                                    icon: Icons.edit_rounded,
                                    label: 'EDITAR',
                                    isSelected: false,
                                    onTap: () {
                                      onClose();
                                      context
                                          .read<DashSettingsProvider>()
                                          .toggleEditMode();
                                    },
                                  ),

                                  _SideMenuItem(
                                    icon:
                                        'assets/images/svg/dashboard/settings.svg',
                                    label: loc
                                        .translate('settings')
                                        .toUpperCase(),
                                    isSelected: false,
                                    onTap: () {
                                      onItemSelected(4);
                                      onClose();
                                    },
                                  ),

                                  const Divider(
                                    color: Colors.white10,
                                    height: 30,
                                    indent: 25,
                                    endIndent: 25,
                                  ),

                                  _SideMenuItem(
                                    icon: Icons.import_export_rounded,
                                    label: 'IMPORTAR/EXPORTAR .RD',
                                    isSelected: false,
                                    onTap: () =>
                                        RealDashImportService.importRDFile(
                                      context,
                                    ),
                                  ),

                                  const Divider(
                                    color: Colors.white10,
                                    height: 30,
                                    indent: 25,
                                    endIndent: 25,
                                  ),

                                  _SideMenuItem(
                                    icon: Icons.system_update_rounded,
                                    label: 'ACTUALIZACIONES',
                                    isSelected: false,
                                    onTap: () {
                                      onClose();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'BUSCANDO ACTUALIZACIONES...',
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const Divider(
                                    color: Colors.white10,
                                    height: 30,
                                    indent: 25,
                                    endIndent: 25,
                                  ),

                                  _SideMenuItem(
                                    icon: Icons.logout_rounded,
                                    label: 'CERRAR SESIÓN',
                                    isSelected: false,
                                    onTap: () async {
                                      onClose();

                                      await Supabase
                                          .instance
                                          .client
                                          .auth
                                          .signOut();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc
                                      .translate('double_tap_close')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white10,
                                    fontSize: 8,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'By Frito-Salami',
                                  style: TextStyle(
                                    color: Colors.white10,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    final contentColor =
        isSelected ? Colors.white : Colors.white54;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(
                    color: themeColor,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            icon is IconData
                ? Icon(
                    icon as IconData,
                    size: 18,
                    color: isSelected
                        ? themeColor
                        : Colors.white38,
                  )
                : SvgPicture.asset(
                    icon as String,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? themeColor
                          : Colors.white38,
                      BlendMode.srcIn,
                    ),
                  ),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: contentColor,
                fontSize: 14,
                fontWeight: isSelected
                    ? FontWeight.w900
                    : FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}