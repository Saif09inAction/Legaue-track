/// Persistent key-value storage. Feature code depends on this, not on a plugin.
abstract interface class LocalStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<List<String>> readStringList(String key);

  Future<void> writeStringList(String key, List<String> values);

  Future<void> delete(String key);
}
