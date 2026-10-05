import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:league_track/app/home_shell.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/data/local/league_cache.dart';
import 'package:league_track/data/mock/mock_league_data.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/data/repositories/league_repository_impl.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/fixtures/widgets/fixture_card.dart';
import 'package:league_track/features/standings/standings_board.dart';
import 'package:league_track/providers/league_providers.dart';

void main() {
  test('failed fetches fall back to the cached fixtures and table', () async {
    final api = MockLeagueApi(delay: Duration.zero);
    final cache = MemoryLeagueCache();
    final repository = LeagueRepositoryImpl(api: api, cache: cache);

    final fixtures = await repository.getFixtures();
    final standings = await repository.getStandings();
    await repository.getTeams();
    final scheduled = fixtures
        .where((fixture) => fixture.status == MatchStatus.scheduled)
        .first;
    final homeBefore = standings.firstWhere(
      (row) => row.teamId == scheduled.homeTeamId,
    );

    await repository.recordResult(
      fixtureId: scheduled.id,
      homeScore: 2,
      awayScore: 0,
    );
    final saved = await cache.read();
    final savedFixture = saved!.fixtures.firstWhere(
      (fixture) => fixture.id == scheduled.id,
    );
    final savedHome = saved.standings.firstWhere(
      (row) => row.teamId == scheduled.homeTeamId,
    );
    expect(savedFixture.status, MatchStatus.finished);
    expect(savedFixture.homeScore, 2);
    expect(savedHome.points, homeBefore.points + 3);
    expect(savedHome.played, homeBefore.played + 1);
    expect(cache.usingStaleData, isFalse);

    api.failRequests = true;
    final fallback = await repository.getFixtures();
    expect(
      fallback.firstWhere((fixture) => fixture.id == scheduled.id).homeScore,
      2,
    );
    final live = await repository.getFixtures(status: MatchStatus.live);
    expect(live.every((fixture) => fixture.status == MatchStatus.live), isTrue);
    final table = await repository.getStandings();
    expect(
      table.firstWhere((row) => row.teamId == scheduled.homeTeamId).points,
      homeBefore.points + 3,
    );
    expect(cache.usingStaleData, isTrue);

    api.failRequests = false;
    await repository.getTeams();
    expect(cache.usingStaleData, isTrue);
    await repository.getFixtures();
    await repository.getStandings();
    expect(cache.usingStaleData, isFalse);
  });

  test('a failed fetch with an empty cache still throws', () async {
    final repository = LeagueRepositoryImpl(
      api: MockLeagueApi(delay: Duration.zero)..failRequests = true,
    );
    await expectLater(repository.getFixtures(), throwsStateError);
    await expectLater(repository.getStandings(), throwsStateError);
  });

  test('hive restores fixtures, standings, and clubs', () async {
    final directory = await Directory.systemTemp.createTemp('league_hive');
    Hive.init(directory.path);
    final box = await Hive.openBox<String>('league_cache_test');
    addTearDown(() async {
      await box.deleteFromDisk();
      await directory.delete(recursive: true);
    });

    final data = MockLeagueData.instance;
    await HiveLeagueCache(box).save(
      fixtures: data.fixtures,
      standings: data.standings,
      teams: data.teams,
    );

    final restored = await HiveLeagueCache(box).read();
    expect(restored, isNotNull);
    expect(restored!.fixtures, data.fixtures);
    expect(restored.standings, data.standings);
    expect(restored.teams, data.teams);
    expect(restored.updatedAt, isNotNull);
  });

  testWidgets('fixtures and standings stay on screen when the mock API fails', (
    tester,
  ) async {
    final api = MockLeagueApi(delay: Duration.zero);
    await tester.pumpWidget(_app(api));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(FixtureCard), findsWidgets);
    expect(find.textContaining('Updated'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-standings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const Key('standing-leader')), findsOneWidget);

    api.failRequests = true;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeShell)),
    );
    container.invalidate(fixturesProvider);
    container.invalidate(teamsProvider);
    container.invalidate(standingsProvider);
    container.invalidate(fixtureBoardProvider);
    container.invalidate(standingsBoardProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.byKey(const Key('standing-leader')), findsOneWidget);
    expect(find.textContaining('Saved data'), findsWidgets);
    expect(find.byKey(const Key('standings-error')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-fixtures')));
    await tester.pump();

    expect(find.byType(FixtureCard), findsWidgets);
    expect(find.textContaining('Saved data'), findsWidgets);
    expect(find.byKey(const Key('fixtures-error')), findsNothing);

    await tester.tap(find.byType(FixtureCard).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Match details'), findsOneWidget);
    expect(find.text('Could not load this match'), findsNothing);
    final detailsScroll = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Record result'),
      200,
      scrollable: detailsScroll,
    );
    expect(find.text('Record result'), findsOneWidget);
    final events = find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.data == 'Events could not be loaded.',
    );
    await tester.scrollUntilVisible(
      events,
      200,
      scrollable: detailsScroll,
    );
    expect(events, findsOneWidget);
  });

  testWidgets('offline mode shows the cached fixtures', (tester) async {
    final online = ValueNotifier(true);
    addTearDown(online.dispose);
    await tester.pumpWidget(_app(MockLeagueApi(delay: Duration.zero), online));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(FixtureCard), findsWidgets);

    online.value = false;
    await tester.pump();
    await tester.pump();

    expect(find.byType(FixtureCard), findsWidgets);
    expect(find.textContaining('Offline · Updated'), findsOneWidget);
    expect(find.byKey(const Key('fixtures-offline')), findsNothing);
  });
}

Widget _app(MockLeagueApi api, [ValueNotifier<bool>? online]) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith(
        () => online == null ? OnlineConnectivity() : FlagConnectivity(online),
      ),
      leagueApiProvider.overrideWithValue(api),
    ],
    child: const MaterialApp(home: HomeShell()),
  );
}

class OnlineConnectivity extends ConnectivityController {
  @override
  bool build() => true;
}

class FlagConnectivity extends ConnectivityController {
  FlagConnectivity(this.flag);

  final ValueNotifier<bool> flag;

  void _sync() => state = flag.value;

  @override
  bool build() {
    flag.addListener(_sync);
    ref.onDispose(() => flag.removeListener(_sync));
    return flag.value;
  }
}
