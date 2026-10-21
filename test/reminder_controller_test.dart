import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/controllers/reminder_controller.dart';
import 'package:tasbeh/models/azkar_models.dart';
import 'package:tasbeh/models/tasbeh_reminder.dart';
import 'package:tasbeh/repositories/reminder_repository.dart';
import 'package:tasbeh/services/notification_service.dart';

void main() {
  group('ReminderController', () {
    late MemoryReminderRepository repository;
    late FakeNotificationService notifications;
    late ReminderController controller;

    setUp(() async {
      repository = MemoryReminderRepository();
      notifications = FakeNotificationService();
      controller = ReminderController(
        repository: repository,
        notifications: notifications,
      );
      await controller.initialize();
    });

    test('creates, persists, and restores a daily reminder', () async {
      final created = await _createSubhanAllah(controller, hour: 7);
      expect(created.notificationId, 10000);
      expect(notifications.scheduled.keys, {10000});

      final restored = ReminderController(
        repository: repository,
        notifications: FakeNotificationService(),
      );
      await restored.initialize();
      expect(restored.reminders, hasLength(1));
      expect(restored.reminders.single.sourceId, 'subhanallah');
      expect(restored.reminders.single.hour, 7);
      expect(restored.reminders.single.notificationId, 10000);
    });

    test('edits a reminder by replacing its one stable schedule', () async {
      final created = await _createSubhanAllah(controller, hour: 7);
      await controller.updateReminder(
        created.copyWith(hour: 19, minute: 30, title: 'Evening Tasbeh'),
      );

      expect(controller.reminders.single.hour, 19);
      expect(controller.reminders.single.minute, 30);
      expect(controller.reminders.single.notificationId, 10000);
      expect(notifications.cancelled, contains(10000));
      expect(notifications.scheduled, hasLength(1));
    });

    test('deletes reminder and cancels its notification', () async {
      final created = await _createSubhanAllah(controller, hour: 7);
      await controller.deleteReminder(created.id);

      expect(controller.reminders, isEmpty);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancelled, contains(created.notificationId));
    });

    test('individual and master switches cancel and restore schedules', () async {
      final first = await _createSubhanAllah(controller, hour: 7);
      final second = await controller.createReminder(
        title: 'Dua reminder',
        sourceType: ReminderSourceType.customDua,
        sourceId: 'custom',
        sourceLabel: 'Morning Dua',
        arabicText: '',
        hour: 8,
        minute: 15,
      );
      expect(notifications.scheduled.keys, {10000, 10001});

      await controller.setReminderEnabled(first, false);
      expect(notifications.scheduled.keys, {second.notificationId});

      await controller.setMasterEnabled(false);
      expect(notifications.scheduled, isEmpty);

      await controller.setMasterEnabled(true);
      expect(notifications.scheduled.keys, {second.notificationId});
    });

    test('resync uses stable IDs and never creates duplicate schedules', () async {
      await _createSubhanAllah(controller, hour: 7);
      await controller.resyncSchedules();
      await controller.resyncSchedules();

      expect(notifications.scheduled, hasLength(1));
      expect(notifications.scheduled.keys.single, 10000);
    });

    test('supports multiple reminders at the same time with unique IDs', () async {
      final first = await _createSubhanAllah(controller, hour: 7);
      final second = await _createSubhanAllah(controller, hour: 7);

      expect(first.notificationId, isNot(second.notificationId));
      expect(notifications.scheduled, hasLength(2));
    });

    test('valid payload opens its item and invalid payload is ignored', () async {
      final reminder = await _createSubhanAllah(controller, hour: 7);
      TasbehReminder? opened;
      controller.onOpenReminder = (value) async => opened = value;

      await controller.handlePayload(reminder.payload());
      expect(opened?.id, reminder.id);

      opened = null;
      await controller.handlePayload('{invalid');
      expect(opened, isNull);
      await controller.handlePayload(
        '{"schemaVersion":1,"reminderId":"missing"}',
      );
      expect(opened, isNull);
    });

    test('permission denial keeps safe scheduling fallback available', () async {
      notifications.permission = const ReminderPermissionSnapshot(
        notifications: NotificationPermissionState.denied,
        exactAlarms: ExactAlarmState.denied,
      );
      await controller.refreshPermissionStatus();
      await _createSubhanAllah(controller, hour: 7);

      expect(
        controller.permissionSnapshot.notifications,
        NotificationPermissionState.denied,
      );
      expect(notifications.scheduled, hasLength(1));
    });
  });

  test('reminder JSON round-trip preserves schema and stable ID', () {
    const reminder = TasbehReminder(
      id: 'reminder-10000',
      notificationId: 10000,
      title: 'Tasbeh Reminder',
      sourceType: ReminderSourceType.builtInTasbeeh,
      sourceId: 'subhanallah',
      sourceLabel: 'SubhanAllah',
      arabicText: 'سُبْحَانَ ٱللَّهِ',
      hour: 0,
      minute: 0,
    );
    const snapshot = ReminderStoreSnapshot(
      nextNotificationId: 10001,
      reminders: [reminder],
    );
    final restored = ReminderStoreSnapshot.decode(snapshot.encode());
    expect(restored.schemaVersion, 1);
    expect(restored.reminders.single.notificationId, 10000);
    expect(restored.reminders.single.hour, 0);
    expect(restored.nextNotificationId, 10001);
  });
}

Future<TasbehReminder> _createSubhanAllah(
  ReminderController controller, {
  required int hour,
}) {
  return controller.createReminder(
    title: 'Tasbeh Reminder',
    sourceType: ReminderSourceType.builtInTasbeeh,
    sourceId: 'subhanallah',
    sourceLabel: 'SubhanAllah',
    arabicText: 'سُبْحَانَ ٱللَّهِ',
    hour: hour,
    minute: 0,
  );
}

class FakeNotificationService implements NotificationService {
  ReminderPermissionSnapshot permission = const ReminderPermissionSnapshot(
    notifications: NotificationPermissionState.granted,
    exactAlarms: ExactAlarmState.granted,
  );
  final Map<int, TasbehReminder> scheduled = {};
  final List<int> cancelled = [];
  ValueChanged<String>? onTap;
  String? initialPayload;

  @override
  Future<void> initialize({required ValueChanged<String> onNotificationTap}) async {
    onTap = onNotificationTap;
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
    scheduled.remove(notificationId);
  }

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<Set<int>> pendingNotificationIds() async => scheduled.keys.toSet();

  @override
  Future<ReminderPermissionSnapshot> permissionStatus() async => permission;

  @override
  Future<bool> requestExactAlarmPermission() async =>
      permission.exactAlarms == ExactAlarmState.granted;

  @override
  Future<bool> requestNotificationPermission() async =>
      permission.notifications == NotificationPermissionState.granted;

  @override
  Future<void> scheduleDaily(TasbehReminder reminder) async {
    scheduled[reminder.notificationId] = reminder;
  }

  @override
  Future<void> scheduleWeekly(AzkarWeeklyNotification notification) async {}

  @override
  String? takeInitialPayload() {
    final payload = initialPayload;
    initialPayload = null;
    return payload;
  }
}
