import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/controllers/azkar_controller.dart';
import 'package:tasbeh/models/azkar_models.dart';
import 'package:tasbeh/models/tasbeh_reminder.dart';
import 'package:tasbeh/repositories/azkar_repository.dart';
import 'package:tasbeh/services/azkar_pdf_service.dart';
import 'package:tasbeh/services/notification_service.dart';

void main() {
  test('PDF metadata and daily Azkar text persist and restore', () async {
    final repository = MemoryAzkarRepository();
    final first = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
    );
    await first.initialize();

    expect(await first.uploadPdf(AzkarCategory.morningEvening), isTrue);
    await first.saveDailyEntry(text: 'صبح کے اذکار');
    await first.saveDailyEntry(text: 'شام کے اذکار');

    final restored = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
    );
    await restored.initialize();

    expect(restored.pdfFor(AzkarCategory.morningEvening)?.pageCount, 3);
    expect(restored.dailyEntries.map((entry) => entry.text), [
      'صبح کے اذکار',
      'شام کے اذکار',
    ]);
    expect(restored.dailyEntries.map((entry) => entry.weekday), [1, 2]);
  });

  test('editing and deleting daily Azkar entries updates persistence', () async {
    final repository = MemoryAzkarRepository();
    final controller = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
    );
    await controller.initialize();
    await controller.saveDailyEntry(
      weekday: 1,
      text: 'Original text',
      title: 'Monday',
    );

    final id = controller.dailyEntries.single.id;
    await controller.saveDailyEntry(
      id: id,
      text: 'Edited text',
      title: 'Edited Monday',
    );
    expect(controller.dailyEntries.single.text, 'Edited text');
    expect(controller.dailyEntries.single.title, 'Edited Monday');
    expect(controller.dailyEntries.single.weekday, 1);

    await controller.deleteDailyEntry(id);
    expect(controller.dailyEntries, isEmpty);
  });

  test('weekly notifications use two stable IDs and repeat on a weekday',
      () async {
    final repository = MemoryAzkarRepository();
    final notifications = FakeAzkarNotificationService();
    final controller = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
      notifications: notifications,
    );
    await controller.initialize();

    await controller.saveDailyEntry(
      weekday: 5,
      text: 'Friday Azkar',
      title: 'Friday',
      notifications: const AzkarNotificationSettings(
        enabled: true,
        morningHour: 5,
        eveningHour: 17,
      ),
    );

    final entry = controller.dailyEntries.single;
    expect(entry.weekday, 5);
    expect(entry.morningNotificationId, 20000);
    expect(entry.eveningNotificationId, 20001);
    expect(notifications.weeklyScheduled.keys, {20000, 20001});
    expect(notifications.weeklyScheduled[20000]?.weekday, 5);

    await controller.saveDailyEntry(
      weekday: 5,
      text: 'Updated Friday Azkar',
      notifications: const AzkarNotificationSettings(enabled: false),
    );
    expect(controller.dailyEntries, hasLength(1));
    expect(controller.dailyEntries.single.id, entry.id);
    expect(controller.dailyEntries.single.morningNotificationId, 20000);
    expect(notifications.weeklyScheduled, isEmpty);
    expect(notifications.cancelled, containsAll([20000, 20001]));
  });

  test('notification payload resolves the correct weekday entry', () async {
    final controller = AzkarController(
      repository: MemoryAzkarRepository(),
      pdfService: FakeAzkarPdfService(),
    );
    await controller.initialize();
    await controller.saveDailyEntry(
      weekday: 2,
      text: 'Tuesday Azkar',
    );
    final entry = controller.dailyEntries.single;

    DailyAzkarEntry? opened;
    controller.onOpenEntry = (value) async => opened = value;
    await controller.handleNotificationPayload(
      AzkarWeeklyNotification(
        notificationId: entry.morningNotificationId,
        entryId: entry.id,
        weekday: entry.weekday,
        hour: 5,
        minute: 0,
        title: 'Tasbeh',
        body: 'Reminder',
      ).payload(),
    );

    expect(opened?.id, entry.id);
    expect(opened?.weekday, 2);
  });
}

class FakeAzkarPdfService implements AzkarPdfService {
  @override
  Future<PickedAzkarPdf?> pickAndStore(AzkarCategory category) async {
    return PickedAzkarPdf(
      path: '/private/azkar/' + category.key + '.pdf',
      displayName: category.key + '.pdf',
      pageCount: 3,
    );
  }

  @override
  Future<Uint8List> renderPage({
    required String path,
    required int pageIndex,
    required int maxWidth,
  }) async =>
      Uint8List.fromList(const <int>[1, 2, 3]);

  @override
  Future<void> delete(String path) async {}
}

class FakeAzkarNotificationService implements NotificationService {
  final Map<int, AzkarWeeklyNotification> weeklyScheduled = {};
  final List<int> cancelled = [];

  @override
  Future<void> initialize({
    required ValueChanged<String> onNotificationTap,
  }) async {}

  @override
  Future<ReminderPermissionSnapshot> permissionStatus() async =>
      const ReminderPermissionSnapshot(
        notifications: NotificationPermissionState.granted,
        exactAlarms: ExactAlarmState.granted,
      );

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<void> scheduleDaily(TasbehReminder reminder) async {}

  @override
  Future<void> scheduleWeekly(AzkarWeeklyNotification notification) async {
    weeklyScheduled[notification.notificationId] = notification;
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
    weeklyScheduled.remove(notificationId);
  }

  @override
  Future<Set<int>> pendingNotificationIds() async =>
      weeklyScheduled.keys.toSet();

  @override
  String? takeInitialPayload() => null;
}
