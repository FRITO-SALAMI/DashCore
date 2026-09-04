import 'package:flutter/material.dart';

enum ConnectionTab { bluetooth, gps }

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({super.key, required this.selectedTab, required this.onTabSelected});
  final ConnectionTab selectedTab;
  final ValueChanged<ConnectionTab> onTabSelected;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _ModeCard(icon: Icons.bluetooth_connected_rounded, title: 'OBD2', description: 'DATOS REALES DEL VEHÍCULO', selected: selectedTab == ConnectionTab.bluetooth, onTap: () => onTabSelected(ConnectionTab.bluetooth))),
    const SizedBox(width: 12),
    Expanded(child: _ModeCard(icon: Icons.satellite_alt_rounded, title: 'GPS', description: 'VELOCIDAD SIN ADAPTADOR', selected: selectedTab == ConnectionTab.gps, onTap: () => onTabSelected(ConnectionTab.gps))),
  ]);
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.description, required this.selected, required this.onTap});
  final IconData icon;
  final String title, description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1 : .97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(.12) : Colors.white.withOpacity(.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent.withOpacity(.75) : Colors.white.withOpacity(.07), width: selected ? 1.5 : 1),
          boxShadow: selected ? [BoxShadow(color: accent.withOpacity(.12), blurRadius: 18)] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 220), width: 46, height: 46, decoration: BoxDecoration(color: selected ? accent : Colors.white.withOpacity(.06), shape: BoxShape.circle), child: Icon(icon, color: selected ? Colors.black : Colors.white38, size: 24)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? accent : Colors.white30, fontSize: 9, fontWeight: FontWeight.w700)),
                ])),
                AnimatedOpacity(opacity: selected ? 1 : 0, duration: const Duration(milliseconds: 180), child: const Icon(Icons.check_circle_rounded, color: accent, size: 20)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
