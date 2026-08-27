import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => _currentPos = pos);

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((p) {
      if (mounted) {
        setState(() => _currentPos = p);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(p.latitude, p.longitude)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    const darkPurple = Color(0xFF0D0216);

    return Container(
      color: darkPurple,
      child: Stack(
        children: [
          // 1. MAPA GRANDE (IZQUIERDA / CENTRAL)
          Positioned(
            top: 20,
            left: 20,
            right: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 30)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: MapLibreMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPos?.latitude ?? 0, _currentPos?.longitude ?? 0),
                    zoom: 16, // Slightly closer
                    tilt: 60, // Higher tilt for 3D look
                  ),
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: true,
                  styleString: 'https://demotiles.maplibre.org/style.json',
                ),
              ),
            ),
          ),

          // 2. TACÓMETRO CIRCULAR (DERECHA SUPERIOR)
          Positioned(
            top: 20,
            right: 20,
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.height * 0.5,
            child: _PurpleTachometer(rpm: widget.rpm),
          ),

          // 3. VELOCIDAD (DEBAJO DEL TACÓMETRO)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.55,
            right: MediaQuery.of(context).size.width * 0.08,
            child: Column(
              children: [
                Text(
                  '${widget.speed}',
                  style: const TextStyle(color: Colors.white, fontSize: 86, fontWeight: FontWeight.w900, height: 1),
                ),
                const Text(
                  'km/h',
                  style: TextStyle(color: Colors.white38, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],
            ),
          ),

          // 4. REPRODUCTOR DE MÚSICA (DEBAJO DEL MAPA)
          Positioned(
            bottom: 30,
            left: 40,
            width: MediaQuery.of(context).size.width * 0.5,
            child: _PurpleMusicHub(music: music),
          ),

          // 5. KILOMETRAJE REMOVED AS PER USER REQUEST
        ],
      ),
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
        child: Text(
          '${(rpm / 1000).toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900),
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

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    final segments = 40;
    final segmentGap = 0.02 * math.pi;
    final segmentSweep = (sweepAngle / segments) - segmentGap;

    for (int i = 0; i < segments; i++) {
      final progress = i / segments;
      final angle = startAngle + (sweepAngle * progress);
      final isActive = (progress * 8000) <= rpm;

      Color color = Colors.cyan;
      if (progress > 0.7) color = Colors.yellow;
      else if (progress > 0.5) color = Colors.green;
      else if (progress > 0.3) color = Colors.teal;

      final paint = Paint()
        ..color = isActive ? color : Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      
      if (isActive) {
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle, segmentSweep, false, paint);
      }
    }

    // Scale numbers 0-8
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 8; i++) {
      final angle = startAngle + (sweepAngle * (i / 8));
      final pos = center + Offset(math.cos(angle) * (radius + 20), math.sin(angle) * (radius + 20));
      
      textPainter.text = TextSpan(text: '$i', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TachoPainter oldDelegate) => oldDelegate.rpm != rpm;
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
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            Text(
              music.trackTitle.toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 24), onPressed: music.previous),
            IconButton(
              icon: Icon(music.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
              onPressed: music.playPause
            ),
            IconButton(icon: const Icon(Icons.skip_next, color: Colors.white70, size: 24), onPressed: music.next),
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
  const _MileageText({required this.value, required this.unit, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: isSmall ? 22 : 32, fontWeight: FontWeight.w900, height: 1),
        ),
        const SizedBox(width: 5),
        Text(
          unit,
          style: TextStyle(color: Colors.white38, fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
