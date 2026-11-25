import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import '../widget/compatible_vehicle_model.dart';
import 'vehicle_resource_download_screen.dart';
import 'manual_vehicle_screen.dart';

class CarScreen extends StatefulWidget {
  final VoidCallback onBack;
  const CarScreen({super.key, required this.onBack});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final vehicles = settings.availableVehicles;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _GarageHeader(onBack: widget.onBack)),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualVehicleScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('MI VEHÍCULO'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: settings.vehiclesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vehicles.isEmpty
                  ? const Center(child: _EmptyGarageCard())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.2,
                          ),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        final isSelected =
                            settings.selectedVehicle?.id == vehicle.id;
                        final bool needsDownload = !vehicle.isDownloaded;
                        final artworkPath = vehicle.artworkPath;
                        final thumbnail = catalogVehiclePreview(
                          vehicle.modelUrl ?? '',
                        );
                        final ImageProvider? artwork = artworkPath != null
                            ? FileImage(File(artworkPath))
                            : thumbnail != null
                            ? AssetImage(thumbnail)
                            : null;

                        return GestureDetector(
                          onTap: () async {
                            if (vehicle.isDownloaded) {
                              settings.selectVehicle(vehicle);
                              return;
                            }
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => VehicleResourceDownloadScreen(
                                  vehicle: vehicle,
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration:
                                settings.reduceMotion ||
                                    MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00E5FF)
                                    : Colors.white10,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                needsDownload
                                                    ? Icons
                                                          .cloud_download_rounded
                                                    : Icons
                                                          .directions_car_filled_rounded,
                                                color: isSelected
                                                    ? const Color(0xFF00E5FF)
                                                    : (needsDownload
                                                          ? Colors.orangeAccent
                                                          : Colors.white38),
                                                size: 32,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                vehicle.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                needsDownload
                                                    ? 'REQUERIDO'
                                                    : vehicle.brand,
                                                style: TextStyle(
                                                  color: needsDownload
                                                      ? Colors.orangeAccent
                                                            .withOpacity(0.6)
                                                      : Colors.white38,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (artwork != null) ...[
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: Image(
                                              image: ResizeImage(
                                                artwork,
                                                width: 360,
                                                height: 200,
                                                policy: ResizeImagePolicy.fit,
                                              ),
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.low,
                                              excludeFromSemantics: true,
                                              errorBuilder: (_, _, _) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00E5FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GarageHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _GarageHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Text(
            "Garage",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGarageCard extends StatelessWidget {
  const _EmptyGarageCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),

      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(
            width: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => {}, //todo
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No Cars",
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Add your first\nvehicle",
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 250,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      "Add Car",
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
