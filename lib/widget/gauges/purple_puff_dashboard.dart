import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';

class PurplePuffDashboard extends StatefulWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final String tempUnit;

  const PurplePuffDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.tempUnit = '°C',
  });

  @override
  State<PurplePuffDashboard> createState() => _PurplePuffDashboardState();
}

class _PurplePuffDashboardState extends State<PurplePuffDashboard> {
  MapLibreMapController? mapController;
  Position? _currentPosition;
  NowPlayingTrack? _currentTrack;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initMusic();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      _currentPosition = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() {});

      if (mapController != null && _currentPosition != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _initMusic() async {
    try {
      await NowPlaying.instance.start(
        resolveImages: true,
      );

      NowPlaying.instance.stream.listen(
        (track) {
          if (!mounted) return;

          setState(() {
            _currentTrack = track;
          });
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;

    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF07050F),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: _GlassCard(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CustomPaint(
                              painter: _PurpleRpmPainter(
                                rpm: widget.rpm,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${widget.speed}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Inter',
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const Text(
                                'KM/H',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: _GlassCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['P', 'R', 'N', 'D'].map((g) {
                          final isActive =
                              (widget.speed == 0 && g == 'P') ||
                              (widget.speed > 0 && g == 'D');

                          return _GearLetter(
                            letter: g,
                            isActive: isActive,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 2,
                    child: _GlassCard(
                      child: _MusicPlayerInfo(
                        track: _currentTrack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    MapLibreMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition != null
                            ? LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              )
                            : const LatLng(
                                18.4861,
                                -69.9312,
                              ),
                        zoom: 15,
                        tilt: 60,
                      ),
                      styleString:
                          'https://tiles.openfreemap.org/styles/liberty',
                      myLocationEnabled: true,
                      trackCameraPosition: true,
                    ),
                    Positioned(
                      top: 15,
                      left: 15,
                      right: 15,
                      child: Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white10,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Buscar destino...',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.mic_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00E5FF)
                                .withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                              color: Color(0xFF00E5FF),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'GPS ACTIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: child,
    );
  }
}

class _GearLetter extends StatelessWidget {
  final String letter;
  final bool isActive;

  const _GearLetter({
    required this.letter,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00E5FF);

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? activeColor
            : Colors.white.withOpacity(0.03),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: isActive ? Colors.black : Colors.white24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
      ),
    );
  }
}

class _MusicPlayerInfo extends StatelessWidget {
  final NowPlayingTrack? track;

  const _MusicPlayerInfo({
    this.track,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white10,
              image: track?.hasImage == true
                  ? DecorationImage(
                      image: track!.image!,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: track?.hasImage != true
                ? const Icon(
                    Icons.music_note,
                    color: Colors.white24,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.title?.trim().isNotEmpty == true
                      ? track!.title!.trim()
                      : 'Silencio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  track?.artist?.trim().isNotEmpty == true
                      ? track!.artist!.trim()
                      : 'DashCore Audio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _PurpleRpmPainter extends CustomPainter {
  final int rpm;

  _PurpleRpmPainter({
    required this.rpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 5;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    final progress = (rpm / 8000).clamp(0.0, 1.0);

    final arcPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return true;
  }
}