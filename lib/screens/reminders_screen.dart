import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/reminder_controller.dart';
import '../models/tasbeh_reminder.dart';
import '../navigation.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_editor.dart';
import '../widgets/reminder_tile.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.controller});

  final ReminderController controller;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  ReminderController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(controller.refreshPermissionStatus());
  }

  Future<void> _setMasterEnabled(bool enabled) async {
    if (enabled) await _explainAndRequestPermissions();
    await controller.setMasterEnabled(enabled);
  }

  Future<void> _explainAndRequestPermissions() async {
    await controller.refreshPermissionStatus();
    if (!mounted) return;
    if (controller.permissionSnapshot.notifications ==
        NotificationPermissionState.denied) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow Tasbeh reminders?'),
          content: const Text(
            'Notifications are needed only to show the daily Tasbeeh or Dua reminders you create. They work locally without an account or internet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (shouldRequest == true) {
        await controller.requestNotificationPermission();
      }
    }
    if (!mounted) return;
    if (controller.permissionSnapshot.exactAlarms == ExactAlarmState.denied) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow exact reminder times?'),
          content: const Text(
            'Android needs exact alarm access to deliver at the selected minute. Without it, reminders still use a safe inexact schedule and Android may delay them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Use fallback'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (shouldRequest == true) {
        await controller.requestExactAlarmPermission();
      }
    }
  }

  Future<void> _addReminder() async {
    await _explainAndRequestPermissions();
    if (!mounted) return;
    final result = await Navigator.of(context).push<ReminderEditorResult>(
      AppRoute.fade(const ReminderEditor()),
    );
    if (result == null) return;
    await controller.createReminder(
      title: result.title,
      sourceType: result.sourceType,
      sourceId: result.sourceId,
      sourceLabel: result.sourceLabel,
      arabicText: result.arabicText,
      hour: result.time.hour,
      minute: result.time.minute,
      enabled: result.enabled,
    );
    if (mounted) showMessage(context, 'Daily reminder saved');
  }

  Future<void> _editReminder(TasbehReminder reminder) async {
    final result = await Navigator.of(context).push<ReminderEditorResult>(
      AppRoute.fade(ReminderEditor(reminder: reminder)),
    );
    if (result == null) return;
    await controller.updateReminder(
      reminder.copyWith(
        title: result.title,
        sourceType: result.sourceType,
        sourceId: result.sourceId,
        sourceLabel: result.sourceLabel,
        arabicText: result.arabicText,
        hour: result.time.hour,
        minute: result.time.minute,
        enabled: result.enabled,
      ),
    );
    if (mounted) showMessage(context, 'Reminder updated');
  }

  Future<void> _deleteReminder(TasbehReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text(
          'The daily reminder for ${reminder.sourceLabel} will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.deleteReminder(reminder.id);
    if (mounted) showMessage(context, 'Reminder deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Add Reminder'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            children: [
              Card(
                child: SwitchListTile.adaptive(
                  key: const ValueKey<String>('reminder-master-switch'),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Enable all reminders'),
                  subtitle: const Text(
                    'Turn this off to cancel every scheduled Tasbeh reminder.',
                  ),
                  value: controller.masterEnabled,
                  onChanged: _setMasterEnabled,
                ),
              ),
              const SizedBox(height: 12),
              _PermissionCard(controller: controller),
              const SizedBox(height: 22),
              Text(
                'Daily reminders',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (controller.reminders.isEmpty)
                _EmptyState(onAdd: _addReminder)
              else
                ...controller.reminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ReminderTile(
                      reminder: reminder,
                      masterEnabled: controller.masterEnabled,
                      onEnabledChanged: (enabled) => unawaited(
                        controller.setReminderEnabled(reminder, enabled),
                      ),
                      onEdit: () => _editReminder(reminder),
                      onDelete: () => _deleteReminder(reminder),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Reminders stay on this device and need no internet. Android battery restrictions or a manual force-stop may delay them; reopening Tasbeh safely resynchronizes enabled reminders.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.controller});

  final ReminderController controller;

  @override
  Widget build(BuildContext context) {
    final notificationDenied = controller.permissionSnapshot.notifications ==
        NotificationPermissionState.denied;
    final exactDenied = controller.permissionSnapshot.exactAlarms ==
        ExactAlarmState.denied;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Android access',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            _PermissionRow(
              label: 'Notifications',
              granted: !notificationDenied,
              deniedText: 'Blocked',
              grantedText: 'Allowed',
            ),
            _PermissionRow(
              label: 'Exact reminder time',
              granted: !exactDenied,
              deniedText: 'Fallback active',
              grantedText: 'Allowed',
            ),
            if (notificationDenied || exactDenied) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (notificationDenied)
                    OutlinedButton.icon(
                      onPressed: () => unawaited(
                        controller.permissions.openNotificationSettings(),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Notification settings'),
                    ),
                  if (exactDenied)
                    OutlinedButton.icon(
                      onPressed: () => unawaited(
                        controller.requestExactAlarmPermission(),
                      ),
                      icon: const Icon(Icons.alarm_rounded),
                      label: const Text('Exact alarm settings'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.deniedText,
    required this.grantedText,
  });

  final String label;
  final bool granted;
  final String deniedText;
  final String grantedText;

  @override
  Widget build(BuildContext context) {
    final color = granted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Semantics(
      label: '$label: ${granted ? grantedText : deniedText}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              granted ? Icons.check_circle_outline : Icons.info_outline,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(
              granted ? grantedText : deniedText,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 46,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'No reminders yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a daily offline reminder for any built-in Tasbeeh or your own saved Dua.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
