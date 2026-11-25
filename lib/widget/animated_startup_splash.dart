import 'package:flutter/material.dart';
import '../core/app_brand.dart';

/// One short fade, with the application tree built only once.
class AnimatedStartupSplash extends StatefulWidget {
  const AnimatedStartupSplash({super.key, required this.child});
  final Widget child;
  @override
  State<AnimatedStartupSplash> createState() => _AnimatedStartupSplashState();
}

class _AnimatedStartupSplashState extends State<AnimatedStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _complete = true);
      });
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    widget.child,
    if (!_complete)
      FadeTransition(
        opacity: ReverseAnimation(_fade),
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: Image.asset(AppBrand.logoAsset, width: 200, cacheWidth: 400)),
        ),
      ),
  ]);
}
