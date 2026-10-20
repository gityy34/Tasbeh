import 'notification_service.dart';

class NotificationPermissionService {
  const NotificationPermissionService(this._notifications);

  final NotificationService _notifications;

  Future<ReminderPermissionSnapshot> status() =>
      _notifications.permissionStatus();

  Future<bool> requestNotifications() =>
      _notifications.requestNotificationPermission();

  Future<bool> requestExactAlarms() =>
      _notifications.requestExactAlarmPermission();

  Future<bool> openNotificationSettings() =>
      _notifications.openNotificationSettings();
}
