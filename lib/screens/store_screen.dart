import '../widget/gauges/night_drive_dashboard.dart';
import '../widget/gauges/velocity_dashboard.dart';
import '../widget/gauges/road_atlas_dashboard.dart';
import '../core/app_colors.dart';
import '../models/obd_data.dart';
import '../widget/gauges/instrument_cluster_v2.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import '../widget/vehicle_top_view.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';
import '../widget/tutorial/tutorial_keys.dart';
import '../widget/empty_state_widget.dart';
import '../widget/style_preview_image.dart';
import 'auth_screen.dart';
import 'download_manager_screen.dart';

class StoreScreen extends StatefulWidget {
  final VoidCallback onBack;
  const StoreScreen({super.key, required this.onBack});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.price,
    required this.name,
    required this.icon,
    required this.tagline,
    required this.benefits,
  });

  final String price, name, tagline;
  final IconData icon;
  final List<String> benefits;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101C25), Color(0xFF080B10)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(.28), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: accent, size: 40),
          const SizedBox(height: 12),
          Text(
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          Text(
            widget.price,
            style: const TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          TextButton.icon(
            onPressed: () => setState(() => expanded = !expanded),
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(expanded ? 'VER MENOS' : 'VER TODO LO INCLUIDO'),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: expanded
                ? Column(
                    children: widget.benefits
                        .map(
                          (benefit) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: accent,
                                  size: 15,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => url_launcher.launchUrl(
                Uri.parse('https://www.paypal.com/paypalme/edwinhdrd'),
                mode: url_launcher.LaunchMode.externalApplication,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'ELEGIR PLAN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategoryKey = 'free';

  @override
  void initState() {
    super.initState();
    final settings = context.read<DashSettingsProvider>();
    if (settings.isTutorialActive) {
      _selectedCategoryKey =
          settings.tutorialStep == 3 || settings.tutorialStep == 4
          ? 'free'
          : 'purchases';
    }
  }

  Future<void> _showVideoWarningOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('video_background_warning_seen') == true || !mounted)
      return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF13161D),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber,
          size: 48,
        ),
        title: const Text('AVISO DE RENDIMIENTO'),
        content: const Text(
          'LOS VIDEOS SE REPRODUCEN ÚNICAMENTE EN EL ESTILO DASHCORE VIDEO.\n\n'
          'Se limitan a ciclos cortos, sin sonido, para proteger dispositivos de 32 bits.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
    await prefs.setBool('video_background_warning_seen', true);
  }

  void _showLoginNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13161D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 12),
            Text(
              'CONTENIDO PREMIUM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: const Text(
          'INICIA SESIÓN PARA DESBLOQUEAR ESTE ESTILO Y SINCRONIZAR TUS DATOS.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'INICIAR AHORA',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreview(DashboardStyle style) {
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
      case DashboardStyle.apexGt:
      case DashboardStyle.carbonPulse:
        return VelocityDashboard.preview(
          style,
          context.read<DashSettingsProvider>(),
        );
      case DashboardStyle.roadAtlas:
        return const RoadAtlasDashboard(
          data: ObdData(speed: 48),
          source: 'VISTA PREVIA',
          preview: true,
        );
      case DashboardStyle.racing:
        imagePath = 'sporty.png';
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
      case DashboardStyle.vehicle3D:
        final vehicleSettings = context.read<DashSettingsProvider>();
        return VehicleTopView(
          colorHex: vehicleSettings.vehicleColorHex,
          vehicle: vehicleSettings.selectedVehicle,
        );
      case DashboardStyle.dashcorevideo:
        return Image.asset(
          'assets/videos/road_poster.jpg',
          fit: BoxFit.cover,
          cacheWidth: 320,
        );
      case DashboardStyle.raceCluster:
        imagePath = 'raceclusterpreview.png';
        break;
      default:
        break;
    }
    return StylePreviewImage(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = AppColors.accent;
    final isSpanish = loc.language == Language.spanish;

    final availableStyles = [
      {
        'style': DashboardStyle.nightDrive,
        'title': 'NIGHT DRIVE 2.0',
        'desc': 'Velocidad, temperatura y voltaje · tu vehículo 3D',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.roadAtlas,
        'title': 'ROAD ATLAS',
        'desc': isSpanish
            ? 'Tu vehículo con mapa en vivo'
            : 'Your vehicle with a live map',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.apexGt,
        'title': 'APEX GT',
        'desc': isSpanish
            ? 'Dos instrumentos y tu vehículo al centro'
            : 'Twin gauges with your vehicle in the center',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.carbonPulse,
        'title': 'CARBON PULSE',
        'desc': isSpanish
            ? 'Velocímetro de aguja con lectura digital'
            : 'Needle speedometer with a digital readout',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.freeDashboard,
        'title': 'DRIVE CORE',
        'desc': 'Nuevo tablero 3D gratuito',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.racing,
        'title': 'RACING PRO',
        'desc': 'High performance',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.modern,
        'title': 'MODERN EV',
        'desc': 'Sleek design',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.vehicle3D,
        'title': 'VISTA CENITAL',
        'desc': 'Interactive model',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.purpleMaps,
        'title': 'PURPLE MAPS',
        'desc': 'Nav & Music',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.racingHud,
        'title': 'RACING HUD',
        'desc': 'HUD Design',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.glowRed,
        'title': 'GLOW RED',
        'desc': 'Aggressive glow',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.hellishRed,
        'title': 'HELLISH RED',
        'desc': 'Hellish theme',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.teslaStyle,
        'title': 'TESLA STYLE',
        'desc': 'Cluster',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.classicSport,
        'title': 'CLASSIC SPORT',
        'desc': 'Mercedes style',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.raceCluster,
        'title': 'RACE CLUSTER',
        'desc': 'Race data',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.retroLcd,
        'title': 'RETRO LCD',
        'desc': '90s style',
        'cat': 'free',
      },
      {
        'style': DashboardStyle.evCluster,
        'title': 'EV CLUSTER',
        'desc': 'EV dash',
        'cat': 'premium',
      },
      {
        'style': DashboardStyle.dashcore,
        'title': 'DASHCORE PRO',
        'desc': 'Editable Gadgets',
        'cat': 'premium',
      },
      {
        'style': DashboardStyle.neonWorld,
        'title': 'NEON WORLD',
        'desc': 'Global Map Premium',
        'cat': 'premium',
      },
      {
        'style': DashboardStyle.orbitWorld,
        'title': 'ORBIT WORLD',
        'desc': 'Globo 3D ultraligero',
        'cat': 'premium',
      },
      {
        'style': DashboardStyle.dashcorevideo,
        'title': 'CARRETERA NOCTURNA',
        'desc': 'Video local en bucle',
        'cat': 'premium',
      },
    ];

    final filteredStyles = availableStyles
        .where((s) => s['cat'] == _selectedCategoryKey)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 180,
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: widget.onBack,
                ),
                const SizedBox(height: 40),
                _buildSidebarItem(loc.translate('purchases'), 'purchases'),
                _buildSidebarItem('PREMIUM', 'premium'),
                _buildSidebarItem(
                  loc.translate('free'),
                  'free',
                  keyWidget: TutorialKeys.freeCategoryKey,
                ),
                _buildSidebarItem('GIF ANIMADOS', 'GIF'),
                _buildSidebarItem('VIDEOS', 'VIDEOS'),
                const Spacer(),
                const Text(
                  'STORE v2.0',
                  style: TextStyle(
                    color: Colors.white10,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCategoryTitle(loc),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DownloadManagerScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.download_for_offline_rounded,
                          color: Color(0xFF00E5FF),
                          size: 28,
                        ),
                        tooltip: 'Gestionar Descargas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _selectedCategoryKey == 'purchases'
                        ? _buildPurchasesSection(loc)
                        : _selectedCategoryKey == 'GIF'
                        ? _buildGifSection(settings)
                        : _selectedCategoryKey == 'VIDEOS'
                        ? _buildVideoSection(settings)
                        : filteredStyles.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.auto_awesome_motion_rounded,
                            title: isSpanish
                                ? 'EN DESARROLLO (PERSONALIZACIÓN)'
                                : 'IN DEVELOPMENT (CUSTOMIZATION)',
                            description: isSpanish
                                ? 'Estamos preparando nuevos diseños increíbles para ti.'
                                : 'We are preparing new amazing designs for you.',
                            actionLabel: isSpanish ? 'VOLVER' : 'GO BACK',
                            onAction: () =>
                                setState(() => _selectedCategoryKey = 'free'),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 260,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.32,
                                ),
                            itemCount: filteredStyles.length,
                            itemBuilder: (context, index) {
                              final item = filteredStyles[index];
                              final style = item['style'] as DashboardStyle;
                              final isDownloaded = settings.downloadedStyles
                                  .contains(style);
                              final isSelected =
                                  settings.selectedStyle == style;
                              final isPremium = item['cat'] == 'premium';
                              final isLoggedIn = settings.isLoggedIn;
                              final isLocked = isPremium && !isLoggedIn;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    if (isLocked) {
                                      _showLoginNotice(context);
                                    } else if (isDownloaded) {
                                      settings.setStyle(style);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        settings.reduceMotion ||
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
                                        ? Duration.zero
                                        : const Duration(milliseconds: 140),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? themeColor
                                            : (isDownloaded
                                                  ? themeColor.withOpacity(0.2)
                                                  : Colors.white.withOpacity(
                                                      0.05,
                                                    )),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: FractionallySizedBox(
                                              heightFactor: .60,
                                              widthFactor: 1,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      6,
                                                      6,
                                                      6,
                                                      0,
                                                    ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Opacity(
                                                    opacity: isLocked ? .4 : 1,
                                                    child: IgnorePointer(
                                                      child: _buildStylePreview(
                                                        style,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        if (isLocked)
                                          const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lock_rounded,
                                                  color: Colors.white70,
                                                  size: 24,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'PREMIUM',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title'] as String,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (!isDownloaded && !isLocked)
                                                TextButton(
                                                  key:
                                                      style ==
                                                          DashboardStyle.racing
                                                      ? TutorialKeys
                                                            .freeStyleDownloadKey
                                                      : null,
                                                  onPressed: () {
                                                    settings.downloadStyle(
                                                      style,
                                                    );
                                                    if (settings
                                                            .isTutorialActive &&
                                                        settings.tutorialStep ==
                                                            4) {
                                                      settings.setTutorialStep(
                                                        5,
                                                      );
                                                      widget.onBack();
                                                    }
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(
                                                      0,
                                                      20,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    loc.translate('buy'),
                                                    style: const TextStyle(
                                                      color: themeColor,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              else if (isLocked)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  child: Text(
                                                    'BLOQUEADO',
                                                    style: TextStyle(
                                                      color: Colors.white24,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(DashSettingsProvider settings) {
    if (settings.downloadedVideos.isEmpty) {
      return _buildPackDownload(
        icon: Icons.video_collection_rounded,
        title: 'PACK DE VIDEOS DISPONIBLE',
        downloading: settings.isDownloadingVideos,
        onDownload: settings.downloadVideoPack,
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: settings.downloadedVideos.length,
      itemBuilder: (_, index) {
        final file = settings.downloadedVideos[index];
        final name = file.path
            .split(Platform.pathSeparator)
            .last
            .split('.')
            .first
            .toUpperCase();
        return Card(
          color: const Color(0xFF13161D),
          child: InkWell(
            onTap: () {
              settings.setVideoStyleSource(file.path);
              settings.setStyle(DashboardStyle.mp4Player);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('VIDEO APLICADO: $name')));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF00E5FF),
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackDownload({
    required IconData icon,
    required String title,
    required bool downloading,
    required Future<bool> Function() onDownload,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 80),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: downloading
                ? null
                : () async {
                    await onDownload();
                  },
            icon: const Icon(Icons.download_rounded),
            label: Text(
              downloading ? 'DESCARGANDO...' : 'DESCARGAR PACK (ZIP)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifSection(DashSettingsProvider settings) {
    if (settings.downloadedGifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gif_box_rounded, color: Colors.white24, size: 80),
            const SizedBox(height: 24),
            const Text(
              'PACK DE GIFS DISPONIBLE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Descarga el paquete completo de fondos animados\npara personalizar tu dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: settings.isDownloadingGifs
                    ? null
                    : () async {
                        final success = await settings.downloadGifPack();
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PACK DE GIFS DESCARGADO'),
                              backgroundColor: Color(0xFF00E5FF),
                            ),
                          );
                        }
                      },
                icon: settings.isDownloadingGifs
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  settings.isDownloadingGifs
                      ? 'DESCARGANDO...'
                      : 'DESCARGAR PACK (ZIP)',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: settings.downloadedGifs.length,
      itemBuilder: (context, index) {
        final file = settings.downloadedGifs[index];
        final fileName = file.path
            .split('/')
            .last
            .split('.')
            .first
            .toUpperCase();
        final isSelected = settings.backgroundImage == file.path;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              settings.setBackgroundImage(file.path, isAsset: false);
              settings.downloadStyle(DashboardStyle.gifSpeedo);
              settings.setStyle(DashboardStyle.gifSpeedo);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("GIF APLICADO: $fileName"),
                  backgroundColor: const Color(0xFF00E5FF),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TickerMode(
                      enabled:
                          !settings.isLowResourceDevice &&
                          !settings.reduceMotion,
                      child: Image(
                        image: ResizeImage(
                          FileImage(file),
                          width: 480,
                          height: 270,
                          policy: ResizeImagePolicy.fit,
                        ),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: Color(0xFF11151C)),
                      ),
                    ),
                    Container(color: Colors.black.withOpacity(0.2)),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCategoryTitle(AppLocalizations loc) {
    if (_selectedCategoryKey == 'purchases')
      return loc.translate('purchases').toUpperCase();
    if (_selectedCategoryKey == 'recent')
      return loc.translate('recent').toUpperCase();
    if (_selectedCategoryKey == 'free')
      return loc.translate('free').toUpperCase();
    if (_selectedCategoryKey == 'GIF') return 'GIF ANIMADOS';
    if (_selectedCategoryKey == 'VIDEOS') return 'VIDEOS';
    return _selectedCategoryKey.toUpperCase();
  }

  Widget _buildPurchasesSection(AppLocalizations loc) {
    final isSpanish = loc.language == Language.spanish;
    final plans = [
      (
        'US\$1',
        isSpanish ? 'APOYO' : 'SUPPORT',
        Icons.favorite_rounded,
        isSpanish ? 'Empieza a formar parte' : 'Start being part of it',
        [
          isSpanish ? 'Insignia Supporter' : 'Supporter badge',
          isSpanish ? 'Novedades del proyecto' : 'Project updates',
          isSpanish ? 'Voto en mejoras futuras' : 'Vote on future improvements',
        ],
      ),
      (
        'US\$5',
        'PRO',
        Icons.workspace_premium_rounded,
        isSpanish ? 'Desbloquea más DashCore' : 'Unlock more DashCore',
        [
          isSpanish ? 'Todo lo de Apoyo' : 'Everything in Support',
          isSpanish
              ? 'Funciones y estilos especiales'
              : 'Special features and styles',
          isSpanish
              ? 'Acceso anticipado a mejoras'
              : 'Early access to improvements',
          isSpanish ? 'Grupo privado de mejoras' : 'Private improvements group',
        ],
      ),
      (
        'US\$10',
        'LEGEND',
        Icons.emoji_events_rounded,
        isSpanish ? 'Ayuda a construir el futuro' : 'Help build the future',
        [
          isSpanish ? 'Todo lo de Pro' : 'Everything in Pro',
          isSpanish
              ? 'Grupo para crear nuevos dashboards'
              : 'Dashboard creation group',
          isSpanish ? 'Prioridad en propuestas' : 'Priority feature proposals',
          isSpanish
              ? 'Videos y diseños exclusivos'
              : 'Exclusive videos and designs',
          isSpanish ? 'Reconocimiento Legend' : 'Legend recognition',
        ],
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: plans
          .map(
            (plan) => Expanded(
              child: _PlanCard(
                price: plan.$1,
                name: plan.$2,
                icon: plan.$3,
                tagline: plan.$4,
                benefits: plan.$5,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSidebarItem(String title, String key, {GlobalKey? keyWidget}) {
    final isSelected = _selectedCategoryKey == key;
    return GestureDetector(
      key: keyWidget,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedCategoryKey = key);
        if (key == 'VIDEOS') _showVideoWarningOnce();
        final settings = context.read<DashSettingsProvider>();
        if (key == 'free' &&
            settings.isTutorialActive &&
            settings.tutorialStep == 3) {
          settings.setTutorialStep(4);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  right: BorderSide(color: Color(0xFF00E5FF), width: 3),
                )
              : null,
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.1),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white24,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
