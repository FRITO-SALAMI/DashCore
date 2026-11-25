import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/obd_provider.dart';
import '../display_units.dart';
import 'local_position_view.dart';

/// Purple's live location design is entirely local. No tiles, geocoder,
/// routing server, coordinate uploads, or stored route history.
class PurpleMapsDashboard extends StatefulWidget {
  const PurpleMapsDashboard({super.key, required this.speed, required this.rpm,
    required this.coolantTemp, required this.voltage});
  final int speed, rpm, coolantTemp;
  final double voltage;
  @override
  State<PurpleMapsDashboard> createState() => _PurpleMapsDashboardState();
}
class _PurpleMapsDashboardState extends State<PurpleMapsDashboard> {
  final _trail = LocalTrail();
  StreamSubscription<Position>? _subscription;
  late final ObdProvider _obd;
  bool _northUp = true;
  @override
  void initState() {
    super.initState();
    _obd = context.read<ObdProvider>();
    final last = _obd.lastGpsPosition;
    if (last != null) _trail.add(last);
    _subscription = _obd.gpsPositions.listen((p) {
      if (mounted) setState(() => _trail.add(p));
    });
    unawaited(_obd.acquireVisualLocation());
  }
  @override
  void dispose() {
    _subscription?.cancel();
    _obd.releaseVisualLocation();
    _trail.clear();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final positions = _trail.positions;
    final current = positions.lastOrNull;
    const accent = Color(0xFFB8A5FF);
    return ColoredBox(color: const Color(0xFF080D17), child: LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      return Row(children: [
        SizedBox(width: compact ? 140 : 200, child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 22),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('PURPLE DRIVE', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            FittedBox(child: Text('${widget.speed}', style: const TextStyle(color: Colors.white, fontSize: 76, fontWeight: FontWeight.w800, height: 1))),
            const SpeedUnitLabel(style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 24),
            const Icon(Icons.phonelink_lock_rounded, color: accent, size: 22),
            const SizedBox(height: 8),
            const Text('GPS LOCAL', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
          ]),
        )),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(fit: StackFit.expand, children: [
          LocalPositionView(trail: positions, northUp: _northUp),
          Positioned(top: 12, left: 16, right: 12, child: Row(children: [
            const Expanded(child: Text('RECORRIDO EN TIEMPO REAL', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))),
            IconButton.filledTonal(tooltip: _northUp ? 'Orientar con el vehículo' : 'Norte arriba', onPressed: () => setState(() => _northUp = !_northUp), icon: Icon(_northUp ? Icons.explore_rounded : Icons.navigation_rounded, size: 20)),
          ])),
          if (current == null) Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.gps_not_fixed_rounded, color: accent, size: 30),
            const SizedBox(height: 8),
            const Text('Esperando señal GPS', style: TextStyle(color: Colors.white70)),
            TextButton(onPressed: () { _obd.releaseVisualLocation(); unawaited(_obd.acquireVisualLocation()); }, child: const Text('ACTIVAR UBICACIÓN')),
          ]))),
          Positioned(left: 16, right: 16, bottom: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (current != null) Text('${current.latitude.toStringAsFixed(5)}  ·  ${current.longitude.toStringAsFixed(5)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            Text(current == null ? '100 m / cuadrícula' : '100 m / cuadrícula  ·  ±${current.accuracy.round()} m', style: const TextStyle(color: Color(0xFF7F8FA8), fontSize: 10)),
          ])),
        ]))),
      ]);
    }));
  }
}
