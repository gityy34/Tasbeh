import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tasbeh/models/app_models.dart';
import 'package:tasbeh/theme/app_theme.dart';
import 'package:tasbeh/widgets/water_counter.dart';

void main() {
  testWidgets('realistic water responds to a tap and settles', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 320,
              child: WaterCounter(
                count: 0,
                target: 100,
                progress: 0,
                colors: counterColorsFor(
                  CounterPalette.realisticWater,
                  TextTone.white,
                ),
                palette: CounterPalette.realisticWater,
                isDark: false,
                onTap: () => tapCount += 1,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byType(WaterCounter));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tapCount, 1);

    await tester.pump(const Duration(milliseconds: 1800));
  });

  testWidgets('rapid taps are accepted while drops are still animating',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 320,
              child: WaterCounter(
                count: 0,
                target: null,
                progress: 0,
                colors: counterColorsFor(
                  CounterPalette.realisticWater,
                  TextTone.white,
                ),
                palette: CounterPalette.realisticWater,
                isDark: false,
                onTap: () => tapCount += 1,
              ),
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < 12; index++) {
      await tester.tap(find.byType(WaterCounter));
      await tester.pump(const Duration(milliseconds: 45));
    }
    expect(tapCount, 12);

    // Let every falling drop and its final ripple settle naturally.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('golden and red fish thresholds remain stable through 50 taps',
      (tester) async {
    final count = ValueNotifier(0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: count,
            builder: (context, value, child) => Center(
              child: SizedBox.square(
                dimension: 320,
                child: WaterCounter(
                  count: value,
                  target: null,
                  progress: 0,
                  colors: counterColorsFor(
                    CounterPalette.realisticWater,
                    TextTone.white,
                  ),
                  palette: CounterPalette.realisticWater,
                  isDark: false,
                  onTap: () => count.value += 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < 50; index++) {
      await tester.tap(find.byType(WaterCounter));
      await tester.pump(const Duration(milliseconds: 35));
    }
    expect(count.value, 50);
    expect(find.text('50'), findsOneWidget);

    // Fish keep moving, but their growth is capped at the 50-tap size.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
  });
}
