import 'package:flutter/foundation.dart';

import '../content/tasbeeh_catalog.dart';
import '../models/azkar_models.dart';
import '../models/tasbeh_reminder.dart';
import '../repositories/azkar_repository.dart';
import '../services/azkar_pdf_service.dart';
import '../services/notification_service.dart';

typedef AzkarOpenCallback = Future<void> Function(DailyAzkarEntry entry);

class AzkarController extends ChangeNotifier {
  AzkarController({
    required AzkarRepository repository,
    required AzkarPdfService pdfService,
    NotificationService? notifications,
  })  : _repository = repository,
        _pdfService = pdfService,
        _notifications = notifications;

  final AzkarRepository _repository;
  final AzkarPdfService _pdfService;
  final NotificationService? _notifications;

  AzkarLibrary _library = const AzkarLibrary.empty();
  bool _initialized = false;
  bool _busy = false;
  String? _pendingPayload;

  AzkarOpenCallback? onOpenEntry;

  AzkarLibrary get library => _library;
  List<AzkarPdfDocument> get pdfs => List.unmodifiable(_library.pdfs);
  List<DailyAzkarEntry> get dailyEntries =>
      List.unmodifiable(_library.dailyEntries);
  bool get isBusy => _busy;
  AzkarPdfService get pdfService => _pdfService;

  DailyAzkarEntry? dailyEntryForWeekday(int weekday) {
    final safeWeekday = weekday.clamp(1, 7).toInt();
    for (final entry in _library.dailyEntries) {
      if (entry.weekday == safeWeekday) return entry;
    }
    return null;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _library = await _repository.read();
    _initialized = true;
    notifyListeners();
    await resyncSchedules();
  }

  AzkarPdfDocument? pdfFor(AzkarCategory category) => _library.pdfFor(category);

  Future<bool> uploadPdf(AzkarCategory category) async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      final picked = await _pdfService.pickAndStore(category);
      if (picked == null) return false;
      final previous = _library.pdfFor(category);
      final document = AzkarPdfDocument(
        category: category,
        localPath: picked.path,
        displayName: picked.displayName,
        pageCount: picked.pageCount,
        savedAt: DateTime.now(),
      );
      final pdfs = [
        for (final pdf in _library.pdfs)
          if (pdf.category != category) pdf,
        document,
      ];
      _library = AzkarLibrary(
        pdfs: pdfs,
        dailyEntries: _library.dailyEntries,
        nextNotificationId: _library.nextNotificationId,
      );
      await _repository.write(_library);
      if (previous != null && previous.localPath != document.localPath) {
        await _pdfService.delete(previous.localPath);
      }
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> removePdf(AzkarCategory category) async {
    final document = _library.pdfFor(category);
    if (document == null) return;
    _library = AzkarLibrary(
      pdfs: _library.pdfs
          .where((pdf) => pdf.category != category)
          .toList(growable: false),
      dailyEntries: _library.dailyEntries,
      nextNotificationId: _library.nextNotificationId,
    );
    await _repository.write(_library);
    await _pdfService.delete(document.localPath);
    notifyListeners();
  }

