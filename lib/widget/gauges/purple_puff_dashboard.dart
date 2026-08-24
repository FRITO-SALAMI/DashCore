import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../dashboard_background.dart';

class PurplePuffDashboard extends StatefulWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;
  final String tempUnit;
  final Color accentColor;
  final String? backgroundImage;
  final bool isAssetBackground;

  const PurplePuffDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
    this.tempUnit = '°C',
    this.accentColor = const Color(0xFF00E5FF),
    this.backgroundImage,
    this.isAssetBackground = true,
  });

  @override
  State<PurplePuffDashboard> createState() => _PurplePuffDashboardState();
}

class _PurplePuffDashboardState extends State<PurplePuffDashboard> {
  GoogleMapController? mapController;
  Position? _currentPosition;
  String? _destination;
  LatLng? _destinationCoords;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = position);
      _updateCamera();
    });
    
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _updateCamera() {
    if (mapController != null && _currentPosition != null && _destinationCoords == null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ));
    }
  }

  void _onSearch(String query) async {
    setState(() {
      _destination = query;
      if (_currentPosition != null) {
        _destinationCoords = LatLng(
          _currentPosition!.latitude + 0.01, 
          _currentPosition!.longitude + 0.01
        );
      }
    });
    _updateRoute();
  }

  void _updateRoute() {
    if (mapController != null && _destinationCoords != null && _currentPosition != null) {
       setState(() {
         _polylines.clear();
         _polylines.add(Polyline(
           polylineId: const PolylineId('route'),
           points: [
             LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
             _destinationCoords!,
           ],
           color: const Color(0xFF00E5FF),
           width: 6,
         ));
       });
       
       mapController!.animateCamera(CameraUpdate.newLatLngBounds(
         LatLngBounds(
           southwest: LatLng(
             math.min(_currentPosition!.latitude, _destinationCoords!.latitude),
             math.min(_currentPosition!.longitude, _destinationCoords!.longitude),
           ),
           northeast: LatLng(
             math.max(_currentPosition!.latitude, _destinationCoords!.latitude),
             math.max(_currentPosition!.longitude, _destinationCoords!.longitude),
           ),
         ),
         100,
       ));
    }
  }

  @override
  void dispose() {
    mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MusicProvider>();

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF07050F)),
      child: Stack(
        children: [
          DashboardBackground(
            backgroundImage: widget.backgroundImage,
            isAssetBackground: widget.isAssetBackground,
            opacity: 0.1,
          ),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _GlassCard(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 280, height: 280,
                                    child: CustomPaint(
                                      painter: _PurpleRpmPainter(rpm: widget.rpm, accentColor: widget.accentColor),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${widget.speed}',
                                        style: const TextStyle(color: Colors.white, fontSize: 110, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                                      ),
                                      Text('KM/H', style: TextStyle(color: widget.accentColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4)),
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
                                  final isActive = (widget.speed == 0 && g == 'P') || (widget.speed > 0 && g == 'D');
                                  return _GearLetter(letter: g, isActive: isActive, accentColor: widget.accentColor);
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: constraints.maxHeight * 0.22,
                            child: _GlassCard(
                              child: _MusicPlayerInfo(accentColor: widget.accentColor),
                            ),
                          ),
                        ],
                      );
                    }
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
                        GoogleMap(
                          onMapCreated: (c) => mapController = c,
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(18.4861, -69.9312),
                            zoom: 15,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          polylines: _polylines,
                          style: _googleMapStyle,
                        ),
                        
                        Positioned(
                          top: 15, left: 15, right: 15,
                          child: _MapSearchBar(onSearch: _onSearch, destination: _destination),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const String _googleMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#484848"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    }
  ]
  ''';
}

class _MapSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final String? destination;
  const _MapSearchBar({required this.onSearch, this.destination});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: destination);
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Color(0xFF00E5FF), size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '¿A DÓNDE VAMOS HOY?',
                hintStyle: TextStyle(color: Colors.white24, letterSpacing: 1),
                border: InputBorder.none,
              ),
              onSubmitted: onSearch,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF00E5FF)),
            onPressed: () => onSearch(controller.text),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _GearLetter extends StatelessWidget {
  final String letter;
  final bool isActive;
  final Color accentColor;
  const _GearLetter({required this.letter, required this.isActive, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isActive ? accentColor : Colors.white.withOpacity(0.02),
        boxShadow: isActive ? [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 10)] : null,
      ),
      child: Text(
        letter,
        style: TextStyle(color: isActive ? Colors.black : Colors.white24, fontWeight: FontWeight.w900, fontSize: 20),
      ),
    );
  }
}

class _MusicPlayerInfo extends StatelessWidget {
  final Color accentColor;
  const _MusicPlayerInfo({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final track = music.currentTrack;
    final bool hasTrack = track != null && track.title != null && track.title!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black26,
              image: hasTrack && track.hasImage ? DecorationImage(image: track.image!, fit: BoxFit.cover) : null,
              border: Border.all(color: Colors.white10),
            ),
            child: (!hasTrack || !track.hasImage) ? Icon(Icons.music_note_rounded, color: accentColor.withOpacity(0.5)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  music.trackTitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                ),
                Text(
                  music.artistName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: music.playPause,
                icon: Icon(music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: accentColor, size: 28),
              ),
              IconButton(
                onPressed: music.next,
                icon: Icon(Icons.skip_next_rounded, color: accentColor, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurpleRpmPainter extends CustomPainter {
  final int rpm;
  final Color accentColor;
  _PurpleRpmPainter({required this.rpm, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    
    final trackPaint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.8, math.pi * 1.4, false, trackPaint);
    
    final progress = (rpm / 8000).clamp(0.0, 1.0);
    final arcPaint = Paint()
      ..shader = LinearGradient(colors: [accentColor.withOpacity(0.5), accentColor]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 10;
      
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.8, math.pi * 1.4 * progress, false, arcPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
