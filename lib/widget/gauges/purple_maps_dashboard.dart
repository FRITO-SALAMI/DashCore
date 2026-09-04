import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../music_hub.dart';
import 'dart:async';
import '../../providers/music_provider.dart';
import '../../providers/obd_provider.dart';
import 'dart:math' as math;

class PurpleMapsDashboard extends StatefulWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;

  const PurpleMapsDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
  });

  @override
  State<PurpleMapsDashboard> createState() => _PurpleMapsDashboardState();
}

class _PurpleMapsDashboardState extends State<PurpleMapsDashboard> {
  MapLibreMapController? _mapController;
  Position? _currentPos;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSharedLocation();
  }

  void _listenToSharedLocation() {
    _positionSubscription = context.read<ObdProvider>().gpsPositions.listen((
      p,
    ) {
      if (mounted) {
        setState(() => _currentPos = p);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(p.latitude, p.longitude)),
        );
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    const darkPurple = Color(0xFF0D0216);

    return Container(
      color: darkPurple,
      child: Stack(
        children: [
          // 1. MAPA (REDISEÑADO - MÁS PEQUEÑO Y CENTRADO)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 25,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: MapLibreMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPos?.latitude ?? 0,
                      _currentPos?.longitude ?? 0,
                    ),
                    zoom: 17, // Closer zoom
                    tilt: 70, // Max tilt for 3D realism
                  ),
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: true,
                  styleString: 'https://demotiles.maplibre.org/style.json',
                ),
              ),
            ),
          ),

          // 2. VELOCIDAD (GRANDE Y ESTILIZADA ABAJO DEL MAPA)
          Positioned(
            bottom: 60,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.speed}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 110,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1,
                    letterSpacing: -4,
                    shadows: [
                      Shadow(color: Colors.purple, blurRadius: 20),
                    ],
                  ),
                ),
                const Text(
                  'KM/H',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),

          // 3. REPRODUCTOR DE MÚSICA (PEGADO ABAJO A LA IZQUIERDA)
          Positioned(
            bottom: 20,
            left: 20,
            width: 320,
            child: const MusicHub(accentColor: Color(0xFFB44CFF), width: 320),
          ),

          // 4. TACÓMETRO (OPCIONAL O MÁS DISCRETO - MOVIDO A LA DERECHA DEL MAPA)
          // Actually user said "velocimetro mejor colocado", I will make the speedometer more prominent and the tacho smaller in a corner.
          Positioned(
            top: 40,
            right: 40,
            width: 140,
            height: 140,
            child: _PurpleTachometer(rpm: widget.rpm),
          ),

          // 5. GADGETS TEMP Y VOLT (ESQUINA SUPERIOR IZQUIERDA, LEÍBLES)
          Positioned(
            top: 40,
            left: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniGauge(
                    label: 'TEMP',
                    value: '${widget.coolantTemp}',
                    unit: '°C',
                    icon: Icons.thermostat_rounded,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(height: 12),
                  _MiniGauge(
                    label: 'VOLT',
                    value: widget.voltage.toStringAsFixed(1),
                    unit: 'V',
                    icon: Icons.bolt_rounded,
                    color: Colors.orangeAccent,
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

class _MiniGauge extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _MiniGauge({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 2),
                Text(unit, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PurpleTachometer extends StatelessWidget {
  final int rpm;
  const _PurpleTachometer({required this.rpm});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TachoPainter(rpm: rpm),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(rpm / 1000).toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'RPM x1000',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TachoPainter extends CustomPainter {
  final int rpm;
  _TachoPainter({required this.rpm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    final stroke = 12.0;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final segments = 40;
    final segmentGap = 0.02 * math.pi;
    final segmentSweep = (sweepAngle / segments) - segmentGap;

    for (int i = 0; i < segments; i++) {
      final progress = i / segments;
      final angle = startAngle + (sweepAngle * progress);
      final isActive = (progress * 8000) <= rpm;

      Color color = Colors.cyan;
      if (progress > 0.7)
        color = Colors.yellow;
      else if (progress > 0.5)
        color = Colors.green;
      else if (progress > 0.3)
        color = Colors.teal;

      final paint = Paint()
        ..color = isActive ? color : Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      if (isActive) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          angle,
          segmentSweep,
          false,
          paint,
        );
      }
    }

    // Scale numbers 0-8
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 8; i++) {
      final angle = startAngle + (sweepAngle * (i / 8));
      final pos =
          center +
          Offset(
            math.cos(angle) * (radius + 20),
            math.sin(angle) * (radius + 20),
          );

      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TachoPainter oldDelegate) =>
      oldDelegate.rpm != rpm;
}

class _PurpleMusicHub extends StatelessWidget {
  final MusicProvider music;
  const _PurpleMusicHub({required this.music});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              music.artistName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              music.trackTitle.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white70,
                size: 24,
              ),
              onPressed: music.previous,
            ),
            IconButton(
              icon: Icon(
                music.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
              onPressed: music.playPause,
            ),
            IconButton(
              icon: const Icon(
                Icons.skip_next,
                color: Colors.white70,
                size: 24,
              ),
              onPressed: music.next,
            ),
          ],
        ),
      ],
    );
  }
}

class _MileageText extends StatelessWidget {
  final String value;
  final String unit;
  final bool isSmall;
  const _MileageText({
    required this.value,
    required this.unit,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmall ? 22 : 32,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white38,
            fontSize: isSmall ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
