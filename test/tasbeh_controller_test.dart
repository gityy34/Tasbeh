import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:tasbeh/models/app_models.dart';
import 'package:tasbeh/services/storage_service.dart';
import 'package:tasbeh/state/tasbeh_controller.dart';
import 'package:tasbeh/theme/app_theme.dart';

void main() {
  group('TasbehController', () {
    late MemoryStorageService storage;
    late TasbehController controller;

    setUp(() async {
      storage = MemoryStorageService();
      controller = TasbehController(storage);
      await controller.initialize();
    });

    test('starts at zero with a 100 count target', () {
      expect(controller.isReady, isTrue);
      expect(controller.count, 0);
      expect(controller.target, 100);
      expect(controller.progress, 0);
      expect(controller.isComplete, isFalse);
      expect(controller.settings.vibrateOnTarget, isTrue);
    });

    test('increments, decrements, and persists the count', () async {
      await controller.increment();
      await controller.increment();
      expect(controller.count, 2);
      await controller.decrement();
      expect(controller.count, 1);

      final restored = TasbehController(storage);
      await restored.initialize();
      expect(restored.count, 1);
    });

    test('does not exceed a finite target and reports completion', () async {
      await controller.setTarget(2);
      await controller.increment();
      await controller.increment();
      await controller.increment();

      expect(controller.count, 2);
      expect(controller.progress, 1);
      expect(controller.isComplete, isTrue);
      expect(controller.progressLabel, 'Target complete');
    });

    test('infinity mode has unlimited increments', () async {
      await controller.setTarget(null);
      for (var i = 0; i < 120; i++) {
        await controller.increment();
      }

      expect(controller.count, 120);
      expect(controller.isInfinite, isTrue);
      expect(controller.progressLabel, '∞ mode');
    });

    test('switching target clamps an existing count', () async {
      await controller.setTarget(null);
      for (var i = 0; i < 12; i++) {
        await controller.increment();
      }
      await controller.setTarget(10);

      expect(controller.count, 10);
      expect(controller.target, 10);
    });

    test('saves and restores checkpoints', () async {
      await controller.increment();
      await controller.saveCheckpoint();

      final restored = TasbehController(storage);
      await restored.initialize();
      expect(restored.checkpoints, hasLength(1));
      expect(restored.checkpoints.single.count, 1);
      expect(restored.checkpoints.single.target, 100);
    });

    test('settings changes persist', () async {
      await controller.setThemeMode(AppThemeMode.night);
      await controller.setPalette(CounterPalette.realisticWater);
      await controller.setTextTone(TextTone.cream);
      await controller.setTasbeeh('allahu-akbar');
      await controller.setVibrateOnTarget(false);

      final restored = TasbehController(storage);
      await restored.initialize();
      expect(restored.settings.themeMode, AppThemeMode.night);
      expect(restored.settings.palette, CounterPalette.realisticWater);
      expect(restored.settings.textTone, TextTone.cream);
      expect(restored.selectedTasbeeh.label, 'Allahu Akbar');
      expect(restored.selectedTasbeeh.arabicText, 'ٱللَّهُ أَكْبَرُ');
      expect(restored.settings.vibrateOnTarget, isFalse);
    });

    test('increment reports when the selected target is reached', () async {
      await controller.setTarget(1);
      expect(await controller.increment(), isTrue);
      expect(await controller.increment(), isFalse);
      expect(controller.isComplete, isTrue);
    });

    for (final target in <int>[33, 100, 313, 1000]) {
      test('target $target emits one completion signal per cycle', () async {
        await controller.setTarget(target);
        for (var count = 1; count < target; count++) {
          expect(await controller.increment(), isFalse);
        }
        expect(await controller.increment(), isTrue);
        expect(await controller.increment(), isFalse);
        await controller.decrement();
        expect(await controller.increment(), isFalse);

        await controller.reset();
        for (var count = 1; count < target; count++) {
          await controller.increment();
        }
        expect(await controller.increment(), isTrue);
      });
    }

    test('infinity mode never emits a target completion signal', () async {
      await controller.setTarget(null);
      for (var count = 0; count < 1200; count++) {
        expect(await controller.increment(), isFalse);
      }
    });

    test('switching target starts a separate completion cycle', () async {
      await controller.setTarget(1);
      expect(await controller.increment(), isTrue);
      await controller.setTarget(2);
      expect(await controller.increment(), isTrue);
      expect(await controller.increment(), isFalse);
    });

    test('realistic water theme has a user-facing label', () {
      expect(CounterPalette.realisticWater.label, 'Realistic Water Theme');
    });

    test('reset returns the count to zero and persists it', () async {
      await controller.increment();
      await controller.reset();
      expect(controller.count, 0);

      final restored = TasbehController(storage);
      await restored.initialize();
      expect(restored.count, 0);
    });
  });

  test('auto brightness follows the 6 AM and 5 PM boundaries', () {
    expect(
      effectiveBrightness(AppThemeMode.auto, DateTime(2026, 1, 1, 5, 59)),
      Brightness.dark,
    );
    expect(
      effectiveBrightness(AppThemeMode.auto, DateTime(2026, 1, 1, 6, 0)),
      Brightness.light,
    );
    expect(
      effectiveBrightness(AppThemeMode.auto, DateTime(2026, 1, 1, 16, 59)),
      Brightness.light,
    );
    expect(
      effectiveBrightness(AppThemeMode.auto, DateTime(2026, 1, 1, 17, 0)),
      Brightness.dark,
    );
    expect(
      effectiveBrightness(AppThemeMode.auto, DateTime(2026, 1, 1, 12)),
      Brightness.light,
    );
    expect(
      effectiveBrightness(AppThemeMode.auto, DateTime(2026, 1, 1, 22)),
      Brightness.dark,
    );
    expect(
      effectiveBrightness(AppThemeMode.day, DateTime(2026, 1, 1, 22)),
      Brightness.light,
    );
    expect(
      effectiveBrightness(AppThemeMode.night, DateTime(2026, 1, 1, 12)),
      Brightness.dark,
    );
  });

  test('persisted state survives JSON round-trip', () {
    const state = PersistedState(
      count: 27,
      target: 100,
      settings: TasbehSettings(
        themeMode: AppThemeMode.night,
        tasbeehId: 'subhanallah',
        vibrateOnTarget: false,
      ),
      checkpoints: <TasbehCheckpoint>[],
    );
    final decoded = PersistedState.decode(state.encode());
    expect(decoded.count, 27);
    expect(decoded.target, 100);
    expect(decoded.settings.themeMode, AppThemeMode.night);
    expect(decoded.settings.tasbeehId, 'subhanallah');
    expect(decoded.settings.vibrateOnTarget, isFalse);
  });
}

