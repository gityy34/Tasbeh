import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/tasbeh_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final TasbehController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved checkpoints'),
        actions: [
          if (controller.checkpoints.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final checkpoints = controller.checkpoints;
          if (checkpoints.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            itemCount: checkpoints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final checkpoint = checkpoints[index];
              return _CheckpointTile(
                checkpoint: checkpoint,
                onDelete: () => controller.deleteCheckpoint(checkpoint.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear checkpoints?'),
        content: const Text('This removes all saved checkpoints from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (clear == true) await controller.clearHistory();
  }
}

class _CheckpointTile extends StatelessWidget {
  const _CheckpointTile({required this.checkpoint, required this.onDelete});

  final TasbehCheckpoint checkpoint;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final local = checkpoint.createdAt.toLocal();
    final time = MaterialLocalizations.of(context).formatMediumDate(local);
    final clock = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
    );
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.bookmark_rounded),
        ),
        title: Text(
          '${checkpoint.count} of ${checkpoint.targetLabel}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$time  •  $clock'),
        trailing: IconButton(
          tooltip: 'Delete checkpoint',
          icon: const Icon(Icons.close_rounded),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No checkpoints yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Save a moment from the counter to find it here later.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

