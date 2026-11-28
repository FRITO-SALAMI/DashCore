import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MusicHub extends StatelessWidget {
  const MusicHub({
    super.key,
    this.accentColor = AppColors.accent,
    this.width,
    this.compact = false,
  });

  final Color accentColor;
  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Tooltip(
        message: 'DashMix',
        child: Icon(
          Icons.music_note_rounded,
          color: accentColor,
          size: compact ? 20 : 24,
          semanticLabel: 'DashMix',
        ),
      ),
    );
  }
}
