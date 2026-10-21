import 'package:shared_preferences/shared_preferences.dart';

import '../models/azkar_models.dart';

abstract interface class AzkarRepository {
  Future<AzkarLibrary> read();

  Future<void> write(AzkarLibrary library);
}

class PreferencesAzkarRepository implements AzkarRepository {
  PreferencesAzkarRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _libraryKey = 'tasbeh.azkar.library.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<AzkarLibrary> read() async {
    final encoded = await _preferences.getString(_libraryKey);
    if (encoded == null || encoded.isEmpty) return const AzkarLibrary.empty();
    try {
      return AzkarLibrary.decode(encoded);
    } catch (_) {
      return const AzkarLibrary.empty();
    }
  }

  @override
  Future<void> write(AzkarLibrary library) {
    return _preferences.setString(_libraryKey, library.encode());
  }
}

class MemoryAzkarRepository implements AzkarRepository {
  AzkarLibrary _library = const AzkarLibrary.empty();

  @override
  Future<AzkarLibrary> read() async => _library;

  @override
  Future<void> write(AzkarLibrary library) async {
    _library = library;
  }
}
