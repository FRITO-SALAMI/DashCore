import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';

class StoreScreen extends StatefulWidget {
  final VoidCallback onBack;

  const StoreScreen({super.key, required this.onBack});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'GRATIS';

  Widget _buildStylePreview(DashboardStyle style) {
    String imagePath = '';

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
      case DashboardStyle.teslaRoad:
        imagePath = 'assets/images/preview_store/sporty.png';
        break;
      case DashboardStyle.teslaModel:
        imagePath = 'assets/images/preview_store/modern.png';
        break;
      default:
        imagePath = 'assets/images/preview_store/defualtpreview.jpeg';
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    const themeColor = Color(0xFF00E5FF);

    final availableStyles = [
      {'style': DashboardStyle.racing, 'title': 'RACING PRO', 'desc': 'High performance', 'cat': 'GRATIS'},
      {'style': DashboardStyle.modern, 'title': 'MODERN EV', 'desc': 'Sleek design', 'cat': 'GRATIS'},
      {'style': DashboardStyle.vehicle3D, 'title': 'VEHICLE 3D', 'desc': 'Interactive model', 'cat': 'GRATIS'},
      {'style': DashboardStyle.purpleMaps, 'title': 'PURPLE MAPS', 'desc': 'Nav & Music', 'cat': 'GRATIS'},
      {'style': DashboardStyle.racingHud, 'title': 'RACING HUD', 'desc': 'HUD Design', 'cat': 'GRATIS'},
      {'style': DashboardStyle.glowRed, 'title': 'GLOW RED', 'desc': 'Aggressive glow', 'cat': 'GRATIS'},
      {'style': DashboardStyle.hellishRed, 'title': 'HELLISH RED', 'desc': 'Hellish theme', 'cat': 'GRATIS'},
      {'style': DashboardStyle.teslaStyle, 'title': 'TESLA STYLE', 'desc': 'Cluster', 'cat': 'GRATIS'},
      {'style': DashboardStyle.classicSport, 'title': 'CLASSIC SPORT', 'desc': 'Mercedes style', 'cat': 'GRATIS'},
      {'style': DashboardStyle.raceCluster, 'title': 'RACE CLUSTER', 'desc': 'Race data', 'cat': 'GRATIS'},
      {'style': DashboardStyle.retroLcd, 'title': 'RETRO LCD', 'desc': '90s style', 'cat': 'GRATIS'},
      {'style': DashboardStyle.evCluster, 'title': 'EV CLUSTER', 'desc': 'EV dash', 'cat': 'GRATIS'},
      {'style': DashboardStyle.dashcore, 'title': 'DASHCORE PRO', 'desc': 'Editable Gadgets', 'cat': 'PREMIUM'},
      {'style': DashboardStyle.neonWorld, 'title': 'NEON WORLD', 'desc': 'Global Map Premium', 'cat': 'PREMIUM'},
    ];

    final availableGifs = [
      {'title': 'GTR DRIFT', 'path': 'assets/images/gifstore/Gtrdm.gif'},
      {'title': 'ROT FIT', 'path': 'assets/images/gifstore/RotFIT.gif'},
      {'title': 'KIA LOGO', 'path': 'assets/images/gifstore/logokia.gif'},
      {'title': 'AVENTADOR', 'path': 'assets/images/gifstore/aventador.gif'},
      {'title': 'NISSAN GTR', 'path': 'assets/images/gifstore/NissanGTR.gif'},
      {'title': 'HYUNDAI', 'path': 'assets/images/gifstore/logohyuinda.gif'},
      {'title': 'SKYLINE', 'path': 'assets/images/gifstore/tenorNissanSkyline.gif'},
    ];

    final filteredStyles = availableStyles.where((s) => s['cat'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF08090B),
      body: Row(
        children: [
          // Sidebar Menu
          Container(
            width: 180,
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: widget.onBack),
                const SizedBox(height: 40),
                _buildSidebarItem('RECIENTE'),
                _buildSidebarItem('PREMIUM'),
                _buildSidebarItem('GRATIS'),
                _buildSidebarItem('GIF'),
                const Spacer(),
                const Text('STORE v2.0', style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory, 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _selectedCategory == 'GIF'
                      ? GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: availableGifs.length,
                          itemBuilder: (context, index) {
                            final gif = availableGifs[index];
                            final isSelected = settings.backgroundImage == gif['path'];

                            return GestureDetector(
                              onTap: () {
                                settings.setBackgroundImage(gif['path'] as String, isAsset: true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('GIF ${gif['title']} APLICADO'), duration: const Duration(seconds: 1))
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? themeColor : Colors.white10,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(gif['path'] as String, fit: BoxFit.cover),
                                      Container(color: Colors.black.withOpacity(0.4)),
                                      Center(
                                        child: Text(
                                          gif['title'] as String,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : filteredStyles.isEmpty 
                      ? const Center(
                          child: Text(
                            'COMMING SOON', 
                            style: TextStyle(
                              color: Colors.white24, 
                              fontSize: 32, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 10
                            )
                          ),
                        )
                      : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 per row
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: filteredStyles.length,
                      itemBuilder: (context, index) {
                        final item = filteredStyles[index];
                        final style = item['style'] as DashboardStyle;
                        final isDownloaded = settings.downloadedStyles.contains(style);
                        final isSelected = settings.selectedStyle == style;

                        return GestureDetector(
                          onTap: isDownloaded ? () => settings.setStyle(style) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? themeColor : (isDownloaded ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: _buildStylePreview(style),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String, 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isDownloaded)
                                        TextButton(
                                          onPressed: () => settings.downloadStyle(style),
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 20)),
                                          child: const Text('DOWNLOAD', style: TextStyle(color: themeColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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

  Widget _buildSidebarItem(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: isSelected ? const Border(right: BorderSide(color: Color(0xFF00E5FF), width: 3)) : null,
          gradient: isSelected ? LinearGradient(colors: [const Color(0xFF00E5FF).withOpacity(0.1), Colors.transparent]) : null,
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
