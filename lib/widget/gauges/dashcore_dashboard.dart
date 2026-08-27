import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../../models/gadget_config.dart';
import '../../widgets/editable_gadget_wrapper.dart';
import '../../painters/rpm_gauge_painter.dart';
import '../../painters/speed_ring_gauge_painter.dart';
import '../../providers/dash_settings_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/rpm_warning_animation.dart';
import '../dashboard_background.dart';

class DashcoreDashboard extends StatefulWidget {
  final int speed;
  final int rpm;
  final int coolantTemp;
  final double voltage;

  const DashcoreDashboard({
    super.key,
    required this.speed,
    required this.rpm,
    required this.coolantTemp,
    required this.voltage,
  });

  @override
  State<DashcoreDashboard> createState() => _DashcoreDashboardState();
}

class _DashcoreDashboardState extends State<DashcoreDashboard> {
  late final Map<String, GadgetConfig> gadgets = {
    'rpm_gauge': GadgetConfig(
      id: 'rpm_gauge',
      label: 'RPM GAUGE',
      relativeX: 0.02,
      relativeY: 0.05,
      relativeWidth: 0.32,
      relativeHeight: 0.55,
    ),
    'speed_ring_gauge': GadgetConfig(
      id: 'speed_ring_gauge',
      label: 'SPEED RING',
      relativeX: 0.34,
      relativeY: 0.05,
      relativeWidth: 0.32,
      relativeHeight: 0.55,
    ),
    'vehicle_model': GadgetConfig(
      id: 'vehicle_model',
      label: 'VEHICLE',
      relativeX: 0.66,
      relativeY: 0.05,
      relativeWidth: 0.32,
      relativeHeight: 0.55,
    ),
    'media_player_bar': GadgetConfig(
      id: 'media_player_bar',
      label: 'MEDIA HUB',
      relativeX: 0.02,
      relativeY: 0.65,
      relativeWidth: 0.6,
      relativeHeight: 0.22,
    ),
    'volt_temp_hub': GadgetConfig(
      id: 'volt_temp_hub',
      label: 'VOLT & TEMP',
      relativeX: 0.64,
      relativeY: 0.65,
      relativeWidth: 0.34,
      relativeHeight: 0.22,
    ),
    'sensors_bar': GadgetConfig(
      id: 'sensors_bar',
      label: 'SENSORS BAR',
      relativeX: 0.02,
      relativeY: 0.9,
      relativeWidth: 0.96,
      relativeHeight: 0.08,
    ),
  };

