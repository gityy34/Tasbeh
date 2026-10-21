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

class DailyAzkarEntry {
  const DailyAzkarEntry({
    required this.id,
    required this.text,
    required this.savedAt,
  });

  final String id;
  final String text;
  final DateTime savedAt;

  DailyAzkarEntry copyWith({String? text, DateTime? savedAt}) {
    return DailyAzkarEntry(
      id: id,
      text: text ?? this.text,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'savedAt': savedAt.toIso8601String(),
      };

  factory DailyAzkarEntry.fromJson(Map<String, dynamic> json) {
    return DailyAzkarEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AzkarLibrary {
  const AzkarLibrary({
    required this.pdfs,
    required this.dailyEntries,
  });

  const AzkarLibrary.empty()
      : pdfs = const <AzkarPdfDocument>[],
        dailyEntries = const <DailyAzkarEntry>[];

  static const schemaVersion = 1;

  final List<AzkarPdfDocument> pdfs;
  final List<DailyAzkarEntry> dailyEntries;

  AzkarPdfDocument? pdfFor(AzkarCategory category) {
    for (final pdf in pdfs) {
      if (pdf.category == category) return pdf;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'pdfs': pdfs.map((pdf) => pdf.toJson()).toList(),
        'dailyEntries': dailyEntries.map((entry) => entry.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory AzkarLibrary.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final pdfs = (json['pdfs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AzkarPdfDocument.fromJson)
        .toList(growable: false);
    final entries = (json['dailyEntries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DailyAzkarEntry.fromJson)
        .where((entry) => entry.id.isNotEmpty && entry.text.trim().isNotEmpty)
        .toList(growable: false);
    return AzkarLibrary(
      pdfs: pdfs,
      dailyEntries: entries,
    );
  }
}
