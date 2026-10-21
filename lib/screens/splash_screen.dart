import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/azkar_controller.dart';
import '../controllers/reminder_controller.dart';
import '../navigation.dart';
import '../state/tasbeh_controller.dart';
import '../widgets/splash_artwork.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.controller,
    this.reminderController,
    this.azkarController,
  });

  final TasbehController controller;
  final ReminderController? reminderController;
  final AzkarController? azkarController;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1700), _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppRoute.fade(
        HomeScreen(
          controller: widget.controller,
          reminderController: widget.reminderController,
          azkarController: widget.azkarController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(body: SplashArtwork(isNight: isNight));
  }
}

