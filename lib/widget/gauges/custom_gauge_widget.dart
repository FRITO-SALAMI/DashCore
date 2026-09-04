import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/dash_settings_provider.dart';
import '../music_hub.dart';

class CustomGaugeWidget extends StatelessWidget {
  final String type;
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  final int design;
  final String? logoPath;

  const CustomGaugeWidget({
    super.key,
    required this.type,
    required this.value,
    required this.unit,
    required this.color,
    this.size = const Size(120, 80),
    this.design = 0,
    this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    Widget child;
    final bool hasImage = logoPath != null && logoPath!.isNotEmpty;

    // Warning logic
    bool isWarning = false;
    Color displayColor = color;

    if (type == 'temp' && settings.tempWarningEnabled) {
       final int temp = value is int ? value : (int.tryParse(value.toString()) ?? 0);
       isWarning = temp >= settings.tempAlertThreshold;
    } else if (type == 'speed' && settings.speedWarningEnabled) {
       final double speed = value is num ? value.toDouble() : (double.tryParse(value.toString()) ?? 0.0);
       isWarning = speed >= settings.speedAlertThreshold;
    }

    if (isWarning) displayColor = Colors.redAccent;

    if (type == 'music_hub') {
      child = MusicHub(accentColor: color, width: size.width, compact: size.height < 90);
    } else if (type == 'box') {
      child = _BoxGauge(logoPath: logoPath, size: size);
    } else {
      switch (design) {
        case 1: child = _ModernDesign(value: value, unit: unit, color: displayColor, size: size, hasImage: hasImage, isWarning: isWarning); break;
        case 2: child = _MinimalDesign(value: value, unit: unit, color: displayColor, size: size, isWarning: isWarning); break;
        case 3: child = _RetroDesign(value: value, unit: unit, color: displayColor, size: size, hasImage: hasImage, isWarning: isWarning); break;
        case 4: child = _CircularDesign(value: value, unit: unit, color: displayColor, size: size); break;
        case 0:
        default: child = _DefaultDesign(value: value, unit: unit, color: displayColor, size: size, hasImage: hasImage, isWarning: isWarning); break;
      }
    }

    if (hasImage && type != 'box') {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15)],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: logoPath!.endsWith('.gif') || logoPath!.startsWith('assets/')
                ? Image.asset(logoPath!, fit: BoxFit.cover)
                : Image.file(File(logoPath!), fit: BoxFit.cover),
            ),
            Container(color: Colors.black.withOpacity(0.3)), // Darken image slightly
            child,
          ],
        ),
      );
    }

    return child;
  }
}

class _DefaultDesign extends StatefulWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  final bool hasImage;
  final bool isWarning;
  const _DefaultDesign({required this.value, required this.unit, required this.color, required this.size, this.hasImage = false, this.isWarning = false});

  @override
  State<_DefaultDesign> createState() => _DefaultDesignState();
}

