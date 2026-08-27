
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../models/obd_data.dart';

class ClassicSportThemeScreen extends StatefulWidget {
  const ClassicSportThemeScreen({
    super.key,
    required this.data,
    required this.modelPath,
    this.ambientTempC,
    this.nowPlaying,
    this.maxSpeedKmh = 320,
    this.maxRpm = 8000,
    this.redlineRpm = 6000,
    this.accentColor = const Color(0xFF29C8F2),
    this.onModeChanged,
    this.fuelLevel = 0,
  });

  final ObdData data;
  final String modelPath;
  final double? ambientTempC;
  final String? nowPlaying;
  final double fuelLevel;

  final double maxSpeedKmh;
  final double maxRpm;
  final double redlineRpm;
  final Color accentColor;

  final ValueChanged<String>? onModeChanged;

  @override
  State<ClassicSportThemeScreen> createState() =>
      _ClassicSportThemeScreenState();
}

class _ClassicSportThemeScreenState extends State<ClassicSportThemeScreen> {
  static const _modes = ['CLASSIC', 'SPORT', 'COMFORT'];
  int _selected = 1;

  static const _bg = Color(0xFF020304);
  static const _amber = Color(0xFFE7C15A);
  static const _red = Color(0xFFE8283F);

  Color get _currentAccent {
    switch (_selected) {
      case 0: return _amber;
      case 1: return _red;
      case 2: return widget.accentColor;
      default: return widget.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompetitive = widget.data.rpm > 5000;
    final scale = isCompetitive ? 1.15 : 1.1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        color: _bg,
        gradient: RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 1.2,
          colors: [
            _currentAccent.withOpacity(0.08),
            _bg,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Texture Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                repeat: ImageRepeat.repeat,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: SafeArea(
              child: Column(
                children: [
                  if (widget.nowPlaying != null) _NowPlayingBar(text: widget.nowPlaying!, accentColor: _currentAccent),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Central 3D Model
                            Positioned(
                              bottom: 0,
                              child: SizedBox(
                                width: constraints.maxWidth * 0.45,
                                height: constraints.maxHeight * 0.45,
                                child: ModelViewer(
                                  key: ValueKey(widget.modelPath),
                                  backgroundColor: Colors.transparent,
                                  src: widget.modelPath,
                                  alt: "Vehicle 3D Model",
                                  autoRotate: true,
                                  cameraControls: false,
                                  disableZoom: true,
                                  disablePan: true,
                                  cameraOrbit: '180deg 75deg 3m',
                                  loading: Loading.lazy,
                                  exposure: 1.0,
                                  shadowIntensity: 0.1,
                                ),
                              ),
                            ),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Transform.scale(
                                    scale: scale,
                                    child: _AnalogClusterGauge(
                                      value: widget.data.speed.toDouble(),
                                      maxValue: widget.maxSpeedKmh,
                                      majorLabels: const ['0', '40', '80', '120', '160', '200', '240', '280', '320'],
                                      unitLabel: 'km/h',
                                      accentColor: _currentAccent,
                                      needleColor: isCompetitive ? Colors.white : _red,
                                      innerValue: '${widget.fuelLevel.round()}',
                                      innerUnit: '%',
                                      innerIcon: Icons.local_gas_station,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth * 0.28,
                                  child: _CenterReadout(
                                    speedKmh: widget.data.speed.toDouble(),
                                    odometerKm: widget.data.odometer.toDouble(),
                                    ambientTempC: widget.ambientTempC,
                                    accentColor: _currentAccent,
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: scale,
                                        child: _AnalogClusterGauge(
                                          value: widget.data.rpm.toDouble(),
                                          maxValue: widget.maxRpm,
                                          majorLabels: const ['0', '1', '2', '3', '4', '5', '6', '7', '8'],
                                          unitLabel: 'x1000/min',
                                          accentColor: _currentAccent,
                                          needleColor: isCompetitive ? Colors.white : _red,
                                          redlineFrom: widget.redlineRpm / widget.maxRpm,
                                          innerValue: '${widget.data.engineTemp.round()}',
                                          innerUnit: '°C',
                                          innerIcon: Icons.thermostat,
                                        ),
                                      ),
                                      if (widget.data.gear.isNotEmpty)
                                        Positioned(
                                          right: 20, 
                                          top: 40,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.8),
                                              border: Border.all(color: _currentAccent, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                 BoxShadow(color: _currentAccent.withOpacity(0.3), blurRadius: 15),
                                              ],
                                            ),
                                            child: Text(
                                              widget.data.gear,
                                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ModeSelector(
                    modes: _modes,
                    selected: _selected,
                    accentColor: _currentAccent,
                    onSelect: (i) {
                      setState(() => _selected = i);
                      widget.onModeChanged?.call(_modes[i]);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar({required this.text, required this.accentColor});
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accentColor.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterReadout extends StatelessWidget {
  const _CenterReadout({
    required this.speedKmh,
    required this.odometerKm,
    required this.ambientTempC,
    required this.accentColor,
  });

  final double speedKmh;
  final double odometerKm;
  final double? ambientTempC;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ambientTempC != null
                  ? '${ambientTempC!.toStringAsFixed(1)}°C'
                  : '',
              style: const TextStyle(
                color: Color(0xFF7C8790),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          speedKmh.round().toString(),
          style: const TextStyle(
            color: Color(0xFFF4D35E),
            fontSize: 72,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -2,
          ),
        ),
        const Text(
          'km/h',
          style: TextStyle(color: Color(0xFF7C8790), fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AnalogClusterGauge extends StatelessWidget {
  const _AnalogClusterGauge({
    required this.value,
    required this.maxValue,
    required this.majorLabels,
    required this.unitLabel,
    required this.accentColor,
    required this.needleColor,
    this.redlineFrom,
    required this.innerValue,
    required this.innerUnit,
    required this.innerIcon,
  });

  final double value;
  final double maxValue;
  final List<String> majorLabels;
  final String unitLabel;
  final Color accentColor;
  final Color needleColor;
  final double? redlineFrom;
  final String innerValue;
  final String innerUnit;
  final IconData innerIcon;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / maxValue).clamp(0.0, 1.0);

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1A1F26), Color(0xFF020304)],
                stops: [0.4, 1],
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _ArcGaugePainter(
              fraction: fraction,
              majorLabels: majorLabels,
              minorPerMajor: 4,
              accentColor: accentColor,
              needleColor: needleColor,
              redlineFrom: redlineFrom,
            ),
          ),
          // Inner Display (Temp/Volt inside circle)
          Positioned(
            bottom: 45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(innerIcon, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    innerValue,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    innerUnit,
                    style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60,
            child: Text(
              unitLabel.toUpperCase(),
              style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({
    required this.fraction,
    required this.majorLabels,
    required this.minorPerMajor,
    required this.accentColor,
    required this.needleColor,
    this.redlineFrom,
  });

  final double fraction;
  final List<String> majorLabels;
  final int minorPerMajor;
  final Color accentColor;
  final Color needleColor;
  final double? redlineFrom;

  static const double _startAngle = 3.14159 * 0.75;
  static const double _sweepAngle = 3.14159 * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 8;

    _drawTicks(canvas, center, radius);
    _drawLabels(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final totalSegments = (majorLabels.length - 1) * minorPerMajor;

    for (int i = 0; i <= totalSegments; i++) {
      final t = i / totalSegments;
      final isMajor = i % minorPerMajor == 0;
      final angle = _startAngle + _sweepAngle * t;
      final outerR = radius;
      final innerR = radius - (isMajor ? 18 : 8);

      final inRedline = redlineFrom != null && t >= redlineFrom!;
      final color = inRedline
          ? const Color(0xFFE8283F)
          : accentColor.withOpacity(isMajor ? 0.95 : 0.4);

      final paint = Paint()
        ..color = color
        ..strokeWidth = isMajor ? 3.0 : 1.2;

      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle)),
        Offset(center.dx + outerR * math.cos(angle), center.dy + outerR * math.sin(angle)),
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < majorLabels.length; i++) {
      final t = i / (majorLabels.length - 1);
      final angle = _startAngle + _sweepAngle * t;
      final labelRadius = radius - 38;
      final pos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final inRedline = redlineFrom != null && t >= redlineFrom!;

      tp.text = TextSpan(
        text: majorLabels[i],
        style: TextStyle(
          color: inRedline ? const Color(0xFFE8283F) : accentColor,
          fontSize: radius * 0.16,
          fontWeight: FontWeight.w900,
        ),
      );
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final angle = _startAngle + _sweepAngle * fraction;
    final length = radius - 26;
    final end = Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, end, needlePaint);
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF1A1D22));
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = needleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return true;
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.modes,
    required this.selected,
    required this.onSelect,
    required this.accentColor,
  });

  final List<String> modes;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(modes.length, (i) {
        final isActive = i == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? accentColor : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                modes[i],
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
