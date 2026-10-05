import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/data/local/local_store.dart';
import 'package:league_track/data/local/memory_local_store.dart';
import 'package:league_track/data/models/user_preferences.dart';
import 'package:league_track/data/repositories/preferences_repository.dart';
import 'package:league_track/providers/league_providers.dart';

final localStoreProvider = Provider<LocalStore>((ref) {
  return MemoryLocalStore();
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(store: ref.watch(localStoreProvider));
});

/// Favorite club, followed clubs, and the saved theme.
class PreferencesController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() {
    return ref.watch(preferencesRepositoryProvider).load();
  }

  Future<void> setFavoriteTeam(String? teamId) async {
    if (teamId != null) {
      await ref.read(leagueRepositoryProvider).teamById(teamId);
    }
    await ref.read(preferencesRepositoryProvider).setFavoriteTeam(teamId);
    state = AsyncData(await ref.read(preferencesRepositoryProvider).load());
  }

  Future<void> setThemeSetting(AppThemeSetting setting) async {
    await ref.read(preferencesRepositoryProvider).setThemeSetting(setting);
    state = AsyncData(await ref.read(preferencesRepositoryProvider).load());
  }

  Future<void> toggleFollowedTeam(String teamId) async {
    await ref.read(leagueRepositoryProvider).teamById(teamId);
    final current = await future;
    final followed = [...current.followedTeamIds];
    if (!followed.remove(teamId)) {
      followed.add(teamId);
    }
    await ref.read(preferencesRepositoryProvider).setFollowedTeams(followed);
    state = AsyncData(await ref.read(preferencesRepositoryProvider).load());
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, UserPreferences>(
      PreferencesController.new,
    );

final themeModeProvider = Provider<ThemeMode>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return preferences.when(
    data: (value) => switch (value.themeSetting) {
      AppThemeSetting.system => ThemeMode.system,
      AppThemeSetting.light => ThemeMode.light,
      AppThemeSetting.dark => ThemeMode.dark,
    },
    error: (_, _) => ThemeMode.system,
    loading: () => ThemeMode.system,
  );
});
