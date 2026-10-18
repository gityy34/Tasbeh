import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';

class WaterCounter extends StatefulWidget {
  const WaterCounter({
    super.key,
    required this.count,
    required this.target,
    required this.progress,
    required this.colors,
    required this.palette,
    required this.isDark,
    required this.onTap,
  });

  final int count;
  final int? target;
  final double progress;
  final CounterColors colors;
  final CounterPalette palette;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<WaterCounter> createState() => _WaterCounterState();
}

class _WaterCounterState extends State<WaterCounter>
    with TickerProviderStateMixin {
  late final AnimationController _waves = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final AnimationController _impact = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  bool get _isRealistic =>
      widget.palette == CounterPalette.realisticWater;

  @override
  void initState() {
    super.initState();
    _syncAmbientAnimation();
  }

  @override
  void didUpdateWidget(covariant WaterCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.palette != widget.palette) {
      _syncAmbientAnimation();
    }
  }

  void _syncAmbientAnimation() {
    if (_isRealistic) {
      _waves.stop();
    } else {
      _waves.repeat();
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    _pulse.dispose();
    _impact.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isRealistic) {
      _impact.forward(from: 0);
    } else {
      _pulse.forward(from: 0);
    }
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
            animation: Listenable.merge([_waves, _pulse, _impact]),
            builder: (context, child) {
              final scale = 1 +
                  (1 - Curves.easeOut.transform(_pulse.value)) * 0.018;
              final painter = _isRealistic
                  ? _RealisticWaterPainter(
                      impact: _impact.value,
                      progress: widget.progress,
                      colors: widget.colors,
                      isDark: widget.isDark,
                    )
                  : _WaterPainter(
                      phase: _waves.value,
                      pulse: _pulse.value,
                      progress: widget.progress,
                      colors: widget.colors,
                    );
              return Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: painter,
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
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'of $targetLabel',
                              style: TextStyle(
                                color: widget.colors.foreground.withValues(
                                  alpha: 0.94,
                                ),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.colors.foreground.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.colors.foreground.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 7,
                                ),
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

class _RealisticWaterPainter extends CustomPainter {
  const _RealisticWaterPainter({
    required this.impact,
    required this.progress,
    required this.colors,
    required this.isDark,
  });

  final double impact;
  final double progress;
  final CounterColors colors;
  final bool isDark;

  double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final circle = Rect.fromCircle(center: center, radius: radius);
    final waveEnergy = math.sin(math.pi * impact).clamp(0.0, 1.0).toDouble();
    final waterLine = size.height * (0.43 - progress.clamp(0.0, 1.0) * 0.08);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.32 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center.translate(0, 10), radius - 1, shadow);

    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.5),
        radius: 1.15,
        colors: isDark
            ? const [Color(0xFF2E8DB9), Color(0xFF0A3B69), Color(0xFF03152D)]
            : const [Color(0xFFE3FBFF), Color(0xFF7BDCF7), Color(0xFF0878D1)],
        stops: const [0.04, 0.5, 1],
      ).createShader(circle);
    canvas.drawCircle(center, radius, sphere);

    canvas.save();
    canvas.clipPath(Path()..addOval(circle));

    final waterPath = _wavePath(
      size,
      waterLine,
      amplitude: 13 * waveEnergy,
      phase: impact * math.pi * 3.5,
    );
    canvas.drawPath(
      waterPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF1D9DCE), Color(0xFF064A83), Color(0xFF021B39)]
              : const [Color(0xFF32C7F3), Color(0xFF068BD0), Color(0xFF0457A5)],
          stops: const [0, 0.28, 1],
        ).createShader(Rect.fromLTWH(0, waterLine, size.width, size.height)),
    );

    _drawWaterDepth(canvas, size, waterLine, waveEnergy);
    _drawSurfaceHighlights(canvas, size, waterLine, waveEnergy);
    _drawBubbles(canvas, size, waveEnergy);
    _drawImpact(canvas, size, waterLine);

    canvas.restore();
    _drawGlassRim(canvas, circle, center, radius);
  }

  Path _wavePath(
    Size size,
    double waterLine, {
    required double amplitude,
    required double phase,
  }) {
    final path = _surfacePath(
      size,
      waterLine,
      amplitude: amplitude,
      phase: phase,
    );
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  Path _surfacePath(
    Size size,
    double waterLine, {
    required double amplitude,
    required double phase,
  }) {
    final path = Path()..moveTo(0, waterLine);
    final segment = size.width / 2;
    for (var i = -1; i < 3; i++) {
      final start = i * segment;
      final offset = phase + i * 0.8;
      path.cubicTo(
        start + segment * 0.22,
        waterLine + math.sin(offset) * amplitude,
        start + segment * 0.28,
        waterLine - math.sin(offset) * amplitude,
        start + segment * 0.5,
        waterLine,
      );
      path.cubicTo(
        start + segment * 0.72,
        waterLine + math.sin(offset) * amplitude,
        start + segment * 0.78,
        waterLine - math.sin(offset) * amplitude,
        start + segment,
        waterLine,
      );
    }
    return path;
  }

  void _drawWaterDepth(
    Canvas canvas,
    Size size,
    double waterLine,
    double waveEnergy,
  ) {
    final depthPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var row = 1; row < 5; row++) {
      final y = waterLine + size.height * (0.08 + row * 0.1);
      final path = Path()..moveTo(size.width * -0.05, y);
      for (var segment = 0; segment < 4; segment++) {
        final left = size.width * (segment * 0.35 - 0.05);
        path.cubicTo(
          left + size.width * 0.08,
          y - 4 * waveEnergy,
          left + size.width * 0.18,
          y + 4 * waveEnergy,
          left + size.width * 0.3,
          y,
        );
      }
      canvas.drawPath(path, depthPaint);
    }
  }

  void _drawSurfaceHighlights(
    Canvas canvas,
    Size size,
    double waterLine,
    double waveEnergy,
  ) {
    final highlight = Paint()
      ..color = colors.accentSoft.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    final path = _surfacePath(
      size,
      waterLine - 2,
      amplitude: 7 * waveEnergy,
      phase: impact * math.pi * 3.5 + 1,
    );
    canvas.drawPath(path, highlight);
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.18 : 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.15,
        waterLine - 4,
        size.width * 0.7,
        size.height * 0.12,
      ),
      math.pi * 1.08,
      math.pi * 0.72,
      false,
      shine,
    );
  }

  void _drawBubbles(Canvas canvas, Size size, double waveEnergy) {
    final bubbles = <(double, double, double)>[
      (0.19, 0.68, 5),
      (0.78, 0.7, 4),
      (0.15, 0.5, 3),
      (0.84, 0.45, 6),
      (0.69, 0.27, 3),
      (0.32, 0.76, 3),
    ];
    for (final (x, y, bubbleRadius) in bubbles) {
      final bubble = Offset(size.width * x, size.height * y);
      final fill = Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.16 : 0.28);
      canvas.drawCircle(bubble, bubbleRadius, fill);
      canvas.drawCircle(
        bubble.translate(-bubbleRadius * 0.28, -bubbleRadius * 0.3),
        bubbleRadius * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.65 + waveEnergy * 0.15),
      );
    }
  }

  void _drawImpact(Canvas canvas, Size size, double waterLine) {
    if (impact <= 0) return;

    if (impact < 0.62) {
      final fall = Curves.easeIn.transform(_clamp01(impact / 0.62));
      final dropCenter = Offset(
        size.width * 0.5,
        size.height * 0.17 + (waterLine - size.height * 0.17) * fall,
      );
      _drawDrop(canvas, dropCenter, size.width * 0.026, opacity: 1);
    }

    final rippleProgress = _clamp01((impact - 0.42) / 0.58);
    if (rippleProgress > 0) {
      final eased = Curves.easeOut.transform(rippleProgress);
      for (var ring = 0; ring < 3; ring++) {
        final ringProgress = _clamp01(eased - ring * 0.1);
        final radius = size.width * (0.045 + ringProgress * (0.3 + ring * 0.06));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, waterLine),
            width: radius * 2.2,
            height: radius * 0.58,
          ),
          Paint()
            ..color = colors.accentSoft.withValues(
              alpha: (1 - ringProgress) * 0.55,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 - ring * 0.35,
        );
      }
    }

    final splashProgress = _clamp01((impact - 0.47) / 0.45);
    if (splashProgress > 0 && splashProgress < 1) {
      final opacity = math.sin(math.pi * splashProgress);
      final droplets = <Offset>[
        const Offset(-0.11, -0.03),
        const Offset(-0.06, -0.1),
        const Offset(0.06, -0.1),
        const Offset(0.11, -0.03),
      ];
      for (final offset in droplets) {
        final dropCenter = Offset(
          size.width * (0.5 + offset.dx * (0.8 + splashProgress)),
          waterLine + size.height * (offset.dy - splashProgress * 0.08),
        );
        _drawDrop(
          canvas,
          dropCenter,
          size.width * 0.014,
          opacity: opacity,
        );
      }
    }
  }

  void _drawDrop(
    Canvas canvas,
    Offset center,
    double dropSize, {
    required double opacity,
  }) {
    final drop = Path()
      ..moveTo(center.dx, center.dy - dropSize * 2.2)
      ..cubicTo(
        center.dx - dropSize * 1.2,
        center.dy - dropSize * 0.55,
        center.dx - dropSize * 1.25,
        center.dy + dropSize * 0.72,
        center.dx,
        center.dy + dropSize,
      )
      ..cubicTo(
        center.dx + dropSize * 1.25,
        center.dy + dropSize * 0.72,
        center.dx + dropSize * 1.2,
        center.dy - dropSize * 0.55,
        center.dx,
        center.dy - dropSize * 2.2,
      )
      ..close();
    final bounds = drop.getBounds();
    canvas.drawPath(
      drop,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: opacity * 0.92),
            colors.accent.withValues(alpha: opacity * 0.9),
            colors.bottom.withValues(alpha: opacity * 0.82),
          ],
        ).createShader(bounds),
    );
    canvas.drawCircle(
      center.translate(-dropSize * 0.35, -dropSize * 0.8),
      dropSize * 0.25,
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.85),
    );
  }

  void _drawGlassRim(
    Canvas canvas,
    Rect circle,
    Offset center,
    double radius,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = SweepGradient(
          colors: isDark
              ? const [Color(0xFF7BD8FF), Color(0xFF0B4F87), Color(0xFFB5EBFF)]
              : const [Color(0xFFFFFFFF), Color(0xFF3BA4D5), Color(0xFFFFFFFF)],
        ).createShader(circle),
    );
    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: isDark ? 0.3 : 0.64),
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.22 : 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(-3, -4), radius: radius - 8),
      math.pi * 1.08,
      math.pi * 0.7,
      false,
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _RealisticWaterPainter oldDelegate) {
    return oldDelegate.impact != impact ||
        oldDelegate.progress != progress ||
        oldDelegate.colors != colors ||
        oldDelegate.isDark != isDark;
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
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.94),
            colors.bottom.withValues(alpha: 0.98),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
          Rect.fromLTWH(0, waterLine, size.width, size.height - waterLine),
        ),
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
      canvas.drawCircle(
        bubble.translate(-1, -1),
        1.3,
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
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
