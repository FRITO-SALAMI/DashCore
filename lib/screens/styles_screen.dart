import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _pick3DModel(BuildContext context, DashSettingsProvider settings) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['glb', 'gltf']);
    if (result != null && result.files.single.path != null) {
      settings.setModelPath(result.files.single.path!);
      settings.setStyle(DashboardStyle.vehicle3D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = Color(0xFF00E5FF);

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
                          _CompactStyleCard(title: 'SPORTY', style: DashboardStyle.sporty, isSelected: settings.selectedStyle == DashboardStyle.sporty, onTap: () => settings.setStyle(DashboardStyle.sporty)),
                          ...settings.downloadedStyles.where((s) => s != DashboardStyle.sporty).map((style) {
                            String title = style.name.toUpperCase();
                            if (style == DashboardStyle.purplePuff) title = 'PURPLE MAP';
                            if (style == DashboardStyle.vehicle3D) title = 'VEHICLE 3D';
                            if (style == DashboardStyle.racingHud) title = 'RACING HUD';
                            if (style == DashboardStyle.glowRed) title = 'GLOW RED';
                            if (style == DashboardStyle.hellishRed) title = 'HELLISH RED';
                            
                            return Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _CompactStyleCard(
                                title: title,
                                style: style,
                                isSelected: settings.selectedStyle == style,
                                onTap: () => settings.setStyle(style),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('3D MODEL (.GLB)', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _ActionBox(icon: Icons.view_in_ar_rounded, label: 'SELECT .GLB', onTap: () => _pick3DModel(context, settings)),
                                  const SizedBox(width: 10),
                                  _ActionBox(icon: Icons.restore_rounded, label: 'DEFAULT', onTap: () => settings.setModelPath('assets/models/OPTIMA2012.GLB')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(loc.translate('accent_color').toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        _ColorCircle(color: themeColor, isSelected: settings.accentColor.toARGB32() == themeColor.toARGB32(), onTap: () => settings.setAccentColor(themeColor)),
                        _ColorCircle(color: Colors.blueAccent, isSelected: settings.accentColor == Colors.blueAccent, onTap: () => settings.setAccentColor(Colors.blueAccent)),
                        _ColorCircle(color: Colors.redAccent, isSelected: settings.accentColor == Colors.redAccent, onTap: () => settings.setAccentColor(Colors.redAccent)),
                        _ColorCircle(color: Colors.orangeAccent, isSelected: settings.accentColor == Colors.orangeAccent, onTap: () => settings.setAccentColor(Colors.orangeAccent)),
                        _ColorCircle(color: Colors.purpleAccent, isSelected: settings.accentColor == Colors.purpleAccent, onTap: () => settings.setAccentColor(Colors.purpleAccent)),
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
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
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

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _ColorCircle({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2)),
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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10, width: 1)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white54, size: 18), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }
}
