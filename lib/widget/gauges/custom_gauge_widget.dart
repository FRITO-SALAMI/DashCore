import 'package:flutter/material.dart';

class CustomGaugeWidget extends StatelessWidget {
  final String type;
  final dynamic value;
  final String unit;
  final Color color;

  const CustomGaugeWidget({super.key, required this.type, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(unit, style: const TextStyle(color: Colors.white24, fontSize: 8)),
        ],
      ),
    );
  }
}
