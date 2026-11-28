import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle_model.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/vehicle_presentation.dart';
import 'realistic_vehicle_body.dart';

class VehicleTopView extends StatefulWidget {
  const VehicleTopView({
    super.key,
    required this.colorHex,
    this.vehicle,
    this.source = '',
    this.hoodOpen = false,
  });
  final String colorHex;
  final Vehicle? vehicle;
  final String source;
  final bool hoodOpen;

  @override
  State<VehicleTopView> createState() => _VehicleTopViewState();
}

class _VehicleTopViewState extends State<VehicleTopView>
    with WidgetsBindingObserver {
  Timer? _transition;
  bool _night = false;
  bool _foreground = true;
  int _on = 19 * 60, _off = 7 * 60;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<DashSettingsProvider?>();
    _on = settings?.vehicleLightsOn ?? 19 * 60;
    _off = settings?.vehicleLightsOff ?? 7 * 60;
    _updateNight();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateNight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateNight();
  }

  void _updateNight() {
    _transition?.cancel();
    if (!_foreground) return;
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    final night = _on < _off
        ? minute >= _on && minute < _off
        : minute >= _on || minute < _off;
    DateTime boundary(int minutes) {
      var date = DateTime(
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!date.isAfter(now))
        date = DateTime(
          now.year,
          now.month,
          now.day + 1,
          minutes ~/ 60,
          minutes % 60,
        );
      return date;
    }

    final on = boundary(_on), off = boundary(_off);
    final next = on.isBefore(off) ? on : off;
    if (_night != night) setState(() => _night = night);
    _transition = Timer(next.difference(now), _updateNight);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transition?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = int.tryParse(
      widget.colorHex.replaceFirst('#', ''),
      radix: 16,
    );
    final color = value == null
        ? const Color(0xFFC2C8D3)
        : Color(0xFF000000 | value);
    final vehicle = widget.vehicle;
    final shape = vehicleShape(vehicle, widget.source);
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.of(context) ||
        context.select<DashSettingsProvider?, bool>(
          (settings) => settings?.reduceMotion ?? false,
        );

    return Semantics(
      image: true,
      label: [
        if (vehicle != null) vehicle.name,
        'Vista superior',
        if (_night) 'Luces nocturnas',
      ].join(' · '),
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _night ? 1 : 0),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          child: const SizedBox.expand(),
          builder: (context, lighting, child) => RealisticVehicleBody(
            color: color,
            shape: shape,
            lighting: lighting,
            hoodOpen: widget.hoodOpen,
            lowResource: context.select<DashSettingsProvider?, bool>(
              (settings) => settings?.isLowResourceDevice ?? false,
            ),
          ),
        ),
      ),
    );
  }
}
