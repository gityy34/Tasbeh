import 'dart:convert';

enum AzkarCategory {
  morningEvening,
  daily,
}

extension AzkarCategoryDetails on AzkarCategory {
  String get key => switch (this) {
        AzkarCategory.morningEvening => 'morning-evening',
        AzkarCategory.daily => 'daily',
      };

  String get label => switch (this) {
        AzkarCategory.morningEvening => 'Subah-o-Shaam Azkar',
        AzkarCategory.daily => 'Rozana ke Azkar',
      };

  String get arabicLabel => switch (this) {
        AzkarCategory.morningEvening => 'صبح و شام کے اذکار',
        AzkarCategory.daily => 'روزانہ کے اذکار',
      };
}

AzkarCategory azkarCategoryFromKey(String? key) {
  return AzkarCategory.values.firstWhere(
    (category) => category.key == key,
    orElse: () => AzkarCategory.morningEvening,
  );
}

enum AzkarWeekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

extension AzkarWeekdayDetails on AzkarWeekday {
  int get number => index + 1;

  String get label => switch (this) {
        AzkarWeekday.monday => 'Monday',
        AzkarWeekday.tuesday => 'Tuesday',
        AzkarWeekday.wednesday => 'Wednesday',
        AzkarWeekday.thursday => 'Thursday',
        AzkarWeekday.friday => 'Friday',
        AzkarWeekday.saturday => 'Saturday',
        AzkarWeekday.sunday => 'Sunday',
      };

  String get shortLabel => switch (this) {
        AzkarWeekday.monday => 'Mon',
        AzkarWeekday.tuesday => 'Tue',
        AzkarWeekday.wednesday => 'Wed',
        AzkarWeekday.thursday => 'Thu',
        AzkarWeekday.friday => 'Fri',
        AzkarWeekday.saturday => 'Sat',
        AzkarWeekday.sunday => 'Sun',
      };

  String get arabicLabel => switch (this) {
        AzkarWeekday.monday => 'پیر',
        AzkarWeekday.tuesday => 'منگل',
        AzkarWeekday.wednesday => 'بدھ',
        AzkarWeekday.thursday => 'جمعرات',
        AzkarWeekday.friday => 'جمعہ',
        AzkarWeekday.saturday => 'ہفتہ',
        AzkarWeekday.sunday => 'اتوار',
      };
}

AzkarWeekday azkarWeekdayFromNumber(int? number) {
  final safeNumber = (number ?? 1).clamp(1, 7).toInt();
  return AzkarWeekday.values[safeNumber - 1];
}

class AzkarPdfDocument {
  const AzkarPdfDocument({
    required this.category,
    required this.localPath,
    required this.displayName,
    required this.pageCount,
    required this.savedAt,
  });

  final AzkarCategory category;
  final String localPath;
  final String displayName;
  final int pageCount;
  final DateTime savedAt;

  Map<String, Object?> toJson() => {
        'category': category.key,
        'localPath': localPath,
        'displayName': displayName,
        'pageCount': pageCount,
        'savedAt': savedAt.toIso8601String(),
      };

  factory AzkarPdfDocument.fromJson(Map<String, dynamic> json) {
    return AzkarPdfDocument(
      category: azkarCategoryFromKey(json['category'] as String?),
      localPath: json['localPath'] as String? ?? '',
      displayName: (json['displayName'] as String?)?.trim().isNotEmpty == true
          ? json['displayName'] as String
          : 'Azkar PDF',
      pageCount: (((json['pageCount'] as num?)?.toInt() ?? 0)
          .clamp(0, 10000)
          .toInt()),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AzkarNotificationSettings {
  const AzkarNotificationSettings({
    this.enabled = true,
    this.morningHour = 5,
    this.morningMinute = 0,
    this.eveningHour = 17,
    this.eveningMinute = 0,
  })  : assert(morningHour >= 0 && morningHour <= 23),
        assert(morningMinute >= 0 && morningMinute <= 59),
        assert(eveningHour >= 0 && eveningHour <= 23),
        assert(eveningMinute >= 0 && eveningMinute <= 59);

  final bool enabled;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;

  AzkarNotificationSettings copyWith({
    bool? enabled,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
  }) {
    return AzkarNotificationSettings(
      enabled: enabled ?? this.enabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
    );
  }

  Map<String, Object> toJson() => {
        'enabled': enabled,
        'morningHour': morningHour,
        'morningMinute': morningMinute,
        'eveningHour': eveningHour,
        'eveningMinute': eveningMinute,
      };

  factory AzkarNotificationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AzkarNotificationSettings();
    return AzkarNotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      morningHour: _safeTime(json['morningHour'], 5),
      morningMinute: _safeMinute(json['morningMinute']),
      eveningHour: _safeTime(json['eveningHour'], 17),
      eveningMinute: _safeMinute(json['eveningMinute']),
    );
  }
}

class DailyAzkarEntry {
  const DailyAzkarEntry({
    required this.id,
    required this.text,
    required this.savedAt,
    required this.weekday,
    this.title = '',
    this.notifications = const AzkarNotificationSettings(),
    this.morningNotificationId = 0,
    this.eveningNotificationId = 0,
  })  : assert(weekday >= 1 && weekday <= 7),
        assert(morningNotificationId >= 0),
        assert(eveningNotificationId >= 0);

  final String id;
  final String text;
  final DateTime savedAt;
  final int weekday;
  final String title;
  final AzkarNotificationSettings notifications;
  final int morningNotificationId;
  final int eveningNotificationId;

