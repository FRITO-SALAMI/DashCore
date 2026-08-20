import 'dart:io';
import 'package:flutter/material.dart';

class ModernDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String tempUnit;

  const ModernDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    required this.accentColor,
    this.backgroundImage,
    this.isAssetBackground = true,
    this.tempUnit = '°C',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0B0D),
      ),
      child: Stack(
        children: [
          if (backgroundImage != null)
            Opacity(
              opacity: 0.1,
              child: isAssetBackground 
                ? Image.asset(backgroundImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : Image.file(File(backgroundImage!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // LEFT: INFO
                _ModernSideInfo(label: 'MOTOR TEMP', value: '$coolantTemp$tempUnit', icon: Icons.thermostat),
                
                // CENTER: SPEEDO CIRCLE
                Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (rpm / 8000).clamp(0.0, 1.0),
                        strokeWidth: 4,
                        color: accentColor,
                        backgroundColor: Colors.white10,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$speed',
                            style: const TextStyle(color: Colors.white, fontSize: 110, fontWeight: FontWeight.w200, height: 1.0),
                          ),
                          Text(
                            'KM/H',
                            style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // RIGHT: VOLTAGE
                _ModernSideInfo(label: 'SYSTEM VOLT', value: '${voltage.toStringAsFixed(1)}V', icon: Icons.bolt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSideInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ModernSideInfo({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white24, size: 24),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}
