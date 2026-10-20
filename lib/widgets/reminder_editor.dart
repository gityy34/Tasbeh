import 'package:flutter/material.dart';

import '../content/tasbeeh_catalog.dart';
import '../models/tasbeh_reminder.dart';

class ReminderEditorResult {
  const ReminderEditorResult({
    required this.title,
    required this.sourceType,
    required this.sourceId,
    required this.sourceLabel,
    required this.arabicText,
    required this.time,
    required this.enabled,
  });

  final String title;
  final ReminderSourceType sourceType;
  final String sourceId;
  final String sourceLabel;
  final String arabicText;
  final TimeOfDay time;
  final bool enabled;
}

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({super.key, this.reminder});

  final TasbehReminder? reminder;

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _customLabelController;
  late final TextEditingController _arabicController;
  late ReminderSourceType _sourceType;
  late String _presetId;
  late TimeOfDay _time;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _sourceType = reminder?.sourceType ?? ReminderSourceType.builtInTasbeeh;
    _presetId = reminder?.sourceType == ReminderSourceType.builtInTasbeeh
        ? reminder!.sourceId
        : defaultTasbeehId;
    _time = TimeOfDay(
      hour: reminder?.hour ?? 8,
      minute: reminder?.minute ?? 0,
    );
    _enabled = reminder?.enabled ?? true;
    _titleController = TextEditingController(
      text: reminder?.title ?? 'Tasbeh Reminder',
    );
    _customLabelController = TextEditingController(
      text: reminder?.sourceType == ReminderSourceType.customDua
          ? reminder?.sourceLabel
          : '',
    );
    _arabicController = TextEditingController(
      text: reminder?.sourceType == ReminderSourceType.customDua
          ? reminder?.arabicText
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customLabelController.dispose();
    _arabicController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Select daily reminder time',
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final preset = tasbeehPresetForId(_presetId);
    final isBuiltIn = _sourceType == ReminderSourceType.builtInTasbeeh;
    Navigator.pop(
      context,
      ReminderEditorResult(
        title: _titleController.text.trim(),
        sourceType: _sourceType,
        sourceId: isBuiltIn ? preset.id : 'custom',
        sourceLabel: isBuiltIn
            ? preset.label
            : _customLabelController.text.trim(),
        arabicText: isBuiltIn
            ? preset.arabicText
            : _arabicController.text.trim(),
        time: _time,
        enabled: _enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = tasbeehPresetForId(_presetId);
    final previewLabel = _sourceType == ReminderSourceType.builtInTasbeeh
        ? selectedPreset.label
        : _customLabelController.text.trim().isEmpty
            ? 'Custom Dua or Tasbeeh'
            : _customLabelController.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              SegmentedButton<ReminderSourceType>(
                segments: const [
                  ButtonSegment(
                    value: ReminderSourceType.builtInTasbeeh,
                    label: Text('Built-in Tasbeeh'),
                    icon: Icon(Icons.auto_awesome_outlined),
                  ),
                  ButtonSegment(
                    value: ReminderSourceType.customDua,
                    label: Text('Saved / Custom Dua'),
                    icon: Icon(Icons.edit_note_rounded),
                  ),
                ],
                selected: {_sourceType},
                onSelectionChanged: (value) {
                  setState(() => _sourceType = value.first);
                },
              ),
              const SizedBox(height: 18),
              if (_sourceType == ReminderSourceType.builtInTasbeeh)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tasbeeh',
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _presetId,
                      isExpanded: true,
                      items: tasbeehPresets
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset.id,
                              child: Text(preset.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _presetId = value);
                      },
                    ),
                  ),
                )
              else ...[
                TextFormField(
                  controller: _customLabelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dua or Tasbeeh name',
                    hintText: 'For example, Morning Dua',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _arabicController,
                  textDirection: TextDirection.rtl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Dua text (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification title',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a notification title'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                minVerticalPadding: 12,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Daily time'),
                subtitle: Text(_time.format(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickTime,
              ),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Reminder enabled'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 12),
              Text(
                'Notification preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    _titleController.text.trim().isEmpty
                        ? 'Tasbeh Reminder'
                        : _titleController.text.trim(),
                  ),
                  subtitle: Text(
                    '$previewLabel — It is time for your Tasbeeh.',
                  ),
                  trailing: Text(_time.format(context)),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
