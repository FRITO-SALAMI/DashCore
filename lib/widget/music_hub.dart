import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';

typedef _MusicSnapshot = ({String title, bool playing, bool active});

/// Lightweight, consistent media control for every dashboard.
/// It intentionally renders only title and previous/play/next controls.
class MusicHub extends StatelessWidget {
  const MusicHub({
    super.key,
    this.accentColor = Colors.cyanAccent,
    this.width = 280,
    this.compact = false,
  });

  final Color accentColor;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Selector<MusicProvider, _MusicSnapshot>(
      selector: (_, music) => (
        title: music.trackTitle,
        playing: music.isPlaying,
        active: music.hasActiveSession,
      ),
      builder: (context, state, _) {
        final music = context.read<MusicProvider>();
        return RepaintBoundary(
          child: Container(
            width: width,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 7 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
              border: Border.all(color: accentColor.withOpacity(0.65)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: state.active ? Colors.white : Colors.white54,
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _button(Icons.skip_previous_rounded, music.previous),
                _button(
                  state.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  music.playPause,
                ),
                _button(Icons.skip_next_rounded, music.next),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _button(IconData icon, VoidCallback onPressed) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
      ),
      padding: EdgeInsets.zero,
      splashRadius: compact ? 15 : 18,
      onPressed: onPressed,
      icon: Icon(icon, color: accentColor, size: compact ? 18 : 22),
    );
  }
}
