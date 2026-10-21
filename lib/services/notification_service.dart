import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/azkar_models.dart';
import '../models/tasbeh_reminder.dart';

enum NotificationPermissionState { granted, denied, notRequired, unavailable }

enum ExactAlarmState { granted, denied, notRequired, unavailable }

class ReminderPermissionSnapshot {
  const ReminderPermissionSnapshot({
    required this.notifications,
    required this.exactAlarms,
  });

  final NotificationPermissionState notifications;
  final ExactAlarmState exactAlarms;
}

abstract interface class NotificationService {
  Future<void> initialize({required ValueChanged<String> onNotificationTap});

  Future<ReminderPermissionSnapshot> permissionStatus();

  Future<bool> requestNotificationPermission();

  Future<bool> requestExactAlarmPermission();

  Future<bool> openNotificationSettings();

  Future<void> scheduleDaily(TasbehReminder reminder);

  Future<void> scheduleWeekly(AzkarWeeklyNotification notification);

  Future<void> cancel(int notificationId);

  Future<Set<int>> pendingNotificationIds();

  String? takeInitialPayload();
}

class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    MethodChannel? deviceChannel,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _deviceChannel = deviceChannel ??
            const MethodChannel('com.gityy34.tasbeh/device');

  static const _channelId = 'tasbeh_daily_reminders';
  static const _channelName = 'Tasbeh reminders';
  static const _channelDescription =
      'Daily Tasbeeh and weekly Azkar reminders.';

  final FlutterLocalNotificationsPlugin _plugin;
  final MethodChannel _deviceChannel;
  String? _initialPayload;
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> initialize({
    required ValueChanged<String> onNotificationTap,
  }) async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _setDeviceTimeZone();

    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    );
    await _plugin.initialize(
      settings: initialization,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onNotificationTap(payload);
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) _initialPayload = payload;
    }
    _initialized = true;
  }

  Future<void> _setDeviceTimeZone() async {
    String? timeZoneId;
    try {
      timeZoneId = await _deviceChannel.invokeMethod<String>('getTimeZoneId');
    } on PlatformException {
      timeZoneId = null;
    } on MissingPluginException {
      timeZoneId = null;
    }
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneId ?? 'UTC'));
    } on ArgumentError {
      tz.setLocalLocation(tz.UTC);
    }
  }

  @override
  Future<ReminderPermissionSnapshot> permissionStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const ReminderPermissionSnapshot(
        notifications: NotificationPermissionState.notRequired,
        exactAlarms: ExactAlarmState.notRequired,
      );
    }
    final android = _android;
    if (android == null) {
      return const ReminderPermissionSnapshot(
        notifications: NotificationPermissionState.unavailable,
        exactAlarms: ExactAlarmState.unavailable,
      );
    }
    final notificationsEnabled = await android.areNotificationsEnabled();
    final exactEnabled = await android.canScheduleExactNotifications();
    return ReminderPermissionSnapshot(
      notifications: notificationsEnabled == false
          ? NotificationPermissionState.denied
          : NotificationPermissionState.granted,
      exactAlarms: exactEnabled == false
          ? ExactAlarmState.denied
          : ExactAlarmState.granted,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    return await _android?.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<bool> openNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return await _android?.openAppNotificationSettings() ?? false;
  }

  @override
  Future<void> scheduleDaily(TasbehReminder reminder) async {
    await cancel(reminder.notificationId);
    final permission = await permissionStatus();
    final exact = permission.exactAlarms != ExactAlarmState.denied;
    final scheduledDate = nextDailyOccurrence(
      hour: reminder.hour,
      minute: reminder.minute,
      now: tz.TZDateTime.now(tz.local),
      location: tz.local,
    );
    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: reminder.title,
      body: '${reminder.sourceLabel} — It is time for your Tasbeeh.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminder.payload(),
    );
  }

  @override
  Future<void> scheduleWeekly(AzkarWeeklyNotification notification) async {
    await cancel(notification.notificationId);
    final permission = await permissionStatus();
    final exact = permission.exactAlarms != ExactAlarmState.denied;
    final scheduledDate = nextWeeklyOccurrence(
      weekday: notification.weekday,
      hour: notification.hour,
      minute: notification.minute,
      now: tz.TZDateTime.now(tz.local),
      location: tz.local,
    );
    await _plugin.zonedSchedule(
      id: notification.notificationId,
      title: notification.title,
      body: notification.body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasbeh_weekly_azkar',
          'Weekly Azkar reminders',
          channelDescription: 'Weekly reminders for saved Azkar pages.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: notification.payload(),
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(id: notificationId);

  @override
  Future<Set<int>> pendingNotificationIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((item) => item.id).toSet();
  }

  @override
  String? takeInitialPayload() {
    final payload = _initialPayload;
    _initialPayload = null;
    return payload;
  }
}

tz.TZDateTime nextDailyOccurrence({
  required int hour,
  required int minute,
  required tz.TZDateTime now,
  required tz.Location location,
}) {
  var scheduled = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!scheduled.isAfter(now)) {
    scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }
  return scheduled;
}

tz.TZDateTime nextWeeklyOccurrence({
  required int weekday,
  required int hour,
  required int minute,
  required tz.TZDateTime now,
  required tz.Location location,
}) {
  final safeWeekday = weekday.clamp(DateTime.monday, DateTime.sunday).toInt();
  final daysUntil = (safeWeekday - now.weekday) % DateTime.daysPerWeek;
  var scheduled = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day + daysUntil,
    hour,
    minute,
  );
  if (!scheduled.isAfter(now)) {
    scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day + daysUntil + DateTime.daysPerWeek,
      hour,
      minute,
    );
  }
  return scheduled;
}

Map<String, dynamic>? decodeReminderPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['schemaVersion'] != 1) return null;
    return decoded;
  } catch (_) {
    return null;
  }
}
