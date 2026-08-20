import 'dart:math' as math;
import 'package:flutter/material.dart';

class HellishRedDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final String tempUnit;

  const HellishRedDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.tempUnit = '°C',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/png/hellish_bg.png'), // Placeholder or User should add it
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),
      child: Stack(
        children: [
          // The image has a very specific layout.
          // Center-ish: Speed, Battery, Coolant labels and values.
          
          Positioned(
            left: 100,
            bottom: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$speed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                  ),
                ),
                const Text(
                  'KM/H',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),

          // Battery Info
          Positioned(
            right: 150,
            bottom: 240,
            child: Row(
              children: [
                const Icon(Icons.battery_charging_full_rounded, color: Colors.white, size: 50),
                const SizedBox(width: 20),
                Text(
                  voltage.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Coolant Info
          Positioned(
            left: 80,
            bottom: 60,
            child: Row(
              children: [
                const Text(
                  'COOLANT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 100),
                Text(
                  '$coolantTemp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tempUnit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Red overlay for that "hellish" look if image is missing
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.red.withOpacity(0.05),
                  Colors.transparent,
                ],
                radius: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
