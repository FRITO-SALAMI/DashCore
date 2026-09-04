import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../../models/obd_data.dart';
import '../../../providers/music_provider.dart';
import '../../../widget/dashboard_background.dart';
import '../../../widget/music_hub.dart';

class TeslaStyleThemeScreen extends StatefulWidget {
  const TeslaStyleThemeScreen({
    super.key,
    required this.data,
    required this.modelPath,
    this.ambientTempC,
    this.maxSpeedKmh = 260,
    this.accentColor = const Color(0xFF00E5FF),
    this.appSlotCount = 6,
    this.onAppTap,
    this.appSlotBuilder,
    this.fuelLevel = 0,
    this.backgroundImage,
    this.isAssetBackground = true,
  });

  final ObdData data;
  final String modelPath;
  final double? ambientTempC;
  final double maxSpeedKmh;
  final Color accentColor;
  final double fuelLevel;

  final int appSlotCount;
  final ValueChanged<int>? onAppTap;
  final Widget Function(BuildContext context, int index)? appSlotBuilder;

  final String? backgroundImage;
  final bool isAssetBackground;

  @override
  State<TeslaStyleThemeScreen> createState() => _TeslaStyleThemeScreenState();
}

class _TeslaStyleThemeScreenState extends State<TeslaStyleThemeScreen> {
  double _vehicleRotation = 180.0;

