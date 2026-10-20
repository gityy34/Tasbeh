import 'package:flutter/material.dart';

import '../models/tasbeh_reminder.dart';

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.masterEnabled,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final TasbehReminder reminder;
  final bool masterEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute)
        .format(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(reminder.sourceLabel),
                  if (reminder.arabicText.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      reminder.arabicText,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamilyFallback: [
                          'Noto Naskh Arabic',
                          'Noto Sans Arabic',
                          'sans',
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(icon: Icons.schedule_rounded, label: time),
                      const _InfoChip(
                        icon: Icons.repeat_rounded,
                        label: 'Daily',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Semantics(
                  label: '${reminder.title} reminder enabled',
                  child: Switch.adaptive(
                    value: reminder.enabled,
                    onChanged: masterEnabled ? onEnabledChanged : null,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit ${reminder.title}',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete ${reminder.title}',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}