  String get displayTitle =>
      title.trim().isEmpty ? azkarWeekdayFromNumber(weekday).label : title.trim();

  DailyAzkarEntry copyWith({
    String? text,
    DateTime? savedAt,
    int? weekday,
    String? title,
    AzkarNotificationSettings? notifications,
    int? morningNotificationId,
    int? eveningNotificationId,
  }) {
    return DailyAzkarEntry(
      id: id,
      text: text ?? this.text,
      savedAt: savedAt ?? this.savedAt,
      weekday: weekday ?? this.weekday,
      title: title ?? this.title,
      notifications: notifications ?? this.notifications,
      morningNotificationId:
          morningNotificationId ?? this.morningNotificationId,
      eveningNotificationId:
          eveningNotificationId ?? this.eveningNotificationId,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'savedAt': savedAt.toIso8601String(),
        'weekday': weekday,
        'title': title,
        'notifications': notifications.toJson(),
        'morningNotificationId': morningNotificationId,
        'eveningNotificationId': eveningNotificationId,
      };

  factory DailyAzkarEntry.fromJson(
    Map<String, dynamic> json, {
    int fallbackWeekday = 1,
  }) {
    final safeWeekday =
        ((json['weekday'] as num?)?.toInt() ?? fallbackWeekday)
            .clamp(1, 7)
            .toInt();
    return DailyAzkarEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      weekday: safeWeekday,
      title: json['title'] as String? ?? '',
      notifications: AzkarNotificationSettings.fromJson(
        json['notifications'] as Map<String, dynamic>?,
      ),
      morningNotificationId:
          (json['morningNotificationId'] as num?)?.toInt() ?? 0,
      eveningNotificationId:
          (json['eveningNotificationId'] as num?)?.toInt() ?? 0,
    );
  }
}

class AzkarWeeklyNotification {
  const AzkarWeeklyNotification({
    required this.notificationId,
    required this.entryId,
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  })  : assert(notificationId > 0),
        assert(weekday >= 1 && weekday <= 7),
        assert(hour >= 0 && hour <= 23),
        assert(minute >= 0 && minute <= 59);

  final int notificationId;
  final String entryId;
  final int weekday;
  final int hour;
  final int minute;
  final String title;
  final String body;

  String payload() => jsonEncode(<String, Object>{
        'schemaVersion': 1,
        'notificationType': 'azkar',
        'azkarEntryId': entryId,
        'weekday': weekday,
      });
}

class AzkarLibrary {
  const AzkarLibrary({
    required this.pdfs,
    required this.dailyEntries,
    this.nextNotificationId = firstNotificationId,
  });

  const AzkarLibrary.empty()
      : pdfs = const <AzkarPdfDocument>[],
        dailyEntries = const <DailyAzkarEntry>[],
        nextNotificationId = firstNotificationId;

  static const int schemaVersion = 2;
  static const int firstNotificationId = 20000;

  final List<AzkarPdfDocument> pdfs;
  final List<DailyAzkarEntry> dailyEntries;
  final int nextNotificationId;

  AzkarPdfDocument? pdfFor(AzkarCategory category) {
    for (final pdf in pdfs) {
      if (pdf.category == category) return pdf;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'nextNotificationId': nextNotificationId,
        'pdfs': pdfs.map((pdf) => pdf.toJson()).toList(),
        'dailyEntries': dailyEntries.map((entry) => entry.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory AzkarLibrary.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final storedSchema = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (storedSchema > schemaVersion) {
      throw const FormatException('Unsupported Azkar schema');
    }
    final pdfs = (json['pdfs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AzkarPdfDocument.fromJson)
        .toList(growable: false);
    final rawEntries = json['dailyEntries'] as List<dynamic>? ?? const [];
    final entries = <DailyAzkarEntry>[];
    for (var index = 0; index < rawEntries.length; index++) {
      final raw = rawEntries[index];
      if (raw is! Map<String, dynamic>) continue;
      final entry = DailyAzkarEntry.fromJson(
        raw,
        fallbackWeekday: (index % 7) + 1,
      );
      if (entry.id.isNotEmpty && entry.text.trim().isNotEmpty) {
        entries.add(entry);
      }
    }
    final storedNextId =
        (json['nextNotificationId'] as num?)?.toInt() ?? firstNotificationId;
    final maxId = entries.fold<int>(
      firstNotificationId - 1,
      (max, entry) => [
        max,
        entry.morningNotificationId,
        entry.eveningNotificationId,
      ].reduce((a, b) => a > b ? a : b),
    );
    return AzkarLibrary(
      pdfs: pdfs,
      dailyEntries: List.unmodifiable(entries),
      nextNotificationId: storedNextId > maxId ? storedNextId : maxId + 1,
    );
  }
}

Map<String, dynamic>? decodeAzkarPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['notificationType'] != 'azkar') {
      return null;
    }
    final entryId = decoded['azkarEntryId'] as String?;
    if (entryId == null || entryId.isEmpty) return null;
    return decoded;
  } catch (_) {
    return null;
  }
}

int _safeTime(Object? value, int fallback) {
  final number = value is num ? value.toInt() : fallback;
  return number.clamp(0, 23).toInt();
}

int _safeMinute(Object? value) {
  final number = value is num ? value.toInt() : 0;
  return number.clamp(0, 59).toInt();
}
