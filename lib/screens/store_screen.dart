import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';

class StoreScreen extends StatelessWidget {
  final VoidCallback onBack;

  const StoreScreen({super.key, required this.onBack});

  Widget _buildStylePreview(DashboardStyle style) {
    switch (style) {
      case DashboardStyle.racing:
        return Container(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 10, width: 80, color: Colors.blueAccent),
              const SizedBox(height: 5),
              const Text('120', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      case DashboardStyle.modern:
        return Container(
          color: const Color(0xFF0A0B0D),
          child: Center(
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
              child: const Center(child: Text('90', style: TextStyle(color: Colors.white, fontSize: 16))),
            ),
          ),
        );
      case DashboardStyle.purplePuff:
        return Container(
          color: const Color(0xFF07050F),
          child: Row(
            children: [
              Container(width: 30, color: Colors.white.withValues(alpha: 0.05)),
              const Expanded(child: Icon(Icons.map, color: Colors.blue, size: 20)),
            ],
          ),
        );
      case DashboardStyle.glowRed:
        return Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 2))),
              const Text('180', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        );
      case DashboardStyle.hellishRed:
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            gradient: LinearGradient(colors: [Colors.black, Color(0xFF300000)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('240', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              Text('KM/H', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      default:
        return const Center(child: Icon(Icons.dashboard, color: Colors.white24));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    const themeColor = Color(0xFF00E5FF);

    final availableStyles = [
      {'style': DashboardStyle.racing, 'title': 'RACING PRO', 'desc': 'High performance gauges'},
      {'style': DashboardStyle.modern, 'title': 'MODERN EV', 'desc': 'Sleek minimalist design'},
      {'style': DashboardStyle.vehicle3D, 'title': 'VEHICLE 3D', 'desc': 'Interactive 3D model'},
      {'style': DashboardStyle.purplePuff, 'title': 'PURPLE MAP', 'desc': 'Navigation & Music'},
      {'style': DashboardStyle.racingHud, 'title': 'RACING HUD', 'desc': 'Pro Racing HUD Design'},
      {'style': DashboardStyle.glowRed, 'title': 'GLOW RED', 'desc': 'Aggressive red glow design'},
      {'style': DashboardStyle.hellishRed, 'title': 'HELLISH RED', 'desc': 'Stylized hellish theme'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1012),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: onBack),
                  const SizedBox(width: 8),
                  const Text('DASHBOARD STORE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: availableStyles.length,
                itemBuilder: (context, index) {
                  final item = availableStyles[index];
                  final style = item['style'] as DashboardStyle;
                  final isDownloaded = settings.downloadedStyles.contains(style);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDownloaded ? themeColor.withValues(alpha: 0.3) : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // PREVIEW AREA
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _buildStylePreview(style),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: Column(
                            children: [
                              Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(item['desc'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
                              const SizedBox(height: 12),
                              if (isDownloaded)
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: themeColor, size: 16),
                                    SizedBox(width: 4),
                                    Text('READY', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              else
                                ElevatedButton(
                                  onPressed: () => settings.downloadStyle(style),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('GET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
