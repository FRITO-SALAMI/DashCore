import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/obd_provider.dart';
import 'vehicle_3d_viewer.dart';

class KiaCluster extends StatelessWidget {
  const KiaCluster({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obdProvider = context.watch<ObdProvider>();
    final data = obdProvider.data;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Visor 3D y Velocímetro Central
        Stack(
          alignment: Alignment.center,
          children: [
            // El visor 3D como fondo del cluster
            const SizedBox(
              height: 320, // Aumentado para landscape
              child: Vehicle3DViewer(radius: 280), // Radio aumentado
            ),
            
            // Velocímetro Circular Digital (Overlay)
            Positioned(
              bottom: 10,
              child: _DigitalSpeedometer(
                speed: data.speed,
                unit: 'KM/H',
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Píldoras de Telemetría (Coolant y Battery)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TelemetryPill(
                label: 'COOLANT',
                value: '${data.engineTemp}°C',
                color: const Color(0xFF5EC8E0),
                icon: Icons.thermostat,
              ),
              _TelemetryPill(
                label: 'BATTERY',
                value: '${data.voltage.toStringAsFixed(1)}V',
                color: const Color(0xFFE0C55E),
                icon: Icons.bolt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DigitalSpeedometer extends StatelessWidget {
  final int speed;
  final String unit;
  final Color color;

  const _DigitalSpeedometer({
    required this.speed,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anillo de progreso circular
        SizedBox(
          width: 180,
          height: 180,
          child: CircularProgressIndicator(
            value: (speed / 240).clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        
        // Texto de velocidad
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                letterSpacing: -2,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TelemetryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TelemetryPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131417),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
