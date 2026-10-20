import 'dart:convert';

enum ReminderSourceType { builtInTasbeeh, customDua }

enum ReminderRepeat { daily }

class TasbehReminder {
  const TasbehReminder({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.sourceType,
    required this.sourceId,
    required this.sourceLabel,
    required this.arabicText,
    required this.hour,
    required this.minute,
    this.repeat = ReminderRepeat.daily,
    this.enabled = true,
  }) : assert(hour >= 0 && hour <= 23),
       assert(minute >= 0 && minute <= 59),
       assert(notificationId > 0);

  final String id;
  final int notificationId;
  final String title;
  final ReminderSourceType sourceType;
  final String sourceId;
  final String sourceLabel;
  final String arabicText;
  final int hour;
  final int minute;
  final ReminderRepeat repeat;
  final bool enabled;

  TasbehReminder copyWith({
    String? title,
    ReminderSourceType? sourceType,
    String? sourceId,
    String? sourceLabel,
    String? arabicText,
    int? hour,
    int? minute,
    ReminderRepeat? repeat,
    bool? enabled,
  }) {
    return TasbehReminder(
      id: id,
      notificationId: notificationId,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      arabicText: arabicText ?? this.arabicText,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'notificationId': notificationId,
    'title': title,
    'sourceType': sourceType.name,
    'sourceId': sourceId,
    'sourceLabel': sourceLabel,
    'arabicText': arabicText,
    'hour': hour,
    'minute': minute,
    'repeat': repeat.name,
    'enabled': enabled,
  };

  factory TasbehReminder.fromJson(Map<String, dynamic> json) {
    final hour = (json['hour'] as num?)?.toInt() ?? 8;
    final minute = (json['minute'] as num?)?.toInt() ?? 0;
    final notificationId = (json['notificationId'] as num?)?.toInt() ?? 0;
    if (notificationId <= 0 || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Invalid reminder values');
    }
    return TasbehReminder(
      id: json['id'] as String,
      notificationId: notificationId,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Tasbeh Reminder',
      sourceType: _enumByName(
        ReminderSourceType.values,
        json['sourceType'] as String?,
        ReminderSourceType.builtInTasbeeh,
      ),
      sourceId: json['sourceId'] as String? ?? '',
      sourceLabel: json['sourceLabel'] as String? ?? 'Tasbeeh',
      arabicText: json['arabicText'] as String? ?? '',
      hour: hour,
      minute: minute,
      repeat: _enumByName(
        ReminderRepeat.values,
        json['repeat'] as String?,
        ReminderRepeat.daily,
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  String payload() => jsonEncode(<String, Object>{
    'schemaVersion': 1,
    'reminderId': id,
    'sourceType': sourceType.name,
    'sourceId': sourceId,
  });
}

class ReminderStoreSnapshot {
  const ReminderStoreSnapshot({
    this.schemaVersion = currentSchemaVersion,
    this.masterEnabled = true,
    this.nextNotificationId = firstNotificationId,
    this.reminders = const <TasbehReminder>[],
  });

  static const int currentSchemaVersion = 1;
  static const int firstNotificationId = 10000;

  final int schemaVersion;
  final bool masterEnabled;
  final int nextNotificationId;
  final List<TasbehReminder> reminders;

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'masterEnabled': masterEnabled,
    'nextNotificationId': nextNotificationId,
    'reminders': reminders.map((item) => item.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory ReminderStoreSnapshot.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion > currentSchemaVersion) {
      throw const FormatException('Unsupported reminder schema');
    }
    final reminders = <TasbehReminder>[];
    for (final raw in json['reminders'] as List<dynamic>? ?? const []) {
      try {
        reminders.add(TasbehReminder.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        // Ignore only the damaged row so valid reminders remain available.
      }
    }
    final maxId = reminders.fold<int>(
      firstNotificationId - 1,
      (value, reminder) => reminder.notificationId > value
          ? reminder.notificationId
          : value,
    );
    final storedNext = (json['nextNotificationId'] as num?)?.toInt() ??
        firstNotificationId;
    return ReminderStoreSnapshot(
      schemaVersion: schemaVersion,
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      nextNotificationId: storedNext > maxId ? storedNext : maxId + 1,
      reminders: List.unmodifiable(reminders),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
