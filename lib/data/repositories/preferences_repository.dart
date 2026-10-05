import 'package:league_track/data/local/local_store.dart';
import 'package:league_track/data/local/storage_keys.dart';
import 'package:league_track/data/models/user_preferences.dart';

/// Reads and writes the preferences kept on device.
class PreferencesRepository {
  PreferencesRepository({required this.store});

  final LocalStore store;

  Future<UserPreferences> load() async {
    final favoriteTeamId = await store.readString(StorageKeys.favoriteTeamId);
    final themeName = await store.readString(StorageKeys.themeSetting);
    final followedTeamIds = await store.readStringList(
      StorageKeys.followedTeamIds,
    );
    return UserPreferences(
      favoriteTeamId: favoriteTeamId,
      themeSetting: AppThemeSetting.fromName(themeName),
      followedTeamIds: followedTeamIds,
    );
  }

  Future<void> setFavoriteTeam(String? teamId) async {
    if (teamId == null) {
      await store.delete(StorageKeys.favoriteTeamId);
      return;
    }
    await store.writeString(StorageKeys.favoriteTeamId, teamId);
  }

  Future<void> setThemeSetting(AppThemeSetting setting) async {
    await store.writeString(StorageKeys.themeSetting, setting.name);
  }

  Future<void> setFollowedTeams(List<String> teamIds) async {
    await store.writeStringList(StorageKeys.followedTeamIds, teamIds);
  }
}
