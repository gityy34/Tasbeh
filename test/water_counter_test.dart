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
}
