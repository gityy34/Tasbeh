import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WaterCounter extends StatefulWidget {
  const WaterCounter({
    super.key,
    required this.count,
    required this.target,
    required this.progress,
    required this.colors,
    required this.onTap,
  });

  final int count;
  final int? target;
  final double progress;
  final CounterColors colors;
  final VoidCallback onTap;

  @override
  State<WaterCounter> createState() => _WaterCounterState();
}

class _WaterCounterState extends State<WaterCounter>
    with TickerProviderStateMixin {
  late final AnimationController _waves = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _waves.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulse.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = widget.count.toString();
    final targetLabel = widget.target == null ? '∞' : widget.target.toString();
    return Semantics(
      button: true,
      label: 'Tasbeh count $countLabel of $targetLabel. Tap to increment.',
      onTap: _handleTap,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: Listenable.merge([_waves, _pulse]),
            builder: (context, child) {
              final scale = 1 + (1 - Curves.easeOut.transform(_pulse.value)) * 0.018;
              return Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _WaterPainter(
                    phase: _waves.value,
                    pulse: _pulse.value,
                    progress: widget.progress,
                    colors: widget.colors,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countLabel,
                              style: TextStyle(
                                color: widget.colors.foreground,
                                fontSize: 78,
                                fontWeight: FontWeight.w800,
                                height: 0.95,
                                letterSpacing: -2,
                                shadows: const [
                                  Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'of $targetLabel',
                              style: TextStyle(
                                color: widget.colors.foreground.withValues(alpha: 0.94),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.colors.foreground.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.colors.foreground.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                child: Text(
                                  widget.target == null
                                      ? 'Infinite remembrance'
                                      : '${(widget.progress * 100).round()}% complete',
                                  style: TextStyle(
                                    color: widget.colors.foreground,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  const _WaterPainter({
    required this.phase,
    required this.pulse,
    required this.progress,
    required this.colors,
  });

  final double phase;
  final double pulse;
  final double progress;
  final CounterColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final circle = Rect.fromCircle(center: center, radius: radius);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center.translate(0, 8), radius - 1, shadow);

    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.38),
        radius: 1.1,
        colors: [colors.top.withValues(alpha: 0.98), colors.bottom],
      ).createShader(circle);
    canvas.drawCircle(center, radius, base);

    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    final waterLine = size.height * (1 - (0.28 + progress * 0.3));
    final wavePath = Path()..moveTo(0, waterLine);
    final waveWidth = size.width / 2;
    for (var i = -1; i < 3; i++) {
      final startX = i * waveWidth;
      final phaseOffset = phase * math.pi * 2 + i * 0.7;
      wavePath.cubicTo(
        startX + waveWidth * 0.25,
        waterLine + math.sin(phaseOffset) * 10,
        startX + waveWidth * 0.25,
        waterLine + math.sin(phaseOffset + math.pi) * 10,
        startX + waveWidth * 0.5,
        waterLine,
      );
      wavePath.cubicTo(
        startX + waveWidth * 0.75,
        waterLine + math.sin(phaseOffset + math.pi) * 10,
        startX + waveWidth * 0.75,
        waterLine + math.sin(phaseOffset) * 10,
        startX + waveWidth,
        waterLine,
      );
    }
    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = LinearGradient(
          colors: [colors.accent.withValues(alpha: 0.94), colors.bottom.withValues(alpha: 0.98)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, waterLine, size.width, size.height - waterLine)),
    );

    final highlight = Paint()
      ..color = colors.accentSoft.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final highlightPath = Path()..moveTo(0, waterLine - 2);
    for (var i = -1; i < 3; i++) {
      final startX = i * waveWidth;
      highlightPath.cubicTo(
        startX + waveWidth * .2,
        waterLine - 8 + math.sin(phase * math.pi * 2 + i) * 5,
        startX + waveWidth * .35,
        waterLine + 5,
        startX + waveWidth * .5,
        waterLine - 2,
      );
      highlightPath.cubicTo(
        startX + waveWidth * .68,
        waterLine - 10,
        startX + waveWidth * .82,
        waterLine + 4,
        startX + waveWidth,
        waterLine - 2,
      );
    }
    canvas.drawPath(highlightPath, highlight);

    final bubblePaint = Paint()..color = colors.accentSoft.withValues(alpha: 0.32);
    final bubbles = [
      Offset(size.width * .2, size.height * .7),
      Offset(size.width * .76, size.height * .73),
      Offset(size.width * .14, size.height * .48),
      Offset(size.width * .84, size.height * .44),
      Offset(size.width * .68, size.height * .25),
    ];
    for (var i = 0; i < bubbles.length; i++) {
      final drift = math.sin(phase * math.pi * 2 + i) * 5;
      final bubble = bubbles[i].translate(drift, 0);
      canvas.drawCircle(bubble, 3.5 + i % 3 * 1.8, bubblePaint);
      canvas.drawCircle(bubble.translate(-1, -1), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.72));
    }
    if (pulse > 0) {
      final ripple = radius * (0.35 + pulse * 0.38);
      canvas.drawCircle(
        Offset(size.width * .5, waterLine),
        ripple,
        Paint()
          ..color = colors.accentSoft.withValues(alpha: (1 - pulse) * 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.restore();

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = SweepGradient(
        colors: [colors.accentSoft, colors.accent, colors.bottom, colors.accentSoft],
      ).createShader(circle);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.36),
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(-2, -2), radius: radius - 8),
      math.pi * 1.08,
      math.pi * .7,
      false,
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.pulse != pulse ||
        oldDelegate.progress != progress ||
        oldDelegate.colors != colors;
  }
}

