import 'dart:async';

import 'package:flutter/material.dart';

import '../content/tasbeeh_catalog.dart';
import '../controllers/reminder_controller.dart';
import '../navigation.dart';
import '../services/haptic_service.dart';
import '../state/tasbeh_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/water_counter.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.reminderController,
    this.hapticService = const PlatformTargetHapticService(),
  });

  final TasbehController controller;
  final ReminderController? reminderController;
  final TargetHapticService hapticService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _TasbehCategoryMenu(),
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
              AppRoute.fade(
                SettingsScreen(
                  controller: controller,
                  reminderController: reminderController,
                ),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => _HomeContent(
            controller: controller,
            hapticService: hapticService,
          ),
        ),
      ),
    );
  }
}

class _TasbehCategoryMenu extends StatelessWidget {
  const _TasbehCategoryMenu();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    return PopupMenuButton<String>(
      key: const ValueKey<String>('tasbeh-category-menu'),
      tooltip: 'Open Tasbeh categories',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 8,
      onSelected: (_) {},
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'morning-evening-azkar',
          height: 56,
          child: _AzkarMenuLabel(
            label: 'صبح و شام کے اذکار',
            icon: Icons.wb_twilight_rounded,
            color: color,
          ),
        ),
        PopupMenuItem<String>(
          value: 'daily-azkar',
          height: 56,
          child: _AzkarMenuLabel(
            label: 'روزانہ کے اذکار',
            icon: Icons.calendar_today_rounded,
            color: color,
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: 'Tasbeh categories',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tasbeh',
                style: Theme.of(context).appBarTheme.titleTextStyle ??
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.keyboard_arrow_down_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _AzkarMenuLabel extends StatelessWidget {
  const _AzkarMenuLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: const [
                    'Noto Naskh Arabic',
                    'Noto Sans Arabic',
                    'sans',
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.controller,
    required this.hapticService,
  });

  final TasbehController controller;
  final TargetHapticService hapticService;

  Future<void> _increment() async {
    final reachedTarget = await controller.increment();
    if (reachedTarget && controller.settings.vibrateOnTarget) {
      await hapticService.targetCompleted();
    }
  }

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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _increment,
                child: Column(
                  children: [
                    _TasbeehSelector(controller: controller),
                    SizedBox(height: compact ? 10 : 16),
                    SizedBox(
                      width: mathMin(constraints.maxWidth, 520),
                      child: WaterCounter(
                        count: controller.count,
                        target: controller.target,
                        progress: controller.progress,
                        colors: counterColors,
                        palette: controller.settings.palette,
                        isDark: isDark,
                        onTap: () => unawaited(_increment()),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    _TargetControlsPanel(
                      controller: controller,
                      onReset: () => _confirmReset(context),
                      onSaveCheckpoint: () => _saveCheckpoint(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCheckpoint(BuildContext context) async {
    await controller.saveCheckpoint();
    if (context.mounted) showMessage(context, 'Checkpoint saved');
  }

  Future<void> _confirmReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset counter?'),
        content: const Text(
          'Your current number will return to zero. Save a checkpoint first if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset == true) {
      await controller.reset();
      if (context.mounted) showMessage(context, 'Counter reset');
    }
  }
}

class _TasbeehSelector extends StatelessWidget {
  const _TasbeehSelector({required this.controller});

  final TasbehController controller;

  Future<void> _openPicker(BuildContext context) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.76,
      ),
      showDragHandle: true,
      builder: (context) => _TasbeehPickerSheet(
        selectedId: controller.selectedTasbeeh.id,
      ),
    );
    if (selectedId != null) {
      unawaited(controller.setTasbeeh(selectedId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedTasbeeh;
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Tasbeh Name. Selected ${selected.label}. Open Tasbeeh list.',
      onTap: () => _openPicker(context),
      child: InkWell(
        key: const ValueKey<String>('tasbeeh-selector'),
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tasbeh Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                selected.arabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamilyFallback: const [
                        'Noto Naskh Arabic',
                        'Noto Sans Arabic',
                        'sans',
                      ],
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasbeehPickerSheet extends StatelessWidget {
  const _TasbeehPickerSheet({required this.selectedId});

  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.76;
    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Tasbeh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the remembrance shown above the counter.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: tasbeehPresets.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final preset = tasbeehPresets[index];
                    final selected = preset.id == selectedId;
                    return ListTile(
                      key: ValueKey<String>('tasbeeh-option-${preset.id}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      selected: selected,
                      selectedTileColor:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      title: Text(
                        preset.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        preset.arabicText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamilyFallback: [
                            'Noto Naskh Arabic',
                            'Noto Sans Arabic',
                            'sans',
                          ],
                        ),
                      ),
                      onTap: () => Navigator.pop(context, preset.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetControlsPanel extends StatelessWidget {
  const _TargetControlsPanel({
    required this.controller,
    required this.onReset,
    required this.onSaveCheckpoint,
  });

  final TasbehController controller;
  final VoidCallback onReset;
  final VoidCallback onSaveCheckpoint;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant.withValues(
          alpha: 0.55,
        );
    return Container(
      key: const ValueKey<String>('target-controls-panel'),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: dividerColor),
          bottom: BorderSide(color: dividerColor),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 14),
      child: Column(
        children: [
          _TargetSection(controller: controller),
          const SizedBox(height: 12),
          _HomeActions(
            controller: controller,
            onReset: onReset,
            onSaveCheckpoint: onSaveCheckpoint,
          ),
        ],
      ),
    );
  }
}

class _TargetSection extends StatelessWidget {
  const _TargetSection({required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    const targets = <int?>[33, 100, 313, 1000, null];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final diameter =
                ((constraints.maxWidth - 28) / 5).clamp(48.0, 64.0).toDouble();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: targets.map((target) {
                final selected = controller.target == target;
                final label = target == null ? '∞' : '$target';
                final colorScheme = Theme.of(context).colorScheme;
                return Semantics(
                  selected: selected,
                  button: true,
                  label: target == null ? 'Infinite target' : 'Target $target',
                  child: Material(
                    color: selected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey<String>('target-$label'),
                      customBorder: const CircleBorder(),
                      onTap: () => unawaited(controller.setTarget(target)),
                      child: SizedBox.square(
                        dimension: diameter,
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: selected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({
    required this.controller,
    required this.onReset,
    required this.onSaveCheckpoint,
  });

  final TasbehController controller;
  final VoidCallback onReset;
  final VoidCallback onSaveCheckpoint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundActionButton(
          key: const ValueKey<String>('minus-action'),
          label: 'Decrease count by one',
          icon: Icons.remove_rounded,
          onPressed: controller.count == 0
              ? null
              : () => unawaited(controller.decrement()),
        ),
        const SizedBox(width: 22),
        _RoundActionButton(
          key: const ValueKey<String>('reset-action'),
          label: 'Reset counter',
          icon: Icons.refresh_rounded,
          filled: true,
          onPressed: onReset,
        ),
        const SizedBox(width: 22),
        _RoundActionButton(
          key: const ValueKey<String>('bookmark-action'),
          label: 'Save checkpoint',
          icon: Icons.bookmark_outline_rounded,
          onPressed: onSaveCheckpoint,
        ),
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final foreground = filled
        ? scheme.onPrimary
        : enabled
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.38);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: filled ? scheme.primary : Colors.transparent,
        shape: CircleBorder(
          side: filled
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
        elevation: filled ? 2 : 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 58,
            child: Icon(icon, color: foreground, size: 29),
          ),
        ),
      ),
    );
  }
}

double mathMin(double a, double b) => a < b ? a : b;
