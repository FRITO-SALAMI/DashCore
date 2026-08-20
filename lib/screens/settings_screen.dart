import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';

class _DismissibleCupertinoSheetRoute<T> extends CupertinoSheetRoute<T> {
  _DismissibleCupertinoSheetRoute({
    required super.builder,
    super.enableDrag,
    Color barrierColor = const Color(0x73000000),
  }) : _barrierColor = barrierColor;
 
  final Color _barrierColor;
  @override Color? get barrierColor => _barrierColor;
  @override bool get barrierDismissible => true;
  @override String get barrierLabel => 'Dismiss';
}

void showSettingsSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  Navigator.of(context, rootNavigator: true).push(
    _DismissibleCupertinoSheetRoute(
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (sheetContext) => NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          if (notification.extent <= notification.minExtent + 0.01) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
            });
          }
          return false;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SettingsSheet(scrollController: scrollController),
        ),
      ),
    ),
  );
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = Color(0xFF00E5FF);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF090B0F).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  
                  // LOGIN SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: themeColor,
                          child: Icon(Icons.person_rounded, color: Colors.black, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('USUARIO DASHCORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('Inicia sesión para sincronizar', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('LOGIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.translate('settings').toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                      IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _SettingsToggleTile(
                    icon: Icons.thermostat_outlined,
                    label: loc.translate('temp_unit'),
                    value: settings.tempUnit == TemperatureUnit.celsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
                    onTap: () => settings.setTempUnit(settings.tempUnit == TemperatureUnit.celsius ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius),
                  ),
                  const SizedBox(height: 12),
                  _SettingsToggleTile(
                    icon: Icons.language_rounded,
                    label: loc.translate('lang'),
                    value: settings.language == Language.english ? 'English' : 'Español',
                    onTap: () => settings.setLanguage(settings.language == Language.english ? Language.spanish : Language.english),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsToggleTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: themeColor),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.3), letterSpacing: 1.2)),
                    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.sync_rounded, size: 18, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
