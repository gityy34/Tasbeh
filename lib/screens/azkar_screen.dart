import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../controllers/azkar_controller.dart';
import '../models/azkar_models.dart';
import '../navigation.dart';
import '../services/azkar_pdf_service.dart';

class MorningEveningAzkarScreen extends StatefulWidget {
  const MorningEveningAzkarScreen({
    super.key,
    required this.controller,
  });

  final AzkarController controller;

  @override
  State<MorningEveningAzkarScreen> createState() =>
      _MorningEveningAzkarScreenState();
}

class _MorningEveningAzkarScreenState
    extends State<MorningEveningAzkarScreen> {
  Future<void> _upload() async {
    bool uploaded;
    try {
      uploaded = await widget.controller.uploadPdf(
        AzkarCategory.morningEvening,
      );
    } catch (_) {
      if (mounted) {
        showMessage(context, 'The PDF could not be opened. Choose a valid PDF.');
      }
      return;
    }
    if (!mounted) return;
    if (uploaded) showMessage(context, 'PDF saved on this device');
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved PDF?'),
        content: const Text(
          'The local PDF will be removed from this device. You can upload it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.controller.removePdf(AzkarCategory.morningEvening);
      } catch (_) {
        if (mounted) showMessage(context, 'The saved PDF could not be removed');
        return;
      }
      if (mounted) showMessage(context, 'PDF removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final document = widget.controller.pdfFor(
          AzkarCategory.morningEvening,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(AzkarCategory.morningEvening.arabicLabel),
            actions: [
              if (document != null)
                PopupMenuButton<String>(
                  tooltip: 'PDF actions',
                  onSelected: (value) {
                    if (value == 'replace') unawaited(_upload());
                    if (value == 'remove') unawaited(_remove());
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'replace',
                      child: Text('Replace PDF'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove PDF'),
                    ),
                  ],
                ),
            ],
          ),
          body: document == null
              ? _PdfEmptyState(
                  busy: widget.controller.isBusy,
                  onUpload: _upload,
                )
              : AzkarPdfViewer(
                  document: document,
                  service: widget.controller.pdfService,
                ),
        );
      },
    );
  }
}

class _PdfEmptyState extends StatelessWidget {
  const _PdfEmptyState({required this.busy, required this.onUpload});

  final bool busy;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 34,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Add your local Azkar PDF',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a PDF from your phone. It will be copied into Tasbeh storage and will remain available offline.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: busy ? null : onUpload,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(busy ? 'Saving PDF…' : 'Upload PDF'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AzkarPdfViewer extends StatefulWidget {
  const AzkarPdfViewer({
    super.key,
    required this.document,
    required this.service,
  });

  final AzkarPdfDocument document;
  final AzkarPdfService service;

  @override
  State<AzkarPdfViewer> createState() => _AzkarPdfViewerState();
}

class _AzkarPdfViewerState extends State<AzkarPdfViewer> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.document.pageCount.clamp(1, 10000).toInt();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.document.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text('${_page + 1} / $pageCount'),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth.floor().clamp(240, 1800)
                  : 720;
              final renderWidth = width.toInt();
              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: pageCount,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _PdfPage(
                  key: ValueKey<String>(
                    '${widget.document.localPath}-$index-$renderWidth',
                  ),
                  service: widget.service,
                  path: widget.document.localPath,
                  pageIndex: index,
                  maxWidth: renderWidth,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PdfPage extends StatelessWidget {
  const _PdfPage({
    super.key,
    required this.service,
    required this.path,
    required this.pageIndex,
    required this.maxWidth,
  });

  final AzkarPdfService service;
  final String path;
  final int pageIndex;
  final int maxWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: service.renderPage(
        path: path,
        pageIndex: pageIndex,
        maxWidth: maxWidth,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This PDF page could not be displayed. Try replacing the PDF.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          minScale: 0.85,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: Image.memory(
              snapshot.requireData,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Unable to decode this PDF page.'),
              ),
            ),
          ),
        );
      },
    );
  }
}


class DailyAzkarScreen extends StatefulWidget {
  const DailyAzkarScreen({
    super.key,
    required this.controller,
    this.initialWeekday = 1,
  });

  final AzkarController controller;
  final int initialWeekday;

  @override
  State<DailyAzkarScreen> createState() => _DailyAzkarScreenState();
}

class _DailyAzkarScreenState extends State<DailyAzkarScreen> {
  late final TextEditingController _textController;
  late final TextEditingController _titleController;
  late int _weekday;
  bool _editing = false;
  AzkarNotificationSettings _notificationSettings =
      const AzkarNotificationSettings();

