import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';

class RacingDashboard extends StatelessWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final Color accentColor;
  final String? backgroundImage;
  final bool isAssetBackground;
  final String tempUnit;

  const RacingDashboard({
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
      color: Colors.black,
      child: Stack(
        children: [
          if (backgroundImage != null)
            Opacity(
              opacity: 0.1,
              child: isAssetBackground 
                ? Image.asset(backgroundImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : Image.file(File(backgroundImage!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          Column(
            children: [
              // TOP RPM BAR (Racing style)
              _RacingRpmBar(rpm: rpm, accentColor: accentColor),
              
              Expanded(
                child: Row(
                  children: [
                    // LEFT: TEMP & VOLT
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CompactGauge(label: 'TEMP', value: '$coolantTemp', unit: tempUnit, color: Colors.blueAccent),
                          const SizedBox(height: 40),
                          _CompactGauge(label: 'BATT', value: voltage.toStringAsFixed(1), unit: 'V', color: Colors.yellowAccent),
                        ],
                      ),
                    ),
                    
                    // CENTER: LARGE SPEED
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$speed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 160,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                height: 0.9,
                              ),
                            ),
                            Text(
                              'KM/H',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // RIGHT: GEAR & SHIFT LIGHT
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: rpm > 7000 ? Colors.red : Colors.white24, width: 4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              speed == 0 ? 'N' : '1', // Placeholder gear
                              style: TextStyle(
                                color: rpm > 7000 ? Colors.red : Colors.white,
                                fontSize: 70,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RacingRpmBar extends StatelessWidget {
  final int rpm;
  final Color accentColor;
  const _RacingRpmBar({required this.rpm, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final progress = (rpm / 8000).clamp(0.0, 1.0);
    
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, Colors.orange, Colors.red],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: rpm > 6500 ? Colors.red.withOpacity(0.5) : Colors.transparent, blurRadius: 15),
                ],
              ),
            ),
          ),
          // Numbers 1-8
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(9, (i) => Text('$i', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
        ],
      ),
    );
  }
}

class _CompactGauge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _CompactGauge({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        Text(unit, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
