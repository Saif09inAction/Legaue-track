import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/fixtures/fixtures_screen.dart';
import 'package:league_track/features/fixtures/widgets/fixture_card.dart';
import 'package:league_track/features/matches/result_recorder.dart';
import 'package:league_track/providers/league_providers.dart';

void main() {
  test(
    'saving through the recorder updates fixture and standings providers',
    () async {
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWith(OnlineConnectivity.new),
          leagueApiProvider.overrideWithValue(
            MockLeagueApi(delay: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);

      final scheduled = (await container.read(
        fixturesProvider(const FixtureQuery(status: MatchStatus.scheduled))
            .future,
      )).first;
      final before = await container.read(standingsProvider.future);
      final homeBefore = before.firstWhere(
        (row) => row.teamId == scheduled.homeTeamId,
      );

      final saved = await container
          .read(resultRecorderProvider.notifier)
          .record(fixtureId: scheduled.id, homeScore: 3, awayScore: 0);
      expect(saved, isTrue);

      final fixture = await container.read(
        fixtureProvider(scheduled.id).future,
      );
      expect(fixture.status, MatchStatus.finished);
      expect(fixture.homeScore, 3);
      expect(fixture.awayScore, 0);

      final after = await container.read(standingsProvider.future);
      final homeAfter = after.firstWhere(
        (row) => row.teamId == scheduled.homeTeamId,
      );
      expect(homeAfter.points, homeBefore.points + 3);
      expect(homeAfter.played, homeBefore.played + 1);
      expect(homeAfter.won, homeBefore.won + 1);
    },
  );

  test('the recorder leaves the season unchanged while offline', () async {
    final container = ProviderContainer(
      overrides: [
        isOnlineProvider.overrideWith(OfflineConnectivity.new),
        leagueApiProvider.overrideWithValue(
          MockLeagueApi(delay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(resultRecorderProvider.notifier)
        .record(fixtureId: 'mw9_mum_che', homeScore: 1, awayScore: 0);
    expect(saved, isFalse);
    expect(
      container.read(resultRecorderProvider).error,
      isA<OfflineException>(),
    );
  });

  testWidgets(
    'recording a result updates the open match and the fixture list',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final opened = tester.widget<FixtureCard>(find.byType(FixtureCard).first);
      final fixtureId = opened.fixture.id;

      await tester.tap(find.byType(FixtureCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Match details'), findsOneWidget);
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
      await tester.scrollUntilVisible(
        find.byKey(const Key('home-standing-points')),
        200,
        scrollable: detailsScroll,
      );

      final homeScore = _number('home-score', tester);
      final awayScore = _number('away-score', tester);
      final homePoints = _number('home-standing-points', tester);
      final homePlayed = _played(tester);

      await tester.tap(find.byKey(const Key('home-score-up')));
      await tester.pump();

      final recordedHome = homeScore + 1;
      final pointsGain = recordedHome > awayScore
          ? 3
          : recordedHome == awayScore
          ? 1
          : 0;

      await tester.tap(find.byKey(const Key('save-result')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Full time'), findsWidgets);
      await tester.scrollUntilVisible(
        find.byKey(const Key('match-scoreline')),
        -400,
        scrollable: detailsScroll,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('match-scoreline'))).data,
        isNull,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('match-scoreline')))
            .textSpan!
            .toPlainText(),
        contains('$recordedHome'),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('home-standing-points')),
        400,
        scrollable: detailsScroll,
      );
      expect(_number('home-standing-points', tester), homePoints + pointsGain);
      expect(_played(tester), homePlayed + 1);
      expect(find.textContaining('Result saved'), findsWidgets);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Fixtures'), findsOneWidget);

      await tester.tap(find.byKey(const Key('matchweek-8')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(Key('fixture-$fixtureId')),
        400,
      );

      expect(
        find.descendant(
          of: find.byKey(Key('fixture-$fixtureId')),
          matching: find.text('$recordedHome'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(Key('fixture-$fixtureId')),
          matching: find.text('Full time'),
        ),
        findsOneWidget,
      );
    },
  );
}

int _number(String key, WidgetTester tester) {
  return int.parse(tester.widget<Text>(find.byKey(Key(key))).data!);
}

int _played(WidgetTester tester) {
  final label = tester
      .widget<Text>(find.byKey(const Key('home-standing-played')))
      .data!;
  return int.parse(label.replaceFirst('P ', ''));
}

Widget _app() {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith(OnlineConnectivity.new),
      leagueApiProvider.overrideWithValue(MockLeagueApi(delay: Duration.zero)),
    ],
    child: const MaterialApp(home: FixturesScreen()),
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
