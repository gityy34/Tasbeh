import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tasbeh/models/app_models.dart';
import 'package:tasbeh/screens/home_screen.dart';
import 'package:tasbeh/screens/settings_screen.dart';
import 'package:tasbeh/services/haptic_service.dart';
import 'package:tasbeh/services/storage_service.dart';
import 'package:tasbeh/state/tasbeh_controller.dart';
import 'package:tasbeh/theme/app_theme.dart';
import 'package:tasbeh/widgets/water_counter.dart';

void main() {
  testWidgets('Tasbeh title opens the two Azkar categories', (tester) async {
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('tasbeh-category-menu')));
    await tester.pump();

    expect(find.text('صبح و شام کے اذکار'), findsOneWidget);
    expect(find.text('روزانہ کے اذکار'), findsOneWidget);

    await tester.tapAt(const Offset(350, 760));
    await tester.pump();
    expect(find.text('صبح و شام کے اذکار'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
  });

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
    expect(find.text('of 100'), findsNothing);
    expect(find.text('1% complete'), findsNothing);
    expect(find.byKey(const ValueKey<String>('target-controls-panel')), findsOneWidget);

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

  testWidgets('target completion vibration can be switched off', (tester) async {
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
        home: SettingsScreen(controller: controller),
      ),
    );
    await tester.pump();

    final vibrationSwitch =
        find.byKey(const ValueKey<String>('target-vibration-switch'));
    expect(controller.settings.vibrateOnTarget, isTrue);
    await tester.tap(vibrationSwitch);
    await tester.pump();
    expect(controller.settings.vibrateOnTarget, isFalse);

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

  testWidgets('target completion haptic fires once and resets by cycle',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = TasbehController(MemoryStorageService());
    final haptics = FakeTargetHapticService();
    await controller.initialize();
    await controller.setTarget(1);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTasbehTheme(
          brightness: Brightness.light,
          palette: CounterPalette.water,
          textTone: TextTone.white,
        ),
        home: HomeScreen(
          controller: controller,
          hapticService: haptics,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(WaterCounter));
    await tester.pump();
    expect(haptics.calls, 1);

    await tester.tap(find.byType(WaterCounter));
    await tester.pump();
    expect(haptics.calls, 1);

    await controller.reset();
    await tester.tap(find.byType(WaterCounter));
    await tester.pump();
    expect(haptics.calls, 2);

    await controller.reset();
    await controller.setVibrateOnTarget(false);
    await tester.tap(find.byType(WaterCounter));
    await tester.pump();
    expect(haptics.calls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

class FakeTargetHapticService implements TargetHapticService {
  int calls = 0;

  @override
  Future<void> targetCompleted() async {
    calls += 1;
  }
}
