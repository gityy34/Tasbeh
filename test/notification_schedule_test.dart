import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('midnight schedules today when it is still in the future', () {
    final location = tz.UTC;
    final now = tz.TZDateTime(location, 2026, 1, 1, 0, 0).subtract(
      const Duration(minutes: 1),
    );
    final result = nextDailyOccurrence(
      hour: 0,
      minute: 0,
      now: now,
      location: location,
    );
    expect(result, tz.TZDateTime(location, 2026, 1, 1));
  });

  test('time already passed schedules the next local day', () {
    final location = tz.getLocation('Asia/Karachi');
    final now = tz.TZDateTime(location, 2026, 6, 5, 20, 0);
    final result = nextDailyOccurrence(
      hour: 7,
      minute: 30,
      now: now,
      location: location,
    );
    expect(result, tz.TZDateTime(location, 2026, 6, 6, 7, 30));
    expect(result.location.name, 'Asia/Karachi');
  });

  test('invalid and old payloads are safely rejected', () {
    expect(decodeReminderPayload(null), isNull);
    expect(decodeReminderPayload('not-json'), isNull);
    expect(
      decodeReminderPayload('{"schemaVersion":99,"reminderId":"old"}'),
      isNull,
    );
  });
}
