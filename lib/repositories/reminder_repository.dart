import 'package:shared_preferences/shared_preferences.dart';

import '../models/tasbeh_reminder.dart';

abstract interface class ReminderRepository {
  Future<ReminderStoreSnapshot> read();

  Future<void> write(ReminderStoreSnapshot snapshot);
}

class PreferencesReminderRepository implements ReminderRepository {
  PreferencesReminderRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storeKey = 'tasbeh.reminders.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<ReminderStoreSnapshot> read() async {
    final encoded = await _preferences.getString(_storeKey);
    if (encoded == null || encoded.isEmpty) {
      return const ReminderStoreSnapshot();
    }
    try {
      return ReminderStoreSnapshot.decode(encoded);
    } catch (_) {
      return const ReminderStoreSnapshot();
    }
  }

  @override
  Future<void> write(ReminderStoreSnapshot snapshot) {
    return _preferences.setString(_storeKey, snapshot.encode());
  }
}

class MemoryReminderRepository implements ReminderRepository {
  MemoryReminderRepository([
    this._snapshot = const ReminderStoreSnapshot(),
  ]);

  ReminderStoreSnapshot _snapshot;

  @override
  Future<ReminderStoreSnapshot> read() async => _snapshot;

  @override
  Future<void> write(ReminderStoreSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
