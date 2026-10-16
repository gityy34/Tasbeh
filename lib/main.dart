import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'state/tasbeh_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TasbehController(PreferencesStorageService());
  await controller.initialize();
  runApp(TasbehApp(controller: controller));
}

class TasbehApp extends StatelessWidget {
  const TasbehApp({super.key, required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final brightness = effectiveBrightness(
          controller.settings.themeMode,
          DateTime.now(),
        );
        final light = buildTasbehTheme(
          brightness: Brightness.light,
          palette: controller.settings.palette,
          textTone: controller.settings.textTone,
        );
        final dark = buildTasbehTheme(
          brightness: Brightness.dark,
          palette: controller.settings.palette,
          textTone: controller.settings.textTone,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tasbeh Counter',
          theme: light,
          darkTheme: dark,
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: SplashScreen(controller: controller),
        );
      },
    );
  }
}

