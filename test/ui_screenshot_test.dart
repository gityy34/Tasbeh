import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tasbeh/models/app_models.dart';
import 'package:tasbeh/screens/history_screen.dart';
import 'package:tasbeh/screens/home_screen.dart';
import 'package:tasbeh/screens/settings_screen.dart';
import 'package:tasbeh/screens/splash_screen.dart';
import 'package:tasbeh/services/storage_service.dart';
import 'package:tasbeh/state/tasbeh_controller.dart';
import 'package:tasbeh/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewport = Size(390, 844);
  final screenshotDirectory = Directory('build/screenshots')..createSync(recursive: true);

  Future<TasbehController> createController() async {
    final controller = TasbehController(MemoryStorageService());
    await controller.initialize();
    return controller;
  }

  Widget frame({required Widget child, required Key key}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTasbehTheme(
        brightness: Brightness.light,
        palette: CounterPalette.water,
        textTone: TextTone.white,
      ),
      home: RepaintBoundary(key: key, child: child),
    );
  }

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Widget child,
    required TasbehController controller,
  }) async {
    final key = ValueKey<String>('screenshot-$name');
    await tester.binding.setSurfaceSize(viewport);
    await tester.pumpWidget(frame(child: child, key: key));
    await tester.pump(const Duration(milliseconds: 250));

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    File('${screenshotDirectory.path}/$name.png').writeAsBytesSync(bytes);
    image.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
  }

  testWidgets('captures the real Tasbeh interfaces', (tester) async {
    final splashController = await createController();
    await capture(
      tester,
      name: '01-splash-open',
      child: SplashScreen(controller: splashController),
      controller: splashController,
    );

    final homeController = await createController();
    for (var index = 0; index < 27; index++) {
      await homeController.increment();
    }
    await capture(
      tester,
      name: '02-home-counter',
      child: HomeScreen(controller: homeController),
      controller: homeController,
    );

    final settingsController = await createController();
    await capture(
      tester,
      name: '03-settings',
      child: SettingsScreen(controller: settingsController),
      controller: settingsController,
    );

    final historyController = await createController();
    for (var index = 0; index < 27; index++) {
      await historyController.increment();
    }
    await historyController.saveCheckpoint();
    await capture(
      tester,
      name: '04-saved-checkpoints',
      child: HistoryScreen(controller: historyController),
      controller: historyController,
    );

    await tester.binding.setSurfaceSize(null);
  });
}
