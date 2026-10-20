import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/reminder_controller.dart';
import 'models/app_models.dart';
import 'models/tasbeh_reminder.dart';
import 'repositories/reminder_repository.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'state/tasbeh_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TasbehController(PreferencesStorageService());
  await controller.initialize();
  final reminderController = ReminderController(
    repository: PreferencesReminderRepository(),
    notifications: FlutterLocalNotificationService(),
  );
  await reminderController.initialize();
  runApp(
    TasbehApp(
      controller: controller,
      reminderController: reminderController,
    ),
  );
}

class TasbehApp extends StatefulWidget {
  const TasbehApp({
    super.key,
    required this.controller,
    required this.reminderController,
  });

  final TasbehController controller;
  final ReminderController reminderController;

  @override
  State<TasbehApp> createState() => _TasbehAppState();
}

class _TasbehAppState extends State<TasbehApp>
    with WidgetsBindingObserver {
  Timer? _themeBoundaryTimer;
  final _navigatorKey = GlobalKey<NavigatorState>();

  TasbehController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_handleControllerChanged);
    widget.reminderController.onOpenReminder = _openReminder;
    _scheduleNextThemeBoundary();
    unawaited(widget.reminderController.consumePendingNavigation());
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
      unawaited(widget.reminderController.resyncSchedules());
      setState(() {});
    }
  }

  Future<void> _openReminder(TasbehReminder? reminder) async {
    if (reminder?.sourceType == ReminderSourceType.builtInTasbeeh) {
      await _controller.setTasbeeh(reminder!.sourceId);
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(
          controller: _controller,
          reminderController: widget.reminderController,
        ),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChanged);
    widget.reminderController.onOpenReminder = null;
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
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tasbeh Counter',
      theme: light,
      darkTheme: dark,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(
        controller: _controller,
        reminderController: widget.reminderController,
      ),
    );
  }
}

