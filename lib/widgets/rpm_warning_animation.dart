import 'package:flutter/material.dart';

class RpmWarningAnimation extends StatefulWidget {
  final int rpm;
  final int threshold;
  final Widget child;

  const RpmWarningAnimation({
    super.key,
    required this.rpm,
    this.threshold = 4800,
    required this.child,
  });

  @override
  State<RpmWarningAnimation> createState() => _RpmWarningAnimationState();
}

class _RpmWarningAnimationState extends State<RpmWarningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RpmWarningAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rpm >= widget.threshold) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.reset();
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.red.withOpacity(widget.rpm >= widget.threshold ? (1.0 - _animation.value) * 0.5 : 0.0),
            BlendMode.srcATop,
          ),
          child: Opacity(
            opacity: widget.rpm >= widget.threshold ? _animation.value : 1.0,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
