import 'dart:math' as math;

import 'package:flutter/material.dart';

const bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

class SplashArtwork extends StatelessWidget {
  const SplashArtwork({super.key, required this.isNight});

  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final foreground = isNight ? const Color(0xFFFFF1C7) : const Color(0xFF6B4419);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _SplashPainter(isNight: isNight)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 48, 26, 34),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Semantics(
                  label: 'Bismillah',
                  child: Text(
                    bismillah,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontFamilyFallback: const ['Noto Naskh Arabic', 'Noto Sans Arabic', 'sans'],
                      fontSize: 30,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: isNight ? 0.55 : 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Tasbeh Counter',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 26),
                const _LoadingBar(),
                const Spacer(flex: 3),
                Text(
                  isNight ? 'A quiet moment under the stars' : 'A quiet moment of remembrance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.84),
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => SizedBox(
        width: 210,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : const Color(0xFF674314))
                .withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (isDark ? Colors.white : const Color(0xFF674314))
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _controller.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF52C9FF), Color(0xFFE6F8FF)]
                        : const [Color(0xFFB87316), Color(0xFFFFE2A8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  const _SplashPainter({required this.isNight});

  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = isNight
        ? const [Color(0xFF020A23), Color(0xFF0D2C54), Color(0xFF031127)]
        : const [Color(0xFFEAF6FF), Color(0xFF8BC6F1), Color(0xFFFFF2D0)];
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(rect),
    );

    final archPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = isNight ? const Color(0xFFC58B2D) : const Color(0xFFB98636);
    final archRect = Rect.fromLTWH(
      size.width * -0.16,
      size.height * 0.07,
      size.width * 1.32,
      size.height * 0.72,
    );
    canvas.drawArc(archRect, math.pi, math.pi, false, archPaint);
    final inner = archRect.deflate(18);
    canvas.drawArc(inner, math.pi, math.pi, false, archPaint..strokeWidth = 2);

    final patternPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = archPaint.color.withValues(alpha: 0.65);
    for (var i = 0; i < 11; i++) {
      final x = size.width * (0.08 + i * 0.084);
      final y = size.height * 0.11 + (i.isEven ? 0 : 7);
      canvas.drawCircle(Offset(x, y), 18, patternPaint);
      canvas.drawLine(Offset(x - 12, y), Offset(x + 12, y), patternPaint);
      canvas.drawLine(Offset(x, y - 12), Offset(x, y + 12), patternPaint);
    }

    final glow = Paint()
      ..color = isNight ? const Color(0xFFFFE39C) : const Color(0xFFFFE4A8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    if (isNight) {
      canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.18), 25, glow);
      canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.18), 18, Paint()..color = const Color(0xFFFFE7AB));
      canvas.drawCircle(Offset(size.width * 0.765, size.height * 0.17), 18, Paint()..color = const Color(0xFF081B3A));
      final stars = [
        Offset(size.width * .17, size.height * .17),
        Offset(size.width * .38, size.height * .11),
        Offset(size.width * .86, size.height * .29),
        Offset(size.width * .24, size.height * .33),
        Offset(size.width * .59, size.height * .25),
      ];
      for (final star in stars) {
        canvas.drawCircle(star, 2.2, glow);
        canvas.drawCircle(star, 1.2, Paint()..color = Colors.white);
      }
    } else {
      canvas.drawCircle(Offset(size.width * .8, size.height * .23), 38, glow);
      canvas.drawCircle(Offset(size.width * .8, size.height * .23), 24, Paint()..color = const Color(0xFFFFD36C));
    }

    final horizon = size.height * 0.78;
    final floor = Paint()
      ..shader = LinearGradient(
        colors: isNight
            ? const [Color(0xFF0A2B4B), Color(0xFF031429)]
            : const [Color(0xFFFFF6DE), Color(0xFF9FCBED)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, horizon, size.width, size.height - horizon));
    canvas.drawRect(Rect.fromLTWH(0, horizon, size.width, size.height - horizon), floor);

    final mosque = Paint()..color = isNight ? const Color(0xFF06152C) : const Color(0xFFFDF8EA);
    final dome = Path()
      ..moveTo(size.width * .28, horizon)
      ..quadraticBezierTo(size.width * .5, horizon - size.height * .18, size.width * .72, horizon)
      ..close();
    canvas.drawPath(dome, mosque);
    canvas.drawRect(Rect.fromLTWH(size.width * .42, horizon, size.width * .16, size.height * .22), mosque);
    for (final x in [0.12, 0.82]) {
      canvas.drawRect(Rect.fromLTWH(size.width * x, horizon - size.height * .17, size.width * .055, size.height * .39), mosque);
      canvas.drawCircle(Offset(size.width * (x + .0275), horizon - size.height * .18), size.width * .04, mosque);
      canvas.drawRect(Rect.fromLTWH(size.width * (x - .01), horizon - size.height * .2, size.width * .075, size.height * .015), mosque);
    }

    final linePaint = Paint()
      ..color = isNight ? const Color(0xFF4F87B8) : const Color(0xFFB88945)
      ..strokeWidth = 1;
    for (var i = 1; i < 7; i++) {
      final y = horizon + (size.height - horizon) * i / 7;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) =>
      oldDelegate.isNight != isNight;
}

