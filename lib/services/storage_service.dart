import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

abstract interface class StorageService {
  Future<PersistedState> read();

  Future<void> write(PersistedState state);
}

class PreferencesStorageService implements StorageService {
  PreferencesStorageService({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _stateKey = 'tasbeh.state.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<PersistedState> read() async {
    final encoded = await _preferences.getString(_stateKey);
    if (encoded == null || encoded.isEmpty) {
      return const PersistedState.defaults();
    }
    try {
      return PersistedState.decode(encoded);
    } catch (_) {
      return const PersistedState.defaults();
    }
  }

  @override
  Future<void> write(PersistedState state) {
    return _preferences.setString(_stateKey, state.encode());
  }
}

class MemoryStorageService implements StorageService {
  PersistedState _state = const PersistedState.defaults();

  @override
  Future<PersistedState> read() async => _state;

  @override
  Future<void> write(PersistedState state) async {
    _state = state;
  }
}