  @override
  Widget build(BuildContext context) {
    final bool isCompetitive = widget.data.rpm > 5000;
    final double scale = isCompetitive ? 1.05 : 1.0;
    const bg = Color(0xFF0A0B0D);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isCompetitive ? Colors.red.withOpacity(0.05) : bg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Stack(
        children: [
          DashboardBackground(
            backgroundImage: widget.backgroundImage,
            isAssetBackground: widget.isAssetBackground,
          ),
          SafeArea(
            child: Column(
              children: [
                _StatusBar(
                  ambientTempC: widget.ambientTempC,
                  coolantTempC: widget.data.engineTemp.toDouble(),
                  batteryVoltage: widget.data.voltage,
                  accentColor: widget.accentColor,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.centerLeft,
                          child: _SpeedPanel(
                            speedKmh: widget.data.speed.toDouble(),
                            rpm: widget.data.rpm,
                            maxSpeedKmh: widget.maxSpeedKmh,
                            coolantTempC: widget.data.engineTemp.toDouble(),
                            batteryVoltage: widget.data.voltage,
                            accentColor: widget.accentColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: _VehiclePanel(
                          modelPath: widget.modelPath,
                          gear: widget.data.gear,
                          rotation: _vehicleRotation,
                          onRotationChange: (val) => setState(() => _vehicleRotation = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: _AppsHub(
                                slotCount: widget.appSlotCount,
                                onAppTap: widget.onAppTap,
                                slotBuilder: widget.appSlotBuilder,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 70,
                              child: MusicHub(
                                accentColor: widget.accentColor,
                                width: 260,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.ambientTempC,
    required this.coolantTempC,
    required this.batteryVoltage,
    required this.accentColor,
  });

  final double? ambientTempC;
  final double coolantTempC;
  final double batteryVoltage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.end,
        children: [
          if (ambientTempC != null) ...[
             Text(
              '${ambientTempC!.toStringAsFixed(0)}°C',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('·', style: TextStyle(color: Colors.white30, fontSize: 18)),
            ),
          ],
          const Icon(Icons.wifi, size: 16, color: Colors.white30),
          const SizedBox(width: 15),
          const Icon(Icons.bluetooth, size: 16, color: Colors.white30),
          const SizedBox(width: 15),
          Text(
            TimeOfDay.now().format(context),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SpeedPanel extends StatelessWidget {
  const _SpeedPanel({
    required this.speedKmh,
    required this.rpm,
    required this.maxSpeedKmh,
    required this.coolantTempC,
    required this.batteryVoltage,
    required this.accentColor,
  });

  final double speedKmh;
  final int rpm;
  final double maxSpeedKmh;
  final double coolantTempC;
  final double batteryVoltage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final rpmFraction = (rpm / 8000).clamp(0.0, 1.0);
    final isCompetitive = rpm > 5000;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isCompetitive ? 1.1 : 1.0,
            child: Text(
              speedKmh.round().toString(),
              style: TextStyle(
                color: isCompetitive ? Colors.redAccent : Colors.white,
                fontSize: 140,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -2,
                shadows: isCompetitive ? [const Shadow(color: Colors.red, blurRadius: 30)] : null,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 0),
            child: Text('KM/H', style: TextStyle(color: Colors.white30, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4)),
          ),
          const SizedBox(height: 20),
          Text('ENGINE SPEED · RPM', style: TextStyle(color: isCompetitive ? Colors.redAccent : Colors.white30, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12, width: 240,
              child: Stack(
                children: [
                  Container(color: Colors.white10),
                  FractionallySizedBox(
                    widthFactor: rpmFraction,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      color: isCompetitive ? Colors.red : accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _SItem(label: 'COOLANT', value: '${coolantTempC.round()}°C', icon: Icons.thermostat, color: coolantTempC > 100 ? Colors.redAccent : accentColor),
              const SizedBox(width: 30),
              _SItem(label: 'VOLTAGE', value: '${batteryVoltage.toStringAsFixed(1)}V', icon: Icons.bolt, color: (batteryVoltage < 11.5 || batteryVoltage > 15.0) ? Colors.redAccent : accentColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _SItem extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _SItem({required this.label, required this.value, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1))]), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))]);
}

class _VehiclePanel extends StatelessWidget {
  const _VehiclePanel({
    required this.modelPath,
    required this.gear,
    required this.rotation,
    required this.onRotationChange,
  });

  final String modelPath;
  final String? gear;
  final double rotation;
  final Function(double) onRotationChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121417),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF23262B)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey('${modelPath}_$rotation'),
              backgroundColor: Colors.transparent,
              src: modelPath,
              alt: "Vehicle 3D Model",
              autoRotate: false,
              cameraControls: false,
              disableZoom: true,
              disablePan: true,
              cameraOrbit: '${rotation}deg 60deg 5m',
              loading: Loading.eager,
              exposure: 1.0,
              shadowIntensity: 0.1,
            ),
          ),

          // Rotation Slider Layer
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Column(
              children: [
                const Text('GYRO VEHICLE', style: TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.bold)),
                Slider(
                  value: rotation, min: 0, max: 360,
                  activeColor: const Color(0xFF00E5FF).withOpacity(0.3),
                  inactiveColor: Colors.white10,
                  onChanged: onRotationChange,
                ),
              ],
            ),
          ),

          if (gear != null && gear!.isNotEmpty)
            Positioned(right: 14, top: 14, child: Text(gear!, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _AppsHub extends StatelessWidget {
  final int slotCount; final ValueChanged<int>? onAppTap; final Widget Function(BuildContext context, int index)? slotBuilder;
  const _AppsHub({required this.slotCount, required this.onAppTap, required this.slotBuilder});
  @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF121417), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF23262B))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('APPS', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)), const SizedBox(height: 10), Expanded(child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: slotCount, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10), itemBuilder: (context, index) => GestureDetector(onTap: onAppTap == null ? null : () => onAppTap!(index), child: slotBuilder != null ? slotBuilder!(context, index) : Center(child: Icon(Icons.apps, size: 20, color: Colors.white10)))))]));
}

class _MusicHub extends StatelessWidget {
  const _MusicHub();
  @override Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121417),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF23262B))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFF23262B), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.music_note, size: 18, color: Colors.white30)
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(music.trackTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(music.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white30, fontSize: 11))
                  ]
                )
              )
            ]
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: music.progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: const Color(0xFF23262B),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF3DDC84))
            )
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: music.previous),
              const SizedBox(width: 18),
              IconButton(icon: Icon(music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 30, color: Colors.white), onPressed: music.playPause),
              const SizedBox(width: 18),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: music.next)
            ]
          )
        ]
      )
    );
  }
}
