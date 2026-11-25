import 'package:flutter/material.dart';
import '../models/gadget_config.dart';

class EditableGadgetWrapper extends StatelessWidget {
  final GadgetConfig config;
  final bool isEditMode;
  final Function(GadgetConfig) onConfigChanged;
  final VoidCallback? onConfigChangeEnd;
  final VoidCallback onTapEdit;
  final Widget child;
  final Size parentSize;

  const EditableGadgetWrapper({
    super.key,
    required this.config,
    required this.isEditMode,
    required this.onConfigChanged,
    this.onConfigChangeEnd,
    required this.onTapEdit,
    required this.child,
    this.parentSize = const Size(100, 100),
  });

  @override
  Widget build(BuildContext context) {
    if (!config.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        child,
        if (isEditMode) ...[
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (config.locked || parentSize.isEmpty) return;

                final newX =
                    (config.relativeX + details.delta.dx / parentSize.width)
                        .clamp(
                          0.0,
                          (1.0 - config.relativeWidth).clamp(0.0, 1.0),
                        );
                final newY =
                    (config.relativeY + details.delta.dy / parentSize.height)
                        .clamp(
                          0.0,
                          (1.0 - config.relativeHeight).clamp(0.0, 1.0),
                        );

                onConfigChanged(
                  config.copyWith(relativeX: newX, relativeY: newY),
                );
              },
              onPanEnd: (_) => onConfigChangeEnd?.call(),
              onPanCancel: onConfigChangeEnd,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    width: 2,
                  ),
                  color: Colors.cyanAccent.withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onTapEdit,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.open_with,
                        color: Colors.cyanAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                if (config.locked || parentSize.isEmpty) return;
                final maxWidth = (1.0 - config.relativeX).clamp(0.0, 1.0);
                final maxHeight = (1.0 - config.relativeY).clamp(0.0, 1.0);
                final width =
                    (config.relativeWidth + details.delta.dx / parentSize.width)
                        .clamp(maxWidth < .10 ? maxWidth : .10, maxWidth);
                final height =
                    (config.relativeHeight +
                            details.delta.dy / parentSize.height)
                        .clamp(maxHeight < .10 ? maxHeight : .10, maxHeight);
                onConfigChanged(
                  config.copyWith(relativeWidth: width, relativeHeight: height),
                );
              },
              onPanEnd: (_) => onConfigChangeEnd?.call(),
              onPanCancel: onConfigChangeEnd,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
                ),
                child: const Icon(
                  Icons.open_in_full_rounded,
                  size: 17,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
