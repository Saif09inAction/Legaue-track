import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/data/local/memory_local_store.dart';
import 'package:league_track/data/local/shared_preferences_local_store.dart';
import 'package:league_track/data/local/storage_keys.dart';
import 'package:league_track/data/mock/mock_league_data.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/data/repositories/league_repository_impl.dart';
import 'package:league_track/data/repositories/preferences_repository.dart';
import 'package:league_track/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('simulated api yields before it returns league data', () async {
    final api = MockLeagueApi(delay: const Duration(milliseconds: 40));
    final pending = api.fetchLeague();
    var completed = false;
    pending.then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    final league = await pending;
    expect(completed, isTrue);
    expect(league.id, AppConstants.leagueId);
    expect(await api.fetchStandings(), hasLength(8));
  });

  test('repository returns the same table as the mock season', () async {
    final repository = LeagueRepositoryImpl(
      api: MockLeagueApi(delay: Duration.zero),
    );
    final standings = await repository.getStandings();
    expect(standings, MockLeagueData.instance.standings);
    final live = await repository.getFixtures(status: MatchStatus.live);
    expect(repository.kickoffLabel(live.single), 'Mon 5 Oct 2026, 20:00');
    await expectLater(repository.teamById('missing'), throwsArgumentError);
  });

  test(
    'recording a result finishes the fixture and rebuilds the table',
    () async {
      final repository = LeagueRepositoryImpl(
        api: MockLeagueApi(delay: Duration.zero),
      );
      final before = await repository.getStandings();
      final scheduled = (await repository.getFixtures(
        status: MatchStatus.scheduled,
      )).first;
      final homeBefore = before.firstWhere(
        (row) => row.teamId == scheduled.homeTeamId,
      );
      final awayBefore = before.firstWhere(
        (row) => row.teamId == scheduled.awayTeamId,
      );
      final player = (await repository.getPlayers(teamId: scheduled.homeTeamId))
          .first;
      final statsBefore = await repository.statsFor(player.id);

      final saved = await repository.recordResult(
        fixtureId: scheduled.id,
        homeScore: 2,
        awayScore: 1,
      );
      expect(saved.status, MatchStatus.finished);
      expect(saved.homeScore, 2);
      expect(saved.awayScore, 1);
      expect(saved.minute, isNull);

      final stored = await repository.getFixtures();
      expect(stored.firstWhere((fixture) => fixture.id == scheduled.id), saved);
      expect(
        MockLeagueData.instance.fixtures
            .firstWhere((fixture) => fixture.id == scheduled.id)
            .status,
        MatchStatus.scheduled,
      );

      final afterWin = await repository.getStandings();
      final homeWin = afterWin.firstWhere(
        (row) => row.teamId == scheduled.homeTeamId,
      );
      final awayLoss = afterWin.firstWhere(
        (row) => row.teamId == scheduled.awayTeamId,
      );
      expect(homeWin.points, homeBefore.points + 3);
      expect(homeWin.won, homeBefore.won + 1);
      expect(homeWin.played, homeBefore.played + 1);
      expect(awayLoss.points, awayBefore.points);
      expect(awayLoss.lost, awayBefore.lost + 1);
      expect(awayLoss.played, awayBefore.played + 1);
      expect(
        (await repository.statsFor(player.id)).appearances,
        statsBefore.appearances + 1,
      );

      await repository.recordResult(
        fixtureId: scheduled.id,
        homeScore: 1,
        awayScore: 1,
      );
      final afterDraw = await repository.getStandings();
      expect(
        afterDraw
            .firstWhere((row) => row.teamId == scheduled.homeTeamId)
            .points,
        homeBefore.points + 1,
      );
      expect(
        afterDraw
            .firstWhere((row) => row.teamId == scheduled.awayTeamId)
            .points,
        awayBefore.points + 1,
      );
      expect(
        afterDraw
            .firstWhere((row) => row.teamId == scheduled.homeTeamId)
            .played,
        homeBefore.played + 1,
      );
      expect(
        (await repository.statsFor(player.id)).appearances,
        statsBefore.appearances + 1,
      );

      await expectLater(
        repository.recordResult(
          fixtureId: 'missing',
          homeScore: 1,
          awayScore: 0,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.recordResult(
          fixtureId: scheduled.id,
          homeScore: -1,
          awayScore: 0,
        ),
        throwsArgumentError,
      );
    },
  );

  test('memory store keeps favorite club and followed clubs', () async {
    final store = MemoryLocalStore();
    final repository = PreferencesRepository(store: store);

    expect((await repository.load()).favoriteTeamId, isNull);
    await repository.setFavoriteTeam('ars');
    await repository.setThemeSetting(AppThemeSetting.dark);
    await repository.setFollowedTeams(['liv', 'mci']);

    final saved = await repository.load();
    expect(saved.favoriteTeamId, 'ars');
    expect(saved.themeSetting, AppThemeSetting.dark);
    expect(saved.followedTeamIds, ['liv', 'mci']);

    await repository.setFavoriteTeam(null);
    expect(await store.readString(StorageKeys.favoriteTeamId), isNull);
  });

  test('shared preferences store round-trips strings', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesLocalStore(
      await SharedPreferences.getInstance(),
    );
    await store.writeString(
      StorageKeys.themeSetting,
      AppThemeSetting.light.name,
    );
    await store.writeStringList(StorageKeys.followedTeamIds, ['che']);

    expect(
      await store.readString(StorageKeys.themeSetting),
      AppThemeSetting.light.name,
    );
    expect(await store.readStringList(StorageKeys.followedTeamIds), ['che']);

    await store.delete(StorageKeys.themeSetting);
    expect(await store.readString(StorageKeys.themeSetting), isNull);
  });

  test('providers load standings, a squad, and saved preferences', () async {
    final container = ProviderContainer(
      overrides: [
        leagueApiProvider.overrideWithValue(
          MockLeagueApi(delay: Duration.zero),
        ),
        localStoreProvider.overrideWithValue(MemoryLocalStore()),
      ],
    );
    addTearDown(container.dispose);

    final standings = await container.read(standingsProvider.future);
    expect(standings, hasLength(8));
    expect(standings.first.position, 1);

    final warriors = await container.read(teamProvider('mum').future);
    expect(warriors.name, 'Mumbai Warriors');
    expect(await container.read(squadProvider('mum').future), hasLength(11));

    final week = await container.read(
      fixturesProvider(const FixtureQuery(matchWeek: 8)).future,
    );
    expect(week, hasLength(4));
    expect(await container.read(topScorersProvider(5).future), hasLength(5));

    expect(container.read(themeModeProvider), ThemeMode.system);
    final notifier = container.read(preferencesProvider.notifier);
    await container.read(preferencesProvider.future);
    await notifier.setThemeSetting(AppThemeSetting.dark);
    await notifier.setFavoriteTeam('mum');
    await notifier.toggleFollowedTeam('che');
    await notifier.toggleFollowedTeam('gov');
    await notifier.toggleFollowedTeam('che');

    final preferences = container.read(preferencesProvider).requireValue;
    expect(preferences.favoriteTeamId, 'mum');
    expect(preferences.themeSetting, AppThemeSetting.dark);
    expect(preferences.followedTeamIds, ['gov']);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await expectLater(notifier.setFavoriteTeam('missing'), throwsArgumentError);
    expect(
      container.read(preferencesProvider).requireValue.favoriteTeamId,
      'mum',
    );
  });
}
