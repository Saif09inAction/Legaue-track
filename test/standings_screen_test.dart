import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/features/matches/result_recorder.dart';
import 'package:league_track/features/standings/standings_board.dart';
import 'package:league_track/features/standings/standings_screen.dart';
import 'package:league_track/providers/league_providers.dart';

void main() {
  testWidgets('shows a loading state while the table is requested', (
    tester,
  ) async {
    await tester.pumpWidget(_app(hang: true));
    await tester.pump();

    expect(find.byKey(const Key('standings-loading')), findsOneWidget);
    expect(find.byKey(const Key('standings-table')), findsNothing);
  });

  testWidgets('shows an error state with a retry action', (tester) async {
    await tester.pumpWidget(_app(fail: true));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('standings-error')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows an offline state when the device has no connection', (
    tester,
  ) async {
    await tester.pumpWidget(_app(online: false));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('standings-offline')), findsOneWidget);
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byKey(const Key('standings-table')), findsNothing);
  });

  testWidgets('renders the full table and highlights first place', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const Key('standings-table')), findsOneWidget);
    for (final label in [
      'POS',
      'TEAM',
      'P',
      'W',
      'D',
      'L',
      'GF',
      'GA',
      'GD',
      'PTS',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byKey(const Key('standing-leader')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StandingsScreen)),
    );
    final rows = await container.read(standingsProvider.future);
    expect(rows, hasLength(8));
    expect(rows.first.position, 1);
    expect(
      _number('standing-${rows.first.teamId}-pts', tester),
      rows.first.points,
    );
    expect(_number('standing-${rows.first.teamId}-pos', tester), 1);

    for (var index = 1; index < rows.length; index++) {
      final previous = rows[index - 1];
      final current = rows[index];
      final ordered =
          previous.points > current.points ||
          (previous.points == current.points &&
              previous.goalDifference > current.goalDifference) ||
          (previous.points == current.points &&
              previous.goalDifference == current.goalDifference &&
              previous.goalsFor >= current.goalsFor);
      expect(ordered, isTrue);
      expect(
        _number('standing-${current.teamId}-played', tester),
        current.played,
      );
      expect(current.played, current.won + current.drawn + current.lost);
      expect(current.points, current.won * 3 + current.drawn);
    }
  });

  testWidgets('updates points, played, and rank when a result is saved', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StandingsScreen)),
    );
    final fixturesFuture = container.read(
      fixturesProvider(const FixtureQuery(status: MatchStatus.scheduled))
          .future,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final scheduled = (await fixturesFuture).first;
    final before = (await container.read(standingsProvider.future))
        .firstWhere((row) => row.teamId == scheduled.homeTeamId);

    expect(
      _number('standing-${scheduled.homeTeamId}-pts', tester),
      before.points,
    );

    final saved = container
        .read(resultRecorderProvider.notifier)
        .record(fixtureId: scheduled.id, homeScore: 2, awayScore: 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(await saved, isTrue);

    final after = (await container.read(standingsProvider.future))
        .firstWhere((row) => row.teamId == scheduled.homeTeamId);
    expect(after.points, before.points + 3);
    expect(after.played, before.played + 1);
    expect(after.won, before.won + 1);
    expect(
      _number('standing-${scheduled.homeTeamId}-pts', tester),
      after.points,
    );
    expect(
      _number('standing-${scheduled.homeTeamId}-played', tester),
      after.played,
    );
    expect(
      _number('standing-${scheduled.homeTeamId}-pos', tester),
      after.position,
    );
    expect(find.byKey(const Key('standing-leader')), findsOneWidget);
  });
}

int _number(String key, WidgetTester tester) {
  return int.parse(tester.widget<Text>(find.byKey(Key(key))).data!);
}

Widget _app({bool online = true, bool hang = false, bool fail = false}) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith(
        online ? OnlineConnectivity.new : OfflineConnectivity.new,
      ),
      leagueApiProvider.overrideWithValue(MockLeagueApi(delay: Duration.zero)),
      if (hang)
        standingsBoardProvider.overrideWith(
          (ref) => Completer<StandingsBoard>().future,
        ),
      if (fail)
        standingsBoardProvider.overrideWith((ref) async {
          throw Exception('Server unavailable');
        }),
    ],
    child: const MaterialApp(home: StandingsScreen()),
  );
}

class OnlineConnectivity extends ConnectivityController {
  @override
  bool build() => true;
}

class OfflineConnectivity extends ConnectivityController {
  @override
  bool build() => false;
}
