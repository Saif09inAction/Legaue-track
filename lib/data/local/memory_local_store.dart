import 'package:league_track/data/local/local_store.dart';

/// Process-local store used in tests and as the provider default.
class MemoryLocalStore implements LocalStore {
  final Map<String, Object> _values = {};

  @override
  Future<String?> readString(String key) async {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<List<String>> readStringList(String key) async {
    final value = _values[key];
    if (value is! List<String>) {
      return const [];
    }
    return List<String>.unmodifiable(value);
  }

  @override
  Future<void> writeStringList(String key, List<String> values) async {
    _values[key] = List<String>.from(values);
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
