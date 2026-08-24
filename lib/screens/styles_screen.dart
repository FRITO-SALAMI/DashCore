import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';

class StylesScreen extends StatelessWidget {
  final VoidCallback onBack;

  const StylesScreen({super.key, required this.onBack});

  Future<void> _pickBackground(BuildContext context, DashSettingsProvider settings) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) settings.setBackgroundImage(image.path, isAsset: false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1012),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: onBack),
                  const SizedBox(width: 8),
                  Text(loc.translate('styles').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.translate('dashboard').toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CompactStyleCard(
                            title: 'SPORTY',
                            style: DashboardStyle.sporty,
                            isSelected: settings.selectedStyle == DashboardStyle.sporty,
                            onTap: () {
                              settings.setStyle(DashboardStyle.sporty);
                              onBack();
                            },
                          ),
                          ...settings.downloadedStyles.where((s) => s != DashboardStyle.sporty).map((style) {
                            String title = style.name.toUpperCase();
                            if (style == DashboardStyle.purplePuff) title = 'PURPLE MAP';
                            if (style == DashboardStyle.vehicle3D) title = 'VEHICLE 3D';
                            if (style == DashboardStyle.racingHud) title = 'RACING HUD';
                            if (style == DashboardStyle.glowRed) title = 'GLOW RED';
                            if (style == DashboardStyle.hellishRed) title = 'HELLISH RED';
                            if (style == DashboardStyle.teslaStyle) title = 'TESLA STYLE';
                            if (style == DashboardStyle.classicSport) title = 'CLASSIC SPORT';
                            if (style == DashboardStyle.raceCluster) title = 'RACE CLUSTER';
                            
                            return Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _CompactStyleCard(
                                title: title,
                                style: style,
                                isSelected: settings.selectedStyle == style,
                                onTap: () {
                                  settings.setStyle(style);
                                  onBack();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('bg_image').toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ActionBox(icon: Icons.image_search_rounded, label: 'GALLERY', onTap: () => _pickBackground(context, settings)),
                            const SizedBox(width: 10),
                            _ActionBox(icon: Icons.no_photography_rounded, label: 'REMOVE', onTap: () => settings.setBackgroundImage(null)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('FONDO', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ActionBoxCompact(
                                label: 'BLACK',
                                isSelected: settings.backgroundImage == 'COLOR_BLACK',
                                onTap: () => settings.setBackgroundImage('COLOR_BLACK'),
                              ),
                              const SizedBox(width: 8),
                              _ActionBoxCompact(
                                label: 'CARBON',
                                isSelected: settings.backgroundImage == 'assets/images/png/carbon_fiber.jpg',
                                onTap: () => settings.setBackgroundImage('assets/images/png/carbon_fiber.jpg'),
                              ),
                              const SizedBox(width: 8),
                              _ActionBoxCompact(
                                label: 'VEHICLE',
                                isSelected: settings.backgroundImage == settings.selectedVehicle?.backgroundImage,
                                onTap: () {
                                  if (settings.selectedVehicle != null) {
                                    settings.setBackgroundImage(settings.selectedVehicle!.backgroundImage);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStyleCard extends StatelessWidget {
  final String title;
  final DashboardStyle style;
  final bool isSelected;
  final VoidCallback onTap;
  const _CompactStyleCard({required this.title, required this.style, required this.isSelected, required this.onTap});

  IconData _getIconForStyle(DashboardStyle style) {
    switch (style) {
      case DashboardStyle.racing: return Icons.speed;
      case DashboardStyle.modern: return Icons.electric_car;
      case DashboardStyle.vehicle3D: return Icons.view_in_ar;
      case DashboardStyle.purplePuff: return Icons.map_rounded;
      case DashboardStyle.racingHud: return Icons.radar_rounded;
      case DashboardStyle.glowRed: return Icons.brightness_auto;
      case DashboardStyle.hellishRed: return Icons.whatshot;
      case DashboardStyle.teslaStyle: return Icons.tablet_android;
      case DashboardStyle.classicSport: return Icons.settings_input_component;
      case DashboardStyle.raceCluster: return Icons.sports_motorsports;
      default: return Icons.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, width: 110,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : Colors.white10, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForStyle(style), size: 22, color: isSelected ? activeColor : Colors.white24),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBox({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10, width: 1)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white54, size: 18), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }
}

class _ActionBoxCompact extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ActionBoxCompact({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? themeColor : Colors.white10, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
