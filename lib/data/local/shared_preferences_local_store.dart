import 'package:league_track/data/local/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [LocalStore] backed by the shared_preferences plugin.
class SharedPreferencesLocalStore implements LocalStore {
  SharedPreferencesLocalStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> readString(String key) async {
    return _preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<List<String>> readStringList(String key) async {
    return List<String>.unmodifiable(
      _preferences.getStringList(key) ?? const [],
    );
  }

  @override
  Future<void> writeStringList(String key, List<String> values) async {
    await _preferences.setStringList(key, values);
  }

  @override
  Future<void> delete(String key) async {
    await _preferences.remove(key);
  }
}