  void _updateGadget(GadgetConfig updated) {
    setState(() => gadgets[updated.id] = updated);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final music = context.watch<MusicProvider>();
    final accentColor = settings.accentColor;

    return Container(
      color: const Color(0xFF020408),
      child: Stack(
        children: [
          DashboardBackground(
            backgroundImage: settings.backgroundImage,
            isAssetBackground: settings.isAssetBackground,
            opacity: 0.3,
          ),

          _buildTopBar(accentColor),

          Positioned.fill(
            top: 50,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: gadgets.values.map((config) {
                    return Positioned(
                      left: config.relativeX * constraints.maxWidth,
                      top: config.relativeY * constraints.maxHeight,
                      width: config.relativeWidth * constraints.maxWidth,
                      height: config.relativeHeight * constraints.maxHeight,
                      child: EditableGadgetWrapper(
                        config: config,
                        isEditMode: settings.isEditMode,
                        onConfigChanged: _updateGadget,
                        onTapEdit: () => debugPrint('Edit ${config.label}'),
                        parentSize: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        child: _buildGadgetContent(
                          config.id,
                          accentColor,
                          music,
                          settings,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color accentColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        child: Center(
          child: Text(
            'DASHCORE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              shadows: [
                Shadow(color: accentColor.withOpacity(0.4), blurRadius: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGadgetContent(
    String id,
    Color color,
    MusicProvider music,
    DashSettingsProvider settings,
  ) {
    switch (id) {
      case 'rpm_gauge':
        return _panelBox(
          child: Stack(
            alignment: Alignment.center,
            children: [
              RpmWarningAnimation(
                rpm: widget.rpm,
                child: CustomPaint(
                  painter: RpmGaugePainter(
                    rpmValue: widget.rpm / 1000,
                    color: color,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                bottom: 30,
                child: Text(
                  '${(widget.rpm / 1000).toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                    letterSpacing: -2,
                  ),
                ),
              ),
              Positioned(
                bottom: 15,
                child: Text(
                  'RPM x1000',
                  style: TextStyle(
                    color: color.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'speed_ring_gauge':
        return _panelBox(child: _buildSpeedRingPanel(color));
      case 'volt_temp_hub':
        return _panelBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _largeSensorItem(Icons.bolt_rounded, Colors.orangeAccent, 'VOLT', '${widget.voltage.toStringAsFixed(1)}V'),
              VerticalDivider(color: Colors.white10, width: 1, indent: 15, endIndent: 15),
              _largeSensorItem(Icons.thermostat_rounded, Colors.cyanAccent, 'TEMP', '${widget.coolantTemp}°C'),
            ],
          ),
        );
      case 'vehicle_model':
        return _panelBox(
          child: ModelViewer(
            key: ValueKey(settings.modelPath),
            src: settings.modelPath,
            backgroundColor: Colors.transparent,
            autoRotate: false,
            cameraControls: false,
            disableZoom: true,
            disablePan: true,
            cameraOrbit: '45deg 75deg 3m',
            exposure: 1.0,
            shadowIntensity: 0.1,
            loading: Loading.lazy,
          ),
        );
      case 'media_player_bar':
        return _panelBox(child: _buildMediaHub(music, color), padding: 8);
      case 'sensors_bar':
        return _buildSensorsBar(color);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _panelBox({required Widget child, double padding = 10}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D14).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }

  Widget _buildSpeedRingPanel(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: SpeedRingGaugePainter(
            speedKmh: widget.speed.toDouble(),
            color: color,
          ),
          child: const SizedBox.expand(),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.speed}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 92,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -4,
              ),
            ),
            const Text(
              'KPH',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _largeSensorItem(IconData icon, Color color, String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaHub(MusicProvider music, Color color) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            color: Colors.white.withOpacity(0.05),
            child: music.currentTrack?.image != null
                ? Image(image: music.currentTrack!.image!, fit: BoxFit.cover)
                : const Icon(Icons.music_note, color: Colors.white24, size: 30),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                music.trackTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                music.artistName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 15),
              Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: music.progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.skip_previous_rounded,
                color: Colors.white70,
                size: 28,
              ),
              onPressed: music.previous,
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: music.playPause,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                ),
                child: Icon(
                  music.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(
                Icons.skip_next_rounded,
                color: Colors.white70,
                size: 28,
              ),
              onPressed: music.next,
            ),
          ],
        ),
        const SizedBox(width: 20),
        const Icon(
          Icons.favorite_border_rounded,
          color: Colors.white24,
          size: 20,
        ),
        const SizedBox(width: 15),
        const Icon(
          Icons.cast_connected_rounded,
          color: Colors.white24,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildSensorsBar(Color color) {
    final settings = context.read<DashSettingsProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _smallSensorItem(
                Icons.timer_outlined,
                Colors.white38,
                'TRIP',
                '12.4 km',
              ),
              const SizedBox(width: 30),
              if (settings.showFuelGauge)
                _fuelSensor(color),
            ],
          ),

          Row(
            children: [
              Icon(
                Icons.bluetooth_rounded,
                color: color.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.wifi_rounded,
                color: Colors.greenAccent.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 20),
              const Icon(Icons.more_horiz_rounded, color: Colors.white12, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallSensorItem(
    IconData icon,
    Color iconColor,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fuelSensor(Color color) {
    return Row(
      children: [
        Icon(
          Icons.local_gas_station_rounded,
          color: Colors.blueAccent,
          size: 32,
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FUEL',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Text(
                  '71%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 100,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.71,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