  DailyAzkarEntry? get _entry =>
      widget.controller.dailyEntryForWeekday(_weekday);

  @override
  void initState() {
    super.initState();
    _weekday = widget.initialWeekday.clamp(1, 7).toInt();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    _loadCurrentEntry();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    if (!_editing) _loadCurrentEntry();
    setState(() {});
  }

  void _loadCurrentEntry() {
    final entry = _entry;
    final text = entry?.text ?? '';
    final title = entry?.title ?? '';
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _titleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
    _notificationSettings =
        entry?.notifications ?? const AzkarNotificationSettings();
  }

  void _selectWeekday(int weekday) {
    if (_weekday == weekday) return;
    _weekday = weekday;
    _loadCurrentEntry();
    setState(() {});
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      showMessage(context, 'Paste or write Azkar text before saving');
      return;
    }

    if (_notificationSettings.enabled) {
      final granted = await widget.controller.requestNotificationPermission();
      if (!granted && mounted) {
        showMessage(
          context,
          'Notification permission was not granted. You can enable it in Android Settings.',
        );
      }
    }

    await widget.controller.saveDailyEntry(
      id: _entry?.id,
      weekday: _weekday,
      text: text,
      title: _titleController.text.trim(),
      notifications: _notificationSettings,
    );
    if (!mounted) return;
    _editing = false;
    _loadCurrentEntry();
    setState(() {});
    showMessage(context, 'Azkar saved for ' + azkarWeekdayFromNumber(_weekday).label);
  }

  void _cancelEditing() {
    _loadCurrentEntry();
    setState(() => _editing = false);
  }

  Future<void> _openNotificationSettings() async {
    final updated = await showModalBottomSheet<AzkarNotificationSettings>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var draft = _notificationSettings;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final morning = TimeOfDay(
              hour: draft.morningHour,
              minute: draft.morningMinute,
            );
            final evening = TimeOfDay(
              hour: draft.eveningHour,
              minute: draft.eveningMinute,
            );

            Future<void> pickMorning() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: morning,
              );
              if (picked == null) return;
              setModalState(() {
                draft = draft.copyWith(
                  morningHour: picked.hour,
                  morningMinute: picked.minute,
                );
              });
            }

            Future<void> pickEvening() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: evening,
              );
              if (picked == null) return;
              setModalState(() {
                draft = draft.copyWith(
                  eveningHour: picked.hour,
                  eveningMinute: picked.minute,
                );
              });
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Push Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This schedule repeats every week on the selected weekday and works offline.',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable weekly notifications'),
                      subtitle: const Text('Two reminders: morning and evening'),
                      value: draft.enabled,
                      onChanged: (value) => setModalState(
                        () => draft = draft.copyWith(enabled: value),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Morning notification'),
                      subtitle: const Text('Default: 5:00 AM'),
                      trailing: OutlinedButton(
                        onPressed: pickMorning,
                        child: Text(_formatTime(context, morning)),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Evening notification'),
                      subtitle: const Text('Default: 5:00 PM'),
                      trailing: OutlinedButton(
                        onPressed: pickEvening,
                        child: Text(_formatTime(context, evening)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(draft),
                      child: const Text('Save notification settings'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (updated != null && mounted) {
      setState(() => _notificationSettings = updated);
    }
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  Future<void> _move(int amount) async {
    if (_editing) {
      final text = _textController.text.trim();
      if (text.isEmpty) {
        showMessage(context, 'Save text before moving to another day');
        return;
      }
      await _save();
      if (!mounted) return;
    }
    final next = (_weekday + amount).clamp(1, 7).toInt();
    if (next == _weekday) return;
    _selectWeekday(next);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final entry = _entry;
        final weekday = azkarWeekdayFromNumber(_weekday);
        final displayTitle = entry?.displayTitle ?? weekday.label;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rozana ke Azkar'),
            actions: [
              IconButton(
                key: const ValueKey<String>('daily-azkar-edit'),
                tooltip: _editing ? 'Cancel editing' : 'Edit Azkar',
                onPressed: () => _editing
                    ? _cancelEditing()
                    : setState(() {
                        _editing = true;
                        _loadCurrentEntry();
                      }),
                icon: Icon(
                  _editing ? Icons.close_rounded : Icons.edit_outlined,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DailyAzkarHeader(
                            weekday: weekday,
                            title: displayTitle,
                          ),
                          const SizedBox(height: 14),
                          if (_editing)
                            _DailyAzkarEditor(
                              weekday: _weekday,
                              titleController: _titleController,
                              textController: _textController,
                              notificationSettings: _notificationSettings,
                              compact: constraints.maxHeight < 700,
                              onWeekdayChanged: _selectWeekday,
                              onNotificationSettings: _openNotificationSettings,
                              onSave: () => unawaited(_save()),
                            )
                          else
                            _DailyAzkarReadOnly(
                              text: entry?.text ?? '',
                              weekday: weekday,
                            ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _PageArrowButton(
                                key: const ValueKey<String>('daily-azkar-back'),
                                icon: Icons.arrow_back_rounded,
                                label: 'Previous weekday Azkar',
                                enabled: _weekday > 1,
                                onPressed: () => unawaited(_move(-1)),
                              ),
                              Text(
                                weekday.shortLabel,
                                key: const ValueKey<String>(
                                  'daily-azkar-weekday',
                                ),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              _PageArrowButton(
                                key: const ValueKey<String>('daily-azkar-next'),
                                icon: Icons.arrow_forward_rounded,
                                label: 'Next weekday Azkar',
                                enabled: _weekday < 7,
                                onPressed: () => unawaited(_move(1)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            weekday.arabicLabel,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DailyAzkarHeader extends StatelessWidget {
  const _DailyAzkarHeader({
    required this.weekday,
    required this.title,
  });

  final AzkarWeekday weekday;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey<String>('daily-azkar-header'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.menu_book_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(weekday.label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyAzkarReadOnly extends StatelessWidget {
  const _DailyAzkarReadOnly({
    required this.text,
    required this.weekday,
  });

  final String text;
  final AzkarWeekday weekday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = text.trim().isNotEmpty;
    return Card(
      key: const ValueKey<String>('daily-azkar-read-only'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 260),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.topRight,
        child: hasText
            ? SelectableText(
                text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  height: 1.85,
                  fontFamilyFallback: [
                    'Noto Naskh Arabic',
                    'Noto Sans Arabic',
                    'sans',
                  ],
                ),
              )
            : Center(
                child: Text(
                  'No Azkar saved for ' + weekday.label + ' yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
      ),
    );
  }
}

class _DailyAzkarEditor extends StatelessWidget {
  const _DailyAzkarEditor({
    required this.weekday,
    required this.titleController,
    required this.textController,
    required this.notificationSettings,
    required this.compact,
    required this.onWeekdayChanged,
    required this.onNotificationSettings,
    required this.onSave,
  });

  final int weekday;
  final TextEditingController titleController;
  final TextEditingController textController;
  final AzkarNotificationSettings notificationSettings;
  final bool compact;
  final ValueChanged<int> onWeekdayChanged;
  final VoidCallback onNotificationSettings;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final weekdays = AzkarWeekday.values;
    return Column(
      key: const ValueKey<String>('daily-azkar-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          key: const ValueKey<String>('daily-azkar-weekday'),
          value: weekday,
          decoration: const InputDecoration(
            labelText: 'Repeat weekday',
            prefixIcon: Icon(Icons.event_repeat_outlined),
          ),
          items: [
            for (final item in weekdays)
              DropdownMenuItem<int>(
                value: item.number,
                child: Text(item.label + ' (' + item.arabicLabel + ')'),
              ),
          ],
          onChanged: (value) {
            if (value != null) onWeekdayChanged(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey<String>('daily-azkar-title'),
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Day or Azkar name',
            prefixIcon: Icon(Icons.label_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey<String>('daily-azkar-text-input'),
          controller: textController,
          minLines: compact ? 8 : 13,
          maxLines: 24,
          keyboardType: TextInputType.multiline,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            labelText: 'Azkar text',
            hintText: 'Paste or write the Azkar text here',
            alignLabelWithHint: true,
          ),
          style: const TextStyle(
            height: 1.8,
            fontFamilyFallback: [
              'Noto Naskh Arabic',
              'Noto Sans Arabic',
              'sans',
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey<String>('daily-azkar-notifications'),
          onPressed: onNotificationSettings,
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(
            notificationSettings.enabled
                ? 'Push notifications: ' +
                    _timeLabel(context, notificationSettings)
                : 'Push notifications: Off',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey<String>('daily-azkar-save'),
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }

  String _timeLabel(
    BuildContext context,
    AzkarNotificationSettings settings,
  ) {
    final localizations = MaterialLocalizations.of(context);
    final morning = localizations.formatTimeOfDay(
      TimeOfDay(hour: settings.morningHour, minute: settings.morningMinute),
    );
    final evening = localizations.formatTimeOfDay(
      TimeOfDay(hour: settings.eveningHour, minute: settings.eveningMinute),
    );
    return morning + ' / ' + evening;
  }
}

class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 56,
            child: Icon(
              icon,
              color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
