import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../providers/dash_settings_provider.dart';
import 'vehicle_top_view.dart';

/// Shows the vehicle silhouette with an optional registered photo.
class VehicleStage extends StatefulWidget {
  const VehicleStage({
    super.key,
    required this.vehicle,
    required this.modelPath,
    required this.reduceMotion,
    required this.onChangeVehicle,
  });
  final Vehicle? vehicle;
  final String modelPath;
  final bool reduceMotion;
  final VoidCallback onChangeVehicle;
  @override
  State<VehicleStage> createState() => _VehicleStageState();
}

class _VehicleStageState extends State<VehicleStage> {
  bool _photo = false;
  @override
  void didUpdateWidget(covariant VehicleStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle?.id != widget.vehicle?.id ||
        oldWidget.modelPath != widget.modelPath)
      _photo = false;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final hasVehicle = vehicle != null || widget.modelPath.isNotEmpty;
    final artwork = vehicle?.artworkPath;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF10283D), Color(0xFF040C13)],
              radius: .85,
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 45,
          right: 45,
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const RadialGradient(
                radius: .9,
                colors: [
                  Color(0xAA00BCEB),
                  Color(0x220077AA),
                  Colors.transparent,
                ],
                stops: [0, .65, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 30),
          child: hasVehicle && (!_photo || artwork == null)
              ? VehicleTopView(
                  colorHex: context.select(
                    (DashSettingsProvider? settings) =>
                        settings?.vehicleColorHex ??
                        vehicle?.paintColorHex ??
                        '#D5DDE9',
                  ),
                  vehicle: vehicle,
                  source: widget.modelPath,
                )
              : VehiclePhoto(
                  artwork: artwork,
                  demo: vehicle == null,
                  reduceMotion: widget.reduceMotion,
                ),
        ),
        if (vehicle != null)
          Positioned(
            top: 2,
            left: 12,
            right: 125,
            child: Text(
              '${vehicle.brand} ${vehicle.name}'.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9AB6C7),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: TextButton.icon(
            onPressed: widget.onChangeVehicle,
            icon: const Icon(Icons.swap_horiz_rounded, size: 17),
            label: const Text('MI VEHÍCULO', style: TextStyle(fontSize: 10)),
          ),
        ),
        if (hasVehicle && artwork != null)
          Positioned(
            bottom: 0,
            right: 4,
            child: TextButton.icon(
              onPressed: () => setState(() => _photo = !_photo),
              icon: Icon(
                _photo ? Icons.view_in_ar_rounded : Icons.photo_outlined,
                size: 15,
              ),
              label: Text(
                _photo ? 'VISTA SUPERIOR' : 'VER FOTO',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

/// A bounded perspective effect without a WebView, timer, or continuous animation.
class VehiclePhoto extends StatefulWidget {
  const VehiclePhoto({
    super.key,
    this.artwork,
    this.demo = false,
    this.reduceMotion = false,
  });
  final String? artwork;
  final bool demo, reduceMotion;
  @override
  State<VehiclePhoto> createState() => _VehiclePhotoState();
}

class _VehiclePhotoState extends State<VehiclePhoto> {
  Offset _tilt = const Offset(-.025, .025);
  @override
  Widget build(BuildContext context) {
    final lowResource = context.select<DashSettingsProvider?, bool>(
      (settings) => settings?.isLowResourceDevice ?? false,
    );
    final reduceMotion =
        widget.reduceMotion ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    return LayoutBuilder(
      builder: (context, constraints) {
        final limit = lowResource ? 520 : 960;
        final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
        final decodeWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth * pixelRatio)
                  .round()
                  .clamp(1, limit)
                  .toInt()
            : limit;
        return GestureDetector(
          onPanUpdate: reduceMotion
              ? null
              : (event) => setState(
                  () => _tilt = Offset(
                    (_tilt.dx +
                            event.delta.dx / math.max(1, constraints.maxWidth))
                        .clamp(-.08, .08),
                    (_tilt.dy +
                            event.delta.dy / math.max(1, constraints.maxHeight))
                        .clamp(-.05, .05),
                  ),
                ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateX(reduceMotion ? 0.0 : -_tilt.dy)
              ..rotateY(reduceMotion ? 0.0 : _tilt.dx),
            child: widget.artwork != null
                ? Image.file(
                    File(widget.artwork!),
                    fit: BoxFit.contain,
                    cacheWidth: decodeWidth,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : widget.demo
                ? Image.asset(
                    'assets/images/png/night_drive_car.png',
                    fit: BoxFit.contain,
                    cacheWidth: decodeWidth,
                    filterQuality: FilterQuality.low,
                  )
                : _placeholder(),
          ),
        );
      },
    );
  }

  Widget _placeholder() => const Center(
    child: Icon(
      Icons.directions_car_filled_rounded,
      color: Color(0xFF4A7D99),
      size: 100,
    ),
  );
}
