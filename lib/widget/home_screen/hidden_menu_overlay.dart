import 'package:dashcore/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/utils/app_localizations.dart';
import 'package:dashcore/widget/tutorial/tutorial_keys.dart';

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
    final user = SupabaseService.instance.currentUser;

    return GestureDetector(
      onDoubleTap: onClose,
      child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            onDoubleTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(
              color: Color(0x99000000),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 280,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              return FractionalTranslation(
                translation: offset,
                child: child,
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF0F1012),
                  border: Border(
                    right: BorderSide(
                      color: Colors.white10,
                      width: 1,
                    ),
                  ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                user != null
                                    ? (user.email ?? '').toUpperCase()
                                    : loc
                                    .translate('main_menu')
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  isSelected: currentIndex == 1,
                                  onTap: () {
                                    onItemSelected(1);
                                    onClose();
                                  },
                                ),

                                _SideMenuItem(
                                  key: TutorialKeys.stylesMenuEntryKey,
                                  icon:
                                  'assets/images/svg/bottomBar/dashboard.svg',
                                  label:
                                  loc.translate('styles').toUpperCase(),
                                  isSelected: currentIndex == 2,
                                  onTap: () {
                                    onItemSelected(2);
                                    onClose();
                                  },
                                ),

                                _SideMenuItem(
                                  key: TutorialKeys.storeMenuEntryKey,
                                  icon: Icons.shopping_cart_rounded,
                                  label: 'TIENDA',
                                  isSelected: currentIndex == 3,
                                  onTap: () {
                                    final settings = context.read<DashSettingsProvider>();
                                    if (settings.isTutorialActive && settings.tutorialStep == 2) {
                                       settings.setTutorialStep(3);
                                    }
                                    onItemSelected(3);
                                    onClose();
                                  },
                                ),

                                const Divider(color: Colors.white10, height: 20, indent: 25, endIndent: 25),

                                _SideMenuItem(
                                  key: TutorialKeys.editorMenuEntryKey,
                                  icon: Icons.edit_rounded,
                                  label: loc.translate('edit').toUpperCase(),
                                  isSelected: false,
                                  onTap: () {
                                    final settings = context.read<DashSettingsProvider>();
                                    if (settings.isTutorialActive && settings.tutorialStep == 8) {
                                      settings.setTutorialStep(9);
                                    }
                                    onClose();
                                    settings.toggleEditMode();
                                  },
                                ),

                                const Divider(color: Colors.white10, height: 20, indent: 25, endIndent: 25),

                                _SideMenuItem(
                                  key: TutorialKeys.workshopMenuEntryKey,
                                  icon: Icons.build_rounded,
                                  label: loc.translate('workshop').toUpperCase(),
                                  isSelected: currentIndex == 4,
                                  onTap: () {
                                    onItemSelected(4);
                                    onClose();
                                  },
                                ),

                                _SideMenuItem(
                                  key: TutorialKeys.settingsMenuEntryKey,
                                  icon:
                                  'assets/images/svg/dashboard/settings.svg',
                                  label:
                                  loc.translate('settings').toUpperCase(),
                                  isSelected: currentIndex == 5,
                                  onTap: () {
                                    onItemSelected(5);
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
                                  icon: Icons.system_update_rounded,
                                  label: 'ACTUALIZACIONES',
                                  isSelected: currentIndex == 6,
                                  showNotification: context.read<DashSettingsProvider>().hasUpdateAvailable,
                                  onTap: () {
                                    onItemSelected(6);
                                    onClose();
                                  },
                                ),

                                const Divider(
                                  color: Colors.white10,
                                  height: 20,
                                  indent: 25,
                                  endIndent: 25,
                                ),

                                _SideMenuItem(
                                  icon: Icons.emoji_events_rounded,
                                  label: 'DASHLEAGUE 🔥',
                                  isSelected: currentIndex == 7,
                                  onTap: () {
                                    onItemSelected(7);
                                    onClose();
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
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
  final bool showNotification;
  final VoidCallback onTap;

  const _SideMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);

    final contentColor = isSelected
        ? Colors.white
        : Colors.white54;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withOpacity(0.1)
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
            if (icon is IconData)
              Icon(
                icon as IconData,
                size: 18,
                color: isSelected
                    ? themeColor
                    : Colors.white38,
              )
            else
              SvgPicture.asset(
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

            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 14,
                  fontWeight: isSelected
                      ? FontWeight.w900
                      : FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            if (showNotification)
               Container(
                 width: 8,
                 height: 8,
                 decoration: const BoxDecoration(
                   color: Color(0xFF00E5FF),
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(color: Color(0xFF00E5FF), blurRadius: 4),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
