import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';

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
    Widget child;

    if (type == 'music_hub') {
      child = _MusicHub(size: size, color: color);
    } else {
      switch (design) {
        case 1: child = _ModernDesign(value: value, unit: unit, color: color, size: size); break;
        case 2: child = _MinimalDesign(value: value, unit: unit, color: color, size: size); break;
        case 3: child = _RetroDesign(value: value, unit: unit, color: color, size: size); break;
        case 0:
        default: child = _DefaultDesign(value: value, unit: unit, color: color, size: size); break;
      }
    }

    if (logoPath != null && logoPath!.isNotEmpty) {
      return Stack(
        children: [
          child,
          Positioned(
            top: 5, right: 5,
            child: Opacity(
              opacity: 0.8,
              child: Image.file(
                File(logoPath!),
                width: size.width * 0.25,
                height: size.width * 0.25,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      );
    }

    return child;
  }
}

class _DefaultDesign extends StatelessWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  const _DefaultDesign({required this.value, required this.unit, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width, height: size.height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              value.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
            ),
          ),
          Text(
            unit,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _ModernDesign extends StatelessWidget {
  final dynamic value;
  final String unit;
  final Color color;
  final Size size;
  const _ModernDesign({required this.value, required this.unit, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width, height: size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23).withOpacity(0.9),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(width: 6, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)))),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(unit, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                FittedBox(child: Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w100))),
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
  const _MinimalDesign({required this.value, required this.unit, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width, height: size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(child: Text(value.toString(), style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.w900, height: 1.0))),
          Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
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
  const _RetroDesign({required this.value, required this.unit, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width, height: size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border.all(color: color, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(child: Text(value.toString(), style: TextStyle(color: color, fontSize: 30, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
            Text(unit, style: TextStyle(color: color, fontSize: 8, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

class _MusicHub extends StatelessWidget {
  final Size size;
  final Color color;
  const _MusicHub({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final bool isSmall = size.width < 180;
    
    // Usar directamente el musicProvider que ya gestiona el estado
    final bool hasTrack = musicProvider.currentTrack != null && musicProvider.currentTrack!.title != null;
    final track = musicProvider.currentTrack;

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
      child: Row(
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
              child: hasTrack && track!.hasImage
                  ? Image(image: track.image!, fit: BoxFit.cover)
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

          // Controls (Now always visible)
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
      ),
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
