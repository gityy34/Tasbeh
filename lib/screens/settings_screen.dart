import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/tasbeh_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            _SectionTitle(title: 'Day / night'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<AppThemeMode>(
                      segments: AppThemeMode.values
                          .map(
                            (mode) => ButtonSegment<AppThemeMode>(
                              value: mode,
                              label: Text(mode.label),
                              icon: Icon(_themeIcon(mode)),
                            ),
                          )
                          .toList(),
                      selected: {controller.settings.themeMode},
                      onSelectionChanged: (selection) {
                        final mode = selection.isEmpty ? null : selection.first;
                        if (mode != null) unawaited(controller.setThemeMode(mode));
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Auto: Day 06:00–16:59 · Night 17:00–05:59',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Counter theme'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: RadioGroup<CounterPalette>(
                  groupValue: controller.settings.palette,
                  onChanged: (value) {
                    if (value != null) unawaited(controller.setPalette(value));
                  },
                  child: Column(
                    children: CounterPalette.values
                        .map(
                          (palette) => RadioListTile<CounterPalette>(
                            value: palette,
                            title: Text(palette.label),
                            secondary: _PaletteSwatch(palette: palette),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Counter text'),
            Card(
              child: RadioGroup<TextTone>(
                groupValue: controller.settings.textTone,
                onChanged: (value) {
                  if (value != null) unawaited(controller.setTextTone(value));
                },
                child: Column(
                  children: TextTone.values
                      .map(
                        (tone) => RadioListTile<TextTone>(
                          value: tone,
                          title: Text(tone.label),
                          secondary: _TextSwatch(tone: tone),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Your count, settings, and checkpoints stay on this device. No account or network connection is required.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _themeIcon(AppThemeMode mode) => switch (mode) {
        AppThemeMode.auto => Icons.brightness_auto_rounded,
        AppThemeMode.day => Icons.wb_sunny_outlined,
        AppThemeMode.night => Icons.nightlight_outlined,
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.palette});

  final CounterPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = switch (palette) {
      CounterPalette.water => const [Color(0xFF6DD5FA), Color(0xFF0878D1)],
      CounterPalette.realisticWater => const [Color(0xFFD9F8FF), Color(0xFF0878D1)],
      CounterPalette.nature => const [Color(0xFF8FD694), Color(0xFF237A57)],
      CounterPalette.sunrise => const [Color(0xFFFFD89B), Color(0xFFCE7A35)],
      CounterPalette.midnight => const [Color(0xFF304E75), Color(0xFF071C3A)],
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class _TextSwatch extends StatelessWidget {
  const _TextSwatch({required this.tone});

  final TextTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      TextTone.white => Colors.white,
      TextTone.navy => const Color(0xFF102A43),
      TextTone.cream => const Color(0xFFFFF3D6),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: const [BoxShadow(blurRadius: 5, color: Color(0x22000000))],
      ),
    );
  }
}

