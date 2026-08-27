import 'package:flutter/material.dart';
import '../models/gadget_config.dart';

class EditableGadgetWrapper extends StatelessWidget {
  final GadgetConfig config;
  final bool isEditMode;
  final Function(GadgetConfig) onConfigChanged;
  final VoidCallback onTapEdit;
  final Widget child;
  final Size parentSize;

  const EditableGadgetWrapper({
    super.key,
    required this.config,
    required this.isEditMode,
    required this.onConfigChanged,
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
        if (isEditMode)
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (config.locked) return;

                final newX = (config.relativeX + details.delta.dx / parentSize.width).clamp(0.0, 1.0 - config.relativeWidth);
                final newY = (config.relativeY + details.delta.dy / parentSize.height).clamp(0.0, 1.0 - config.relativeHeight);

                onConfigChanged(config.copyWith(
                  relativeX: newX,
                  relativeY: newY,
                ));
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
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
                          child: const Icon(Icons.settings, size: 14, color: Colors.black),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.open_with, color: Colors.cyanAccent, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
