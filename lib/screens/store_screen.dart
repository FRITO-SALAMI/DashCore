import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../services/supabase_service.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';
import '../widget/tutorial/tutorial_keys.dart';
import '../widget/empty_state_widget.dart';
import 'auth_screen.dart';
import 'download_manager_screen.dart';

class StoreScreen extends StatefulWidget {
  final VoidCallback onBack;
  const StoreScreen({super.key, required this.onBack});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategoryKey = 'purchases';

  @override
  void initState() {
    super.initState();
    final settings = context.read<DashSettingsProvider>();
    if (settings.isTutorialActive && settings.tutorialStep == 2) {
      _selectedCategoryKey = 'purchases';
    }
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
    String imagePath = 'assets/images/preview_store/defualtpreview.jpeg';
    switch (style) {
      case DashboardStyle.racing:
        imagePath = 'assets/images/preview_store/sporty.png';
        break;
      case DashboardStyle.modern:
        imagePath = 'assets/images/preview_store/modern.png';
        break;
      case DashboardStyle.purpleMaps:
        imagePath = 'assets/images/preview_store/purplemap.png';
        break;
      case DashboardStyle.glowRed:
        imagePath = 'assets/images/preview_store/glowred.jpg';
        break;
      case DashboardStyle.hellishRed:
        imagePath = 'assets/images/preview_store/hellish.png';
        break;
      case DashboardStyle.racingHud:
        imagePath = 'assets/images/preview_store/racinghub.png';
        break;
      case DashboardStyle.teslaStyle:
        imagePath = 'assets/images/preview_store/teslastyle.png';
        break;
      case DashboardStyle.classicSport:
        imagePath = 'assets/images/preview_store/classicsport.png';
        break;
      case DashboardStyle.retroLcd:
        imagePath = 'assets/images/preview_store/retrolcd.png';
        break;
      case DashboardStyle.evCluster:
        imagePath = 'assets/images/preview_store/evcluster.png';
        break;
      case DashboardStyle.neonWorld:
        imagePath = 'assets/images/preview_store/neonword.png';
        break;
      case DashboardStyle.dashcore:
        imagePath = 'assets/images/preview_store/Dashcorepro.png';
        break;
      case DashboardStyle.vehicle3D:
        imagePath = 'assets/images/preview_store/vehicle3d.jpeg';
        break;
      default:
        break;
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_rounded, color: Colors.white12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    const themeColor = Color(0xFF00E5FF);
    final isSpanish = loc.language == Language.spanish;

    final availableStyles = [
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
        'title': 'VEHICLE 3D',
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
        'style': DashboardStyle.dashcorevideo,
        'title': 'DASHCOREVIDEO',
        'desc': 'Video Dashboard',
        'cat': 'premium',
      },
    ];

    final filteredStyles = availableStyles
        .where((s) => s['cat'] == _selectedCategoryKey)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF08090B),
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
                _buildSidebarItem('GIF ANIMADOS', 'GIF'),
                _buildSidebarItem('PREMIUM', 'premium'),
                _buildSidebarItem(
                  loc.translate('free'),
                  'free',
                  keyWidget: TutorialKeys.freeCategoryKey,
                ),
                _buildSidebarItem(loc.translate('recent'), 'recent'),
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
                          MaterialPageRoute(builder: (_) => const DownloadManagerScreen())
                        ),
                        icon: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF00E5FF), size: 28),
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
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.2,
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
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
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
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: Opacity(
                                              opacity: isLocked ? 0.3 : 1.0,
                                              child: _buildStylePreview(style),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.9),
                                                ],
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
                                                      (item['cat'] == 'free' &&
                                                          index == 0)
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            const Text(
              'Descarga el paquete completo de fondos animados\npara personalizar tu dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: settings.isDownloadingGifs ? null : () async {
                  final success = await settings.downloadGifPack();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PACK DE GIFS DESCARGADO'), backgroundColor: Color(0xFF00E5FF))
                    );
                  }
                },
                icon: settings.isDownloadingGifs
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.download_rounded),
                label: Text(settings.isDownloadingGifs ? 'DESCARGANDO...' : 'DESCARGAR PACK (ZIP)', style: const TextStyle(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        final fileName = file.path.split('/').last.split('.').first.toUpperCase();
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
                SnackBar(content: Text("GIF APLICADO: $fileName"), backgroundColor: const Color(0xFF00E5FF), duration: const Duration(seconds: 2))
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
                    Image.file(file, fit: BoxFit.cover, gaplessPlayback: true),
                    Container(color: Colors.black.withOpacity(0.2)),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Text(
                        fileName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
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
    return _selectedCategoryKey.toUpperCase();
  }

  Widget _buildPurchasesSection(AppLocalizations loc) {
    final isSpanish = loc.language == Language.spanish;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.05),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 60),
            const SizedBox(height: 20),
            const Text(
              'PONGA ALGO PATRON',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              isSpanish
                  ? 'Acceso ilimitado a todos los estilos premium, HUDs y telemetría avanzada.'
                  : 'Unlimited access to all premium styles, HUDs and advanced telemetry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  url_launcher.launchUrl(
                    Uri.parse('https://www.paypal.com/paypalme/edwinhdrd'),
                    mode: url_launcher.LaunchMode.externalApplication,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 10,
                ),
                child: const Text(
                  'DONAR',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String title, String key, {GlobalKey? keyWidget}) {
    final isSelected = _selectedCategoryKey == key;
    return GestureDetector(
      key: keyWidget,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedCategoryKey = key);
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
