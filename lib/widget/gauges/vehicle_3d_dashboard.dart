import 'dart:io';
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
      child: Stack(
        children: [
          // 1. 3D Model (Full Background)
          ModelViewer(
            backgroundColor: Colors.transparent,
            src: modelPath,
            alt: "Vehicle 3D Model",
            ar: false,
            autoRotate: false,
            cameraControls: true,
            disableZoom: false,
            disablePan: true,
            cameraOrbit: '35deg 75deg 4.2m',
            shadowIntensity: 1,
            exposure: 1.0,
            environmentImage: 'neutral',
            loading: Loading.eager,
          ),

          // 2. Telemetry Overlays
          // Speedo (Bottom Center)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$speed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                      shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 25)],
                    ),
                  ),
                  const Text(
                    'KM/H',
                    style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, letterSpacing: 6, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // RPM Progress (Top)
          Positioned(
            top: 20,
            left: 60,
            right: 60,
            child: Column(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (rpm / 8000).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [const BoxShadow(color: Color(0xFF00E5FF), blurRadius: 10)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(9, (i) => Text('${i}k', style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold))),
                ),
              ],
            ),
          ),

          // Side Data
          Positioned(
            left: 30,
            bottom: 30,
            child: _DataTile(label: 'MOTOR', value: '$coolantTemp$tempUnit', icon: Icons.thermostat_rounded),
          ),
          Positioned(
            right: 30,
            bottom: 30,
            child: _DataTile(label: 'SYSTEM', value: '${voltage.toStringAsFixed(1)}V', icon: Icons.bolt_rounded),
          ),
          
          // Rotation Helper
          const Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Text(
              'DESLIZA PARA ROTAR EL VEHÍCULO',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white12, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold),
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

  const _DataTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