class _DefaultDesignState extends State<_DefaultDesign> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.isWarning) _blinkController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _DefaultDesign oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWarning && !oldWidget.isWarning) _blinkController.repeat(reverse: true);
    else if (!widget.isWarning && oldWidget.isWarning) _blinkController.stop();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final opacity = widget.isWarning ? _blinkController.value : 1.0;

        return Opacity(
          opacity: widget.isWarning ? (0.4 + 0.6 * opacity) : 1.0,
          child: Container(
            width: widget.size.width, height: widget.size.height,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.hasImage ? Colors.transparent : Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border: widget.hasImage ? null : Border.all(color: widget.color.withOpacity(0.4), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    widget.value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
                  ),
                ),
                Text(
                  widget.unit,
                  style: TextStyle(color: widget.hasImage ? Colors.white : widget.color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModernDesign extends StatelessWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  final bool hasImage;
  final bool isWarning;
  const _ModernDesign({required this.value, required this.unit, required this.color, required this.size, this.hasImage = false, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width, height: size.height,
      decoration: BoxDecoration(
        color: hasImage ? Colors.transparent : const Color(0xFF1A1D23).withOpacity(0.9),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
        border: hasImage ? null : Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          if (isWarning) BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          if (!hasImage) Container(width: 6, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)))),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(unit, style: TextStyle(color: hasImage ? Colors.white : color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                FittedBox(child: Text(value.toString(), style: TextStyle(color: isWarning ? Colors.redAccent : Colors.white, fontSize: 38, fontWeight: FontWeight.w100))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalDesign extends StatelessWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  final bool isWarning;
  const _MinimalDesign({required this.value, required this.unit, required this.color, required this.size, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width, height: size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(child: Text(value.toString(), style: TextStyle(color: isWarning ? Colors.redAccent : color, fontSize: 44, fontWeight: FontWeight.w900, height: 1.0))),
          Text(unit, style: TextStyle(color: isWarning ? Colors.redAccent.withOpacity(0.5) : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RetroDesign extends StatelessWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  final bool hasImage;
  final bool isWarning;
  const _RetroDesign({required this.value, required this.unit, required this.color, required this.size, this.hasImage = false, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width, height: size.height,
      decoration: BoxDecoration(
        color: hasImage ? Colors.transparent : const Color(0xFF121212),
        border: hasImage ? null : Border.all(color: isWarning ? Colors.redAccent : color, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: hasImage ? null : BoxDecoration(border: Border.all(color: (isWarning ? Colors.redAccent : color).withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(child: Text(value.toString(), style: TextStyle(color: isWarning ? Colors.redAccent : (hasImage ? Colors.white : color), fontSize: 32, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
            Text(unit, style: TextStyle(color: isWarning ? Colors.redAccent : (hasImage ? Colors.white : color), fontSize: 8, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

class _CircularDesign extends StatelessWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  const _CircularDesign({required this.value, required this.unit, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    double numericValue = 0.0;
    if (value is num) numericValue = value.toDouble();
    else if (value is String) numericValue = double.tryParse(value) ?? 0.0;

    final double maxValue = unit.toUpperCase().contains('RPM') ? 8000 : 240;
    final double redline = unit.toUpperCase().contains('RPM') ? 4500 : 200;

    return SizedBox(
      width: size.width, height: size.height,
      child: CustomPaint(
        painter: _CircularGaugePainter(
          value: numericValue,
          maxValue: maxValue,
          redline: redline,
          color: color,
          unit: unit,
        ),
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double value, maxValue, redline;
  final Color color;
  final String unit;
  _CircularGaugePainter({required this.value, required this.maxValue, required this.redline, required this.color, required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final startAngle = 0.75 * math.pi;
    final sweepAngle = 1.5 * math.pi;

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 6;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    final progress = (value / maxValue).clamp(0.0, 1.0);
    final isRedline = value >= redline;

    final fgPaint = Paint()..color = isRedline ? Colors.redAccent : color..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, fgPaint);

    // Redline indicator
    final redlineT = redline / maxValue;
    final redlinePaint = Paint()..color = Colors.red.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle + sweepAngle * redlineT, sweepAngle * (1 - redlineT), false, redlinePaint);

    // Needle
    final needleAngle = startAngle + sweepAngle * progress;
    final needlePaint = Paint()..color = Colors.white..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + Offset(math.cos(needleAngle) * (radius - 5), math.sin(needleAngle) * (radius - 5)), needlePaint);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    // Label unit
    final textPainter = TextPainter(
      text: TextSpan(text: unit, style: TextStyle(color: Colors.white24, fontSize: radius * 0.25, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, radius * 0.4));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _MusicHub extends StatelessWidget {
  final Size size;
  final Color color;
  final int design;
  const _MusicHub({required this.size, required this.color, this.design = 0});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final bool isSmall = size.width < 180;
    
    // Usar directamente el musicProvider que ya gestiona el estado
    final bool hasTrack = musicProvider.hasActiveSession;

    Widget content;

    switch(design) {
      case 1:
        content = _buildMinimalDesign(musicProvider, isSmall);
        break;
      case 2:
        content = _buildVisualizerDesign(musicProvider, isSmall);
        break;
      case 0:
      default:
        content = _buildDefaultDesign(musicProvider, isSmall, hasTrack);
        break;
    }

    return Container(
      width: size.width,
      height: size.height,
      padding: EdgeInsets.all(isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: content,
    );
  }

  Widget _buildDefaultDesign(MusicProvider musicProvider, bool isSmall, bool hasTrack) {
    return Row(
      children: [
        // Album Art with Neon Glow
        Container(
          width: isSmall ? 36 : 55,
          height: isSmall ? 36 : 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              if (hasTrack) BoxShadow(color: color.withOpacity(0.2), blurRadius: 8),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: musicProvider.nativeArtwork != null
                ? Image.memory(musicProvider.nativeArtwork!, fit: BoxFit.cover)
                : Icon(Icons.music_note_rounded, color: color, size: isSmall ? 20 : 30),
          ),
        ),
        const SizedBox(width: 14),

        // Track Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                musicProvider.trackTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 11 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                musicProvider.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: isSmall ? 9 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSmall) ...[
              _MusicButton(
                icon: Icons.skip_previous_rounded,
                onTap: () => musicProvider.previous(),
              ),
              const SizedBox(width: 4),
            ],
            _MusicButton(
              icon: musicProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              isMain: !isSmall,
              color: color,
              onTap: () => musicProvider.playPause(),
            ),
            if (!isSmall) ...[
              const SizedBox(width: 4),
              _MusicButton(
                icon: Icons.skip_next_rounded,
                onTap: () => musicProvider.next(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalDesign(MusicProvider musicProvider, bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MusicButton(
          icon: Icons.skip_previous_rounded,
          onTap: () => musicProvider.previous(),
        ),
        _MusicButton(
          icon: musicProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          isMain: true,
          color: color,
          onTap: () => musicProvider.playPause(),
        ),
        _MusicButton(
          icon: Icons.skip_next_rounded,
          onTap: () => musicProvider.next(),
        ),
        const VerticalDivider(color: Colors.white10, indent: 10, endIndent: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                musicProvider.trackTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: musicProvider.progress,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizerDesign(MusicProvider musicProvider, bool isSmall) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                musicProvider.trackTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
              ),
              Text(
                musicProvider.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: _MusicVisualizer(
            isPlaying: musicProvider.isPlaying,
            color: color,
          ),
        ),
        _MusicButton(
          icon: musicProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          isMain: true,
          color: color,
          onTap: () => musicProvider.playPause(),
        ),
      ],
    );
  }
}

class _MusicVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  const _MusicVisualizer({required this.isPlaying, required this.color});

  @override
  State<_MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<_MusicVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = List.generate(15, (index) => 0.2 + (index % 5) * 0.1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(15, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 3,
              height: widget.isPlaying
                  ? (10 + 30 * math.sin((_controller.value * 2 * math.pi) + (index * 0.5)).abs())
                  : 4,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(widget.isPlaying ? 0.8 : 0.2),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  if (widget.isPlaying) BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 4),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _MusicButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isMain;
  final Color? color;

  const _MusicButton({
    required this.icon,
    required this.onTap,
    this.isMain = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isMain ? 42 : 32,
        height: isMain ? 42 : 32,
        decoration: BoxDecoration(
          color: isMain ? (color ?? Colors.white) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          boxShadow: isMain && color != null ? [BoxShadow(color: color!.withOpacity(0.4), blurRadius: 10)] : null,
        ),
        child: Icon(
          icon,
          color: isMain ? Colors.black : Colors.white70,
          size: isMain ? 28 : 20,
        ),
      ),
    );
  }
}

class _BoxGauge extends StatelessWidget {
  final String? logoPath;
  final Size size;
  const _BoxGauge({this.logoPath, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: logoPath != null && logoPath!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: logoPath!.endsWith('.gif') || logoPath!.startsWith('assets/')
                  ? Image.asset(logoPath!, fit: BoxFit.cover)
                  : Image.file(File(logoPath!), fit: BoxFit.cover),
            )
          : const Center(child: Icon(Icons.add_photo_alternate_rounded, color: Colors.white24)),
    );
  }
}
