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

  test('weekly schedule stays on the requested weekday', () {
    final location = tz.getLocation('Asia/Karachi');
    final monday = tz.TZDateTime(location, 2026, 6, 1, 4, 0);
    final sameMonday = nextWeeklyOccurrence(
      weekday: DateTime.monday,
      hour: 5,
      minute: 0,
      now: monday,
      location: location,
    );
    expect(sameMonday, tz.TZDateTime(location, 2026, 6, 1, 5, 0));

    final afterMonday = tz.TZDateTime(location, 2026, 6, 1, 6, 0);
    final nextMonday = nextWeeklyOccurrence(
      weekday: DateTime.monday,
      hour: 5,
      minute: 0,
      now: afterMonday,
      location: location,
    );
    expect(nextMonday, tz.TZDateTime(location, 2026, 6, 8, 5, 0));
  });

  test('weekly schedule handles Sunday rollover and local timezone', () {
    final location = tz.getLocation('Asia/Karachi');
    final sundayNight = tz.TZDateTime(location, 2026, 6, 7, 23, 0);
    final nextSunday = nextWeeklyOccurrence(
      weekday: DateTime.sunday,
      hour: 5,
      minute: 0,
      now: sundayNight,
      location: location,
    );
    expect(nextSunday, tz.TZDateTime(location, 2026, 6, 14, 5, 0));
    expect(nextSunday.location.name, 'Asia/Karachi');
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
