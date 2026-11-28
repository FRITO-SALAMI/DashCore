import '../widget/gauges/night_drive_dashboard.dart';
import '../widget/gauges/velocity_dashboard.dart';
import '../widget/gauges/road_atlas_dashboard.dart';
import '../core/app_colors.dart';
import '../models/obd_data.dart';
import '../widget/gauges/instrument_cluster_v2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';
import '../widget/tutorial/tutorial_keys.dart';
import '../widget/style_preview_image.dart';

class StylesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const StylesScreen({super.key, required this.onBack});

  @override
  State<StylesScreen> createState() => _StylesScreenState();
}

class _StylesScreenState extends State<StylesScreen> {
  Future<void> _pickBackground(
    BuildContext context,
    DashSettingsProvider settings,
  ) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) settings.setBackgroundImage(image.path, isAsset: false);
  }

  Widget _buildStylePreview(DashboardStyle style) {
    if (style == DashboardStyle.roadAtlas) {
      return const RoadAtlasDashboard(data: ObdData(speed: 48), source: 'VISTA PREVIA', preview: true);
    }
    if (style == DashboardStyle.apexGt || style == DashboardStyle.carbonPulse) {
      return VelocityDashboard.preview(style, context.read<DashSettingsProvider>());
    }
    final design = switch (style) {
      DashboardStyle.sporty => ClusterDesign.sport,
      DashboardStyle.racing => ClusterDesign.racing,
      DashboardStyle.modern => ClusterDesign.modern,
      DashboardStyle.glowRed => ClusterDesign.glow,
      DashboardStyle.hellishRed => ClusterDesign.hellish,
      DashboardStyle.retroLcd => ClusterDesign.retro,
      DashboardStyle.classicSport => ClusterDesign.classic,
      DashboardStyle.evCluster => ClusterDesign.electric,
      DashboardStyle.racingHud ||
      DashboardStyle.raceCluster => ClusterDesign.hud,
      _ => null,
    };
    if (design != null)
      return InstrumentClusterV2(
        speed: 86,
        rpm: 2800,
        coolantTemp: 91,
        voltage: 13.8,
        design: design,
        registerTutorialTargets: false,
      );
    String imagePath = 'defaultpreview.jpeg';
    switch (style) {
      case DashboardStyle.nightDrive:
        return NightDrivePreview(
          settings: context.read<DashSettingsProvider>(),
        );
      case DashboardStyle.racing:
        imagePath = 'defaultpreview.jpeg';
        break;
      case DashboardStyle.modern:
        imagePath = 'modern.png';
        break;
      case DashboardStyle.purpleMaps:
        imagePath = 'purplemap.png';
        break;
      case DashboardStyle.glowRed:
        imagePath = 'glowred.jpg';
        break;
      case DashboardStyle.hellishRed:
        imagePath = 'hellish.png';
        break;
      case DashboardStyle.racingHud:
        imagePath = 'racinghub.png';
        break;
      case DashboardStyle.teslaStyle:
        imagePath = 'teslastyle.png';
        break;
      case DashboardStyle.classicSport:
        imagePath = 'classicsport.png';
        break;
      case DashboardStyle.retroLcd:
        imagePath = 'retrolcd.png';
        break;
      case DashboardStyle.evCluster:
        imagePath = 'evcluster.png';
        break;
      case DashboardStyle.neonWorld:
        imagePath = 'neonword.png';
        break;
      case DashboardStyle.orbitWorld:
        imagePath = 'Orbitpreview.png';
        break;
      case DashboardStyle.freeDashboard:
        imagePath = 'defaultpreview.jpeg';
        break;
      case DashboardStyle.dashcore:
        imagePath = 'Dashcorepro.png';
        break;
      case DashboardStyle.dashcorevideo:
        return Image.asset('assets/videos/road_poster.jpg', fit: BoxFit.cover, cacheWidth: 320);
      case DashboardStyle.vehicle3D:
        imagePath = 'vehicle3d.jpeg';
        break;
      case DashboardStyle.teslaRoad:
        imagePath = 'sporty.png';
        break;
      case DashboardStyle.teslaModel:
        imagePath = 'modern.png';
        break;
      default:
        imagePath = 'defaultpreview.jpeg';
    }
    return StylePreviewImage(imagePath);
  }

  Widget _styleList(DashSettingsProvider settings) {
    final styles = <DashboardStyle>{
      DashboardStyle.nightDrive,
      DashboardStyle.sporty,
      ...settings.downloadedStyles,
    }.toList();
    final tutorialStyle = styles.firstWhere(
      (s) => s != DashboardStyle.sporty && s != DashboardStyle.nightDrive,
      orElse: () => DashboardStyle.nightDrive,
    );
    final compact = MediaQuery.sizeOf(context).height < 420;
    return SizedBox(
      height: compact ? 108 : 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        cacheExtent: 180,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final style = styles[index];
          final title = switch (style) {
            DashboardStyle.nightDrive => 'NIGHT DRIVE 2.0',
            DashboardStyle.apexGt => 'APEX GT',
            DashboardStyle.carbonPulse => 'CARBON PULSE',
            DashboardStyle.roadAtlas => 'ROAD ATLAS',
            DashboardStyle.dashcorevideo => 'CARRETERA NOCTURNA',
            DashboardStyle.freeDashboard => 'DRIVE CORE',
            DashboardStyle.purpleMaps => 'PURPLE DRIVE',
            DashboardStyle.vehicle3D => 'VEHICLE 3D',
            DashboardStyle.myStyle => 'MI ESTILO',
            _ =>
              style.name
                  .replaceAllMapped(
                    RegExp(r'([a-z])([A-Z])'),
                    (m) => '${m[1]} ${m[2]}',
                  )
                  .toUpperCase(),
          };
          return _CompactStyleCard(
            key: style == tutorialStyle
                ? TutorialKeys.applyStyleButtonKey
                : ValueKey(style),
            title: title,
            style: style,
            isSelected: settings.selectedStyle == style,
            preview: _buildStylePreview(style),
            onTap: () {
              if (settings.isTutorialActive && settings.tutorialStep == 6)
                settings.setTutorialStep(7);
              settings.setStyle(style);
              widget.onBack();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.translate('styles').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.tune_rounded, size: 19),
                    label: const Text('Editar instrumentos'),
                    onPressed: () {
                      if (!settings.isEditMode) settings.toggleEditMode();
                      widget.onBack();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('dashboard').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _styleList(settings),
                    if (settings.selectedStyle == DashboardStyle.roadAtlas)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: settings.flipRoadAtlasPanels,
                          icon: const Icon(Icons.swap_horiz),
                          label: Text(settings.roadAtlasVehicleOnRight
                              ? 'Mover vehículo a la izquierda'
                              : 'Mover vehículo a la derecha'),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Acento', style: TextStyle(color: AppColors.textSecondaryColor)),
                        for (final color in const [AppColors.accent, AppColors.secondaryAccent,
                          Color(0xFF88DAB3), Color(0xFFFFBD82), Color(0xFFF38A98), Color(0xFFE3EAF6)])
                          ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: color),
                            label: const Text(' '),
                            tooltip: 'Color de acento',
                            selected: settings.accentColor == color,
                            onSelected: (_) => settings.setAccentColor(color),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('bg_image').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ActionBox(
                              icon: Icons.image_search_rounded,
                              label: 'GALLERY',
                              onTap: () => _pickBackground(context, settings),
                            ),
                            const SizedBox(width: 10),
                            _ActionBox(
                              icon: Icons.blur_on_rounded,
                              label: 'QUITAR FONDO',
                              onTap: () =>
                                  settings.setBackgroundImage('DARK_TENUE'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'FONDO',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ActionBoxCompact(
                                label: 'BLACK',
                                isSelected:
                                    settings.backgroundImage == 'COLOR_BLACK',
                                onTap: () =>
                                    settings.setBackgroundImage('COLOR_BLACK'),
                              ),
                              const SizedBox(width: 8),
                              _ActionBoxCompact(
                                label: 'CARBON',
                                isSelected:
                                    settings.backgroundImage ==
                                        'CARBON_LOCAL' ||
                                    (settings.backgroundImage?.contains(
                                          'carbon_fiber.jpg',
                                        ) ??
                                        false),
                                onTap: () => settings.setCarbonBackground(),
                              ),
                              const SizedBox(width: 8),
                              _ActionBoxCompact(
                                label: 'ESTRELLAS',
                                isSelected:
                                    settings.backgroundImage == 'STARS_LOCAL' ||
                                    (settings.backgroundImage?.contains(
                                          'Estrellas__bg.gif',
                                        ) ??
                                        false),
                                onTap: () => settings.setStarsBackground(),
                              ),
                              const SizedBox(width: 8),
                              _ActionBoxCompact(
                                label: 'VEHICLE',
                                isSelected:
                                    settings.backgroundImage ==
                                        settings
                                            .selectedVehicle
                                            ?.backgroundImage ||
                                    settings.backgroundImage ==
                                        settings
                                            .selectedVehicle
                                            ?.backgroundUrl ||
                                    (settings.selectedVehicle?.artworkPath !=
                                            null &&
                                        settings.backgroundImage ==
                                            settings
                                                .selectedVehicle
                                                ?.artworkPath),
                                onTap: () {
                                  if (settings.selectedVehicle != null) {
                                    settings.setBackgroundImage(
                                      settings.selectedVehicle!.artworkPath ??
                                          settings
                                              .selectedVehicle!
                                              .backgroundImage,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // GIFs section removed as per user request
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
  final Widget preview;
  final VoidCallback onTap;
  const _CompactStyleCard({
    super.key,
    required this.title,
    required this.style,
    required this.isSelected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: 140, // Increased size for preview
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white10,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: activeColor,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBoxCompact extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ActionBoxCompact({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeColor : Colors.white10,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
