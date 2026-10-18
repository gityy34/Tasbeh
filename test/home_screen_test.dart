import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tasbeh/models/app_models.dart';
import 'package:tasbeh/screens/home_screen.dart';
import 'package:tasbeh/services/storage_service.dart';
import 'package:tasbeh/state/tasbeh_controller.dart';
import 'package:tasbeh/theme/app_theme.dart';

void main() {
  testWidgets('Tasbeeh picker updates Arabic text and closes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = TasbehController(MemoryStorageService());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTasbehTheme(
          brightness: Brightness.light,
          palette: CounterPalette.water,
          textTone: TextTone.white,
        ),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Tasbeh Name'), findsOneWidget);
    expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('tasbeeh-selector')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Allahu Akbar'), findsOneWidget);

    final allahuAkbarOption =
        find.byKey(const ValueKey<String>('tasbeeh-option-allahu-akbar'));
    final option = tester.widget<ListTile>(allahuAkbarOption);
    option.onTap!();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('ٱللَّهُ أَكْبَرُ'), findsOneWidget);
    expect(controller.selectedTasbeeh.id, 'allahu-akbar');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
  });

  testWidgets('target controls use the reference target values', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = TasbehController(MemoryStorageService());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTasbehTheme(
          brightness: Brightness.light,
          palette: CounterPalette.water,
          textTone: TextTone.white,
        ),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey<String>('target-33')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('target-100')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('target-313')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('target-1000')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('target-∞')), findsOneWidget);

    final target33 = find.byKey(const ValueKey<String>('target-33'));
    await tester.ensureVisible(target33);
    await tester.tap(target33);
    await tester.pump();
    expect(controller.target, 33);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
  });
}
