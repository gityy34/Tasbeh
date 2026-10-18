import 'package:flutter/material.dart';

import '../content/tasbeeh_catalog.dart';

class SplashArtwork extends StatelessWidget {
  const SplashArtwork({super.key, required this.isNight});

  final bool isNight;

  String get _assetPath =>
      isNight ? 'assets/images/splash_night.jpg' : 'assets/images/splash_day.jpg';

  @override
  Widget build(BuildContext context) {
    final label = isNight
        ? 'Night Tasbeh Counter splash screen'
        : 'Day Tasbeh Counter splash screen';

    return ColoredBox(
      color: isNight ? const Color(0xFF031127) : const Color(0xFFEAF6FF),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: _AnimatedSplashImage(
          key: ValueKey(_assetPath),
          assetPath: _assetPath,
          semanticLabel: label,
        ),
      ),
    );
  }
}

class _AnimatedSplashImage extends StatefulWidget {
  const _AnimatedSplashImage({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
  });

  final String assetPath;
  final String semanticLabel;

  @override
  State<_AnimatedSplashImage> createState() => _AnimatedSplashImageState();
}

class _AnimatedSplashImageState extends State<_AnimatedSplashImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.035, end: 1)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        child: Image.asset(
          widget.assetPath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          cacheWidth: 720,
          cacheHeight: 1280,
          excludeFromSemantics: true,
        ),
        builder: (context, child) => FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: child,
          ),
        ),
      ),
    );
  }
}
