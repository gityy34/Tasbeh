import 'package:flutter/foundation.dart';

import '../content/tasbeeh_catalog.dart';
import '../models/tasbeh_reminder.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_permission_service.dart';
import '../services/notification_service.dart';

typedef ReminderOpenCallback = Future<void> Function(TasbehReminder? reminder);

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepository repository,
    required NotificationService notifications,
  })  : _repository = repository,
        _notifications = notifications,
        permissions = NotificationPermissionService(notifications);

  final ReminderRepository _repository;
  final NotificationService _notifications;
  final NotificationPermissionService permissions;
  Future<void> _writeQueue = Future<void>.value();
  List<TasbehReminder> _reminders = const [];
  bool _masterEnabled = true;
  int _nextNotificationId = ReminderStoreSnapshot.firstNotificationId;
  bool _ready = false;
  ReminderPermissionSnapshot _permissionSnapshot =
      const ReminderPermissionSnapshot(
    notifications: NotificationPermissionState.unavailable,
    exactAlarms: ExactAlarmState.unavailable,
  );
  ReminderOpenCallback? onOpenReminder;
  String? _pendingPayload;

  bool get isReady => _ready;
  bool get masterEnabled => _masterEnabled;
  List<TasbehReminder> get reminders => List.unmodifiable(_reminders);
  ReminderPermissionSnapshot get permissionSnapshot => _permissionSnapshot;

  Future<void> initialize() async {
    if (_ready) return;
    await _notifications.initialize(onNotificationTap: handlePayload);
    final snapshot = await _repository.read();
    _masterEnabled = snapshot.masterEnabled;
    _nextNotificationId = snapshot.nextNotificationId;
    _reminders = List.unmodifiable(snapshot.reminders);
    _permissionSnapshot = await permissions.status();
    _ready = true;
    final launchPayload = _notifications.takeInitialPayload();
    if (launchPayload != null) _pendingPayload = launchPayload;
    await resyncSchedules();
  }

  Future<void> refreshPermissionStatus() async {
    _permissionSnapshot = await permissions.status();
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await permissions.requestNotifications();
    await refreshPermissionStatus();
    if (granted) await resyncSchedules();
    return granted;
  }

  Future<bool> requestExactAlarmPermission() async {
    final granted = await permissions.requestExactAlarms();
    await refreshPermissionStatus();
    await resyncSchedules();
    return granted;
  }

  Future<void> setMasterEnabled(bool enabled) async {
    if (_masterEnabled == enabled) return;
    _masterEnabled = enabled;
    notifyListeners();
    await _persist();
    if (enabled) {
      await resyncSchedules();
    } else {
      await Future.wait(
        _reminders.map(
          (reminder) => _notifications.cancel(reminder.notificationId),
        ),
      );
    }
  }

  Future<TasbehReminder> createReminder({
    required String title,
    required ReminderSourceType sourceType,
    required String sourceId,
    required String sourceLabel,
    required String arabicText,
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    final notificationId = _allocateNotificationId();
    final reminder = TasbehReminder(
      id: 'reminder-$notificationId',
      notificationId: notificationId,
      title: title.trim().isEmpty ? 'Tasbeh Reminder' : title.trim(),
      sourceType: sourceType,
      sourceId: sourceId,
      sourceLabel: sourceLabel.trim(),
      arabicText: arabicText.trim(),
      hour: hour,
      minute: minute,
      enabled: enabled,
    );
    _reminders = List.unmodifiable([..._reminders, reminder]);
    notifyListeners();
    await _persist();
    if (_masterEnabled && reminder.enabled) {
      await _notifications.scheduleDaily(reminder);
    }
    return reminder;
  }

  Future<void> updateReminder(TasbehReminder updated) async {
    final index = _reminders.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;
    await _notifications.cancel(updated.notificationId);
    final copy = [..._reminders]..[index] = updated;
    _reminders = List.unmodifiable(copy);
    notifyListeners();
    await _persist();
    if (_masterEnabled && updated.enabled) {
      await _notifications.scheduleDaily(updated);
    }
  }

  Future<void> setReminderEnabled(TasbehReminder reminder, bool enabled) {
    return updateReminder(reminder.copyWith(enabled: enabled));
  }

  Future<void> deleteReminder(String id) async {
    final index = _reminders.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final removed = _reminders[index];
    await _notifications.cancel(removed.notificationId);
    _reminders = List.unmodifiable(
      _reminders.where((item) => item.id != id),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> resyncSchedules() async {
    if (!_ready) return;
    final expected = _masterEnabled
        ? _reminders.where((item) => item.enabled).toList(growable: false)
        : const <TasbehReminder>[];
    final expectedIds = expected.map((item) => item.notificationId).toSet();
    final pendingIds = await _notifications.pendingNotificationIds();

    for (final reminder in _reminders) {
      if (!expectedIds.contains(reminder.notificationId) &&
          pendingIds.contains(reminder.notificationId)) {
        await _notifications.cancel(reminder.notificationId);
      }
    }
    for (final reminder in expected) {
      await _notifications.scheduleDaily(reminder);
    }
    _permissionSnapshot = await permissions.status();
    notifyListeners();
  }

  Future<void> handlePayload(String payload) async {
    final decoded = decodeReminderPayload(payload);
    if (decoded == null) return;
    final reminderId = decoded['reminderId'] as String?;
    if (reminderId == null) return;
    TasbehReminder? reminder;
    for (final item in _reminders) {
      if (item.id == reminderId) {
        reminder = item;
        break;
      }
    }
    final callback = onOpenReminder;
    if (callback == null) {
      _pendingPayload = payload;
      return;
    }
    await callback(reminder);
  }

  Future<void> consumePendingNavigation() async {
    final payload = _pendingPayload;
    _pendingPayload = null;
    if (payload != null) await handlePayload(payload);
  }

  int _allocateNotificationId() {
    final used = _reminders.map((item) => item.notificationId).toSet();
    var candidate = _nextNotificationId;
    while (used.contains(candidate)) {
      candidate += 1;
    }
    _nextNotificationId = candidate + 1;
    return candidate;
  }

  Future<void> _persist() {
    final snapshot = ReminderStoreSnapshot(
      masterEnabled: _masterEnabled,
      nextNotificationId: _nextNotificationId,
      reminders: _reminders,
    );
    _writeQueue = _writeQueue.then((_) => _repository.write(snapshot));
    return _writeQueue;
  }
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
