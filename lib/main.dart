import 'dart:async';

import 'package:flutter/material.dart';

import 'models/app_models.dart';
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

class TasbehApp extends StatefulWidget {
  const TasbehApp({super.key, required this.controller});

  final TasbehController controller;

  @override
  State<TasbehApp> createState() => _TasbehAppState();
}

class _TasbehAppState extends State<TasbehApp>
    with WidgetsBindingObserver {
  Timer? _themeBoundaryTimer;

  TasbehController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_handleControllerChanged);
    _scheduleNextThemeBoundary();
  }

  @override
  void didUpdateWidget(covariant TasbehApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _controller.addListener(_handleControllerChanged);
      _scheduleNextThemeBoundary();
    }
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    _scheduleNextThemeBoundary();
    setState(() {});
  }

  void _scheduleNextThemeBoundary() {
    _themeBoundaryTimer?.cancel();
    if (_controller.settings.themeMode != AppThemeMode.auto) return;

    final now = DateTime.now();
    final todayDayStart = DateTime(
      now.year,
      now.month,
      now.day,
      autoDayStartHour,
    );
    final todayNightStart = DateTime(
      now.year,
      now.month,
      now.day,
      autoNightStartHour,
    );
    final nextBoundary = now.isBefore(todayDayStart)
        ? todayDayStart
        : now.isBefore(todayNightStart)
            ? todayNightStart
            : todayDayStart.add(const Duration(days: 1));
    final delay = nextBoundary.difference(now);
    _themeBoundaryTimer = Timer(
      delay.isNegative || delay == Duration.zero
          ? const Duration(milliseconds: 100)
          : delay,
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleNextThemeBoundary();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _scheduleNextThemeBoundary();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChanged);
    _themeBoundaryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = effectiveBrightness(
      _controller.settings.themeMode,
      DateTime.now(),
    );
    final light = buildTasbehTheme(
      brightness: Brightness.light,
      palette: _controller.settings.palette,
      textTone: _controller.settings.textTone,
    );
    final dark = buildTasbehTheme(
      brightness: Brightness.dark,
      palette: _controller.settings.palette,
      textTone: _controller.settings.textTone,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasbeh Counter',
      theme: light,
      darkTheme: dark,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(controller: _controller),
    );
  }
}

