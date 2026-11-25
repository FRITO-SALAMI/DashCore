import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';

class ReconnectionBanner extends StatelessWidget {
  const ReconnectionBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = context.select<DashSettingsProvider, bool>((s) => s.reduceMotion);

    return Material(
      elevation: 8,
      color: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThreeDotsLoading(
              color: colorScheme.primary,
              isStatic: reduceMotion,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeDotsLoading extends StatefulWidget {
  final Color color;
  final bool isStatic;

  const _ThreeDotsLoading({
    required this.color,
    required this.isStatic,
  });

  @override
  State<_ThreeDotsLoading> createState() => _ThreeDotsLoadingState();
}

class _ThreeDotsLoadingState extends State<_ThreeDotsLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!widget.isStatic) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _ThreeDotsLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStatic != oldWidget.isStatic) {
      if (widget.isStatic) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double opacity = 1.0;
            if (!widget.isStatic) {
              final delay = index * 0.2;
              double progress = (_controller.value - delay) % 1.0;
              if (progress < 0) progress += 1.0;

              if (progress < 0.5) {
                opacity = 0.3 + (progress * 1.4); // Fade in
              } else {
                opacity = 1.0 - ((progress - 0.5) * 1.4); // Fade out
              }
            }

            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
