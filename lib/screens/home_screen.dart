import 'dart:async';

import 'package:flutter/material.dart';

import '../state/tasbeh_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/splash_artwork.dart';
import '../widgets/water_counter.dart';
import '../navigation.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbeh'),
        actions: [
          IconButton(
            tooltip: 'Saved checkpoints',
            onPressed: () => Navigator.of(context).push(
              AppRoute.fade(HistoryScreen(controller: controller)),
            ),
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              AppRoute.fade(SettingsScreen(controller: controller)),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => _HomeContent(controller: controller),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    final counterColors = counterColorsFor(
      controller.settings.palette,
      controller.settings.textTone,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, compact ? 6 : 12, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bismillah',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bismillah,
                              textDirection: TextDirection.rtl,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFamilyFallback: const ['Noto Naskh Arabic', 'Noto Sans Arabic', 'sans'],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(
                        label: controller.isInfinite
                            ? '∞'
                            : '${controller.count}/${controller.target}',
                        icon: controller.isComplete
                            ? Icons.check_circle_outline_rounded
                            : Icons.water_drop_outlined,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 18),
                  SizedBox(
                    width: mathMin(constraints.maxWidth, 430),
                    child: WaterCounter(
                      count: controller.count,
                      target: controller.target,
                      progress: controller.progress,
                      colors: counterColors,
                      palette: controller.settings.palette,
                      isDark: isDark,
                      onTap: () => unawaited(controller.increment()),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 18),
                  _TargetSection(controller: controller),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.count == 0
                              ? null
                              : () => unawaited(controller.decrement()),
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('Minus 1'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _confirmReset(context, controller),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        await controller.saveCheckpoint();
                        if (context.mounted) showMessage(context, 'Checkpoint saved');
                      },
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(
                        controller.checkpoints.isEmpty
                            ? 'Save checkpoint'
                            : 'Save checkpoint  •  ${controller.checkpoints.length} saved',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.progressLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double mathMin(double a, double b) => a < b ? a : b;

  Future<void> _confirmReset(BuildContext context, TasbehController controller) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset counter?'),
        content: const Text('Your current number will return to zero. Save a checkpoint first if you want to keep it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (shouldReset == true) {
      await controller.reset();
      if (context.mounted) showMessage(context, 'Counter reset');
    }
  }
}

class _TargetSection extends StatelessWidget {
  const _TargetSection({required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    const targets = <int?>[33, 50, 100, 1000, null];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: targets.map((target) {
            final selected = controller.target == target;
            final label = target == null ? '∞' : '$target';
            return Semantics(
              selected: selected,
              button: true,
              label: target == null ? 'Infinite target' : 'Target $target',
              child: ChoiceChip(
                label: Text(label),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => unawaited(controller.setTarget(target)),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

