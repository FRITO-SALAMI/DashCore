import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../models/obd_data.dart';

class TeslaStyleThemeScreen extends StatelessWidget {
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
    this.trackTitle,
    this.artistName,
    this.isPlaying = false,
    this.progress = 0,
    this.onPlayPause,
    this.onPrev,
    this.onNext,
    this.fuelLevel = 0,
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

  final String? trackTitle;
  final String? artistName;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  static const _bg = Color(0xFF0A0B0D);
  static const _panel = Color(0xFF121417);
  static const _line = Color(0xFF23262B);
  static const _white = Color(0xFFF1F3F5);
  static const _muted = Color(0xFF6E7680);
  static const _green = Color(0xFF3DDC84);

  @override
  Widget build(BuildContext context) {
    final bool isCompetitive = data.rpm > 5000;
    final double scale = isCompetitive ? 1.05 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isCompetitive ? Colors.red.withOpacity(0.05) : _bg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: SafeArea(
        child: Column(
          children: [
            _StatusBar(
              ambientTempC: ambientTempC,
              coolantTempC: data.engineTemp.toDouble(),
              batteryVoltage: data.voltage,
              accentColor: accentColor,
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
                        speedKmh: data.speed.toDouble(),
                        rpm: data.rpm,
                        maxSpeedKmh: maxSpeedKmh,
                        coolantTempC: data.engineTemp.toDouble(),
                        batteryVoltage: data.voltage,
                        accentColor: accentColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _VehiclePanel(
                      modelPath: modelPath,
                      gear: data.gear,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: _AppsHub(
                            slotCount: appSlotCount,
                            onAppTap: onAppTap,
                            slotBuilder: appSlotBuilder,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 140, // Increased slightly for better fit
                          child: _MusicHub(
                            trackTitle: trackTitle,
                            artistName: artistName,
                            isPlaying: isPlaying,
                            progress: progress,
                            onPlayPause: onPlayPause,
                            onPrev: onPrev,
                            onNext: onNext,
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
              style: const TextStyle(color: TeslaStyleThemeScreen._white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('·', style: TextStyle(color: TeslaStyleThemeScreen._muted, fontSize: 18)),
            ),
          ],
          const Icon(Icons.wifi, size: 16, color: TeslaStyleThemeScreen._muted),
          const SizedBox(width: 15),
          const Icon(Icons.bluetooth, size: 16, color: TeslaStyleThemeScreen._muted),
          const SizedBox(width: 15),
          Text(
            TimeOfDay.now().format(context),
            style: const TextStyle(color: TeslaStyleThemeScreen._white, fontSize: 16, fontWeight: FontWeight.w900),
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
                color: isCompetitive ? Colors.redAccent : TeslaStyleThemeScreen._white,
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
            child: Text(
              'KM/H',
              style: TextStyle(color: TeslaStyleThemeScreen._muted, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ENGINE SPEED · RPM',
            style: TextStyle(color: isCompetitive ? Colors.redAccent : TeslaStyleThemeScreen._muted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              width: 240,
              child: Stack(
                children: [
                  Container(color: TeslaStyleThemeScreen._line),
                  FractionallySizedBox(
                    widthFactor: rpmFraction,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      color: isCompetitive ? Colors.red : accentColor,
                      child: isCompetitive ? _CompetitiveFlicker() : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _StatusItem(
                label: 'COOLANT',
                value: '${coolantTempC.round()}°C',
                icon: Icons.thermostat,
                color: coolantTempC > 100 ? Colors.redAccent : accentColor,
              ),
              const SizedBox(width: 30),
              _StatusItem(
                label: 'VOLTAGE',
                value: '${batteryVoltage.toStringAsFixed(1)}V',
                icon: Icons.bolt,
                color: (batteryVoltage < 11.5 || batteryVoltage > 15.0) ? Colors.redAccent : accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: TeslaStyleThemeScreen._muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: TeslaStyleThemeScreen._white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _CompetitiveFlicker extends StatefulWidget {
  const _CompetitiveFlicker();
  @override
  State<_CompetitiveFlicker> createState() => _CompetitiveFlickerState();
}

class _CompetitiveFlickerState extends State<_CompetitiveFlicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.7, end: 1.0)),
      child: Container(color: Colors.redAccent),
    );
  }
}

class _VehiclePanel extends StatelessWidget {
  const _VehiclePanel({
    required this.modelPath,
    required this.gear,
  });

  final String modelPath;
  final String? gear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeslaStyleThemeScreen._panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeslaStyleThemeScreen._line),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey(modelPath),
              backgroundColor: Colors.transparent,
              src: modelPath,
              alt: "Vehicle 3D Model",
              autoRotate: true,
              cameraControls: false,
              disableZoom: true,
              disablePan: true,
              cameraOrbit: '180deg 75deg 5m',
              loading: Loading.eager,
              exposure: 1.0,
              shadowIntensity: 0.5,
            ),
          ),
          if (gear != null && gear!.isNotEmpty)
            Positioned(
              right: 14,
              bottom: 14,
              child: _GearIndicator(current: gear!),
            ),
        ],
      ),
    );
  }
}

class _GearIndicator extends StatelessWidget {
  const _GearIndicator({required this.current});
  final String current;

  static const _gears = ['P', 'R', 'N', 'D', '1', '2', '3', '4', '5', '6'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _gears.where((g) => ['P','R','N','D'].contains(g) || g == current).map((g) {
        final active = g.toUpperCase() == current.toUpperCase();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            g,
            style: TextStyle(
              color: active ? TeslaStyleThemeScreen._white : TeslaStyleThemeScreen._muted,
              fontSize: active ? 17 : 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AppsHub extends StatelessWidget {
  const _AppsHub({
    required this.slotCount,
    required this.onAppTap,
    required this.slotBuilder,
  });

  final int slotCount;
  final ValueChanged<int>? onAppTap;
  final Widget Function(BuildContext context, int index)? slotBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TeslaStyleThemeScreen._panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeslaStyleThemeScreen._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPS',
            style: TextStyle(
              color: TeslaStyleThemeScreen._muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slotCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: onAppTap == null ? null : () => onAppTap!(index),
                  child: slotBuilder != null
                      ? slotBuilder!(context, index)
                      : _EmptyAppSlot(index: index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAppSlot extends StatelessWidget {
  const _EmptyAppSlot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return DottedBorderBox(
      child: Center(
        child: Icon(Icons.apps, size: 20, color: TeslaStyleThemeScreen._muted.withOpacity(0.6)),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    final paint = Paint()
      ..color = TeslaStyleThemeScreen._line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final metric in metrics) {
      double distance = 0;
      const dashWidth = 4.0;
      const dashGap = 3.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MusicHub extends StatelessWidget {
  const _MusicHub({
    required this.trackTitle,
    required this.artistName,
    required this.isPlaying,
    required this.progress,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
  });

  final String? trackTitle;
  final String? artistName;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TeslaStyleThemeScreen._panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeslaStyleThemeScreen._line),
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
                decoration: BoxDecoration(
                  color: TeslaStyleThemeScreen._line,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, size: 18, color: TeslaStyleThemeScreen._muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trackTitle ?? 'Sin reproducción',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TeslaStyleThemeScreen._white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      artistName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: TeslaStyleThemeScreen._muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: TeslaStyleThemeScreen._line,
              valueColor: const AlwaysStoppedAnimation(TeslaStyleThemeScreen._green),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MusicButton(icon: Icons.skip_previous, onTap: onPrev),
              const SizedBox(width: 18),
              _MusicButton(
                icon: isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                onTap: onPlayPause,
                size: 30,
              ),
              const SizedBox(width: 18),
              _MusicButton(icon: Icons.skip_next, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

class _MusicButton extends StatelessWidget {
  const _MusicButton({required this.icon, required this.onTap, this.size = 22});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: TeslaStyleThemeScreen._white),
    );
  }
}
