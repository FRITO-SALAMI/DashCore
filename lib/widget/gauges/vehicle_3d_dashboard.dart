import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Vehicle3DDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String tempUnit;
  final String modelPath;

  const Vehicle3DDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    required this.accentColor,
    required this.modelPath,
    this.backgroundImage,
    this.isAssetBackground = true,
    this.tempUnit = '°C',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // 1. 3D Model (Top Area)
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ModelViewer(
                  key: ValueKey(modelPath),
                  backgroundColor: Colors.transparent,
                  src: modelPath,
                  alt: "Vehicle 3D Model",
                  ar: false,
                  autoRotate: false,
                  cameraControls: true,
                  disableZoom: false,
                  disablePan: true,
                  cameraOrbit: '35deg 75deg 4.2m',
                  shadowIntensity: 0.1,
                  exposure: 1.0,
                  environmentImage: 'neutral',
                  loading: Loading.eager,
                ),
                Positioned(
                  left: 40, top: 40,
                  child: _DataTile(label: 'ENGINE THERMAL', value: '$coolantTemp$tempUnit', icon: Icons.thermostat_rounded, accentColor: accentColor, isLarge: true),
                ),
                Positioned(
                  right: 40, top: 40,
                  child: _DataTile(label: 'BATTERY VOLTS', value: '${voltage.toStringAsFixed(1)}V', icon: Icons.bolt_rounded, accentColor: accentColor, isLarge: true),
                ),
              ],
            ),
          ),

          // 2. Speed Info (Bottom Area)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, accentColor.withOpacity(0.05)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$speed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 180, // Much larger
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 0.9,
                      shadows: [Shadow(color: accentColor.withOpacity(0.5), blurRadius: 40)],
                    ),
                  ),
                  Text(
                    'KM/H',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, letterSpacing: 12, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SWIPE TO ROTATE VEHICLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white12, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isLarge;

  const _DataTile({required this.label, required this.value, required this.icon, required this.accentColor, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: isLarge ? 24 : 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.white38, fontSize: isLarge ? 14 : 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        Text(value, style: TextStyle(color: Colors.white, fontSize: isLarge ? 56 : 36, fontWeight: FontWeight.w900)),
        Container(width: 100, height: 4, color: accentColor.withOpacity(0.3)),
      ],
    );
  }
}