  Future<void> saveDailyEntry({
    String? id,
    required String text,
    int? weekday,
    String? title,
    AzkarNotificationSettings? notifications,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    final now = DateTime.now();
    final existingIndex = _findEntryIndex(id: id, weekday: weekday);
    final existing = existingIndex < 0
        ? null
        : _library.dailyEntries[existingIndex];
    final entryId = existing?.id ?? id ?? 'azkar-${now.microsecondsSinceEpoch}';
    final safeWeekday = weekday ??
        existing?.weekday ??
        _firstAvailableWeekday(_library.dailyEntries);
    final ids = _notificationIdsFor(existing);
    final nextNotificationId = ids.nextId;
    final entry = DailyAzkarEntry(
      id: entryId,
      text: cleaned,
      savedAt: now,
      weekday: safeWeekday,
      title: title ?? existing?.title ?? '',
      notifications: notifications ?? existing?.notifications ??
          const AzkarNotificationSettings(),
      morningNotificationId: ids.morning,
      eveningNotificationId: ids.evening,
    );

    final entries = [..._library.dailyEntries];
    if (existingIndex < 0) {
      entries.add(entry);
    } else {
      entries[existingIndex] = entry;
    }
    _library = AzkarLibrary(
      pdfs: _library.pdfs,
      dailyEntries: entries,
      nextNotificationId: nextNotificationId,
    );
    await _repository.write(_library);
    await resyncSchedules();
    notifyListeners();
  }

  Future<void> deleteDailyEntry(String id) async {
    DailyAzkarEntry? entry;
    for (final item in _library.dailyEntries) {
      if (item.id == id) {
        entry = item;
        break;
      }
    }
    if (entry == null) return;
    if (_notifications != null) {
      await _notifications.cancel(entry.morningNotificationId);
      await _notifications.cancel(entry.eveningNotificationId);
    }
    _library = AzkarLibrary(
      pdfs: _library.pdfs,
      dailyEntries: _library.dailyEntries
          .where((item) => item.id != id)
          .toList(growable: false),
      nextNotificationId: _library.nextNotificationId,
    );
    await _repository.write(_library);
    await resyncSchedules();
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final service = _notifications;
    if (service == null) return true;
    return service.requestNotificationPermission();
  }

  Future<void> resyncSchedules() async {
    final service = _notifications;
    if (!_initialized || service == null) return;

    final expected = <int>{};
    for (final entry in _library.dailyEntries) {
      if (entry.text.trim().isEmpty || !entry.notifications.enabled) continue;
      expected
        ..add(entry.morningNotificationId)
        ..add(entry.eveningNotificationId);
    }
    final pending = await service.pendingNotificationIds();
    for (final id in pending) {
      if (id >= AzkarLibrary.firstNotificationId && !expected.contains(id)) {
        await service.cancel(id);
      }
    }

    for (final entry in _library.dailyEntries) {
      if (entry.text.trim().isEmpty || !entry.notifications.enabled) continue;
      final title = 'Tasbeh - ' + entry.displayTitle;
      await service.scheduleWeekly(
        AzkarWeeklyNotification(
          notificationId: entry.morningNotificationId,
          entryId: entry.id,
          weekday: entry.weekday,
          hour: entry.notifications.morningHour,
          minute: entry.notifications.morningMinute,
          title: title,
          body: 'Morning Azkar reminder - it is time for your Azkar.',
        ),
      );
      await service.scheduleWeekly(
        AzkarWeeklyNotification(
          notificationId: entry.eveningNotificationId,
          entryId: entry.id,
          weekday: entry.weekday,
          hour: entry.notifications.eveningHour,
          minute: entry.notifications.eveningMinute,
          title: title,
          body: 'Evening Azkar reminder - it is time for your Azkar.',
        ),
      );
    }
  }

  Future<void> handleNotificationPayload(String payload) async {
    final decoded = decodeAzkarPayload(payload);
    if (decoded == null) return;
    final entryId = decoded['azkarEntryId'] as String?;
    DailyAzkarEntry? entry;
    for (final item in _library.dailyEntries) {
      if (item.id == entryId) {
        entry = item;
        break;
      }
    }
    if (entry == null) return;
    final callback = onOpenEntry;
    if (callback == null) {
      _pendingPayload = payload;
      return;
    }
    await callback(entry);
  }

  Future<void> consumePendingNavigation() async {
    final payload = _pendingPayload;
    _pendingPayload = null;
    if (payload != null) await handleNotificationPayload(payload);
  }

  int _findEntryIndex({String? id, int? weekday}) {
    if (id != null) {
      return _library.dailyEntries.indexWhere((entry) => entry.id == id);
    }
    if (weekday != null) {
      return _library.dailyEntries.indexWhere(
        (entry) => entry.weekday == weekday,
      );
    }
    return -1;
  }

  int _firstAvailableWeekday(List<DailyAzkarEntry> entries) {
    final used = entries.map((entry) => entry.weekday).toSet();
    for (var weekday = 1; weekday <= 7; weekday++) {
      if (!used.contains(weekday)) return weekday;
    }
    return 1;
  }

  _AzkarNotificationIds _notificationIdsFor(DailyAzkarEntry? existing) {
    var next = _library.nextNotificationId;
    var morning = existing?.morningNotificationId ?? 0;
    var evening = existing?.eveningNotificationId ?? 0;
    if (morning <= 0) {
      morning = next++;
    }
    if (evening <= 0 || evening == morning) {
      evening = next++;
    }
    return _AzkarNotificationIds(
      morning: morning,
      evening: evening,
      nextId: next,
    );
  }
}

class _AzkarNotificationIds {
  const _AzkarNotificationIds({
    required this.morning,
    required this.evening,
    required this.nextId,
  });

  final int morning;
  final int evening;
  final int nextId;
}

TasbehReminderDraft builtInReminderDraft(String tasbeehId) {
  final preset = tasbeehPresetForId(tasbeehId);
  return TasbehReminderDraft(
    sourceType: ReminderSourceType.builtInTasbeeh,
    sourceId: preset.id,
    sourceLabel: preset.label,
    arabicText: preset.arabicText,
  );
}

class TasbehReminderDraft {
  const TasbehReminderDraft({
    required this.sourceType,
    required this.sourceId,
    required this.sourceLabel,
    required this.arabicText,
  });

  final ReminderSourceType sourceType;
  final String sourceId;
  final String sourceLabel;
  final String arabicText;
}
