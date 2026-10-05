import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/fixtures/fixtures_screen.dart';
import 'package:league_track/features/fixtures/widgets/fixture_card.dart';
import 'package:league_track/features/fixtures/widgets/fixture_state_view.dart';
import 'package:league_track/providers/league_providers.dart';

void main() {
  testWidgets('shows a loading state while fixtures are requested', (
    tester,
  ) async {
    await tester.pumpWidget(_app(hang: true));
    await tester.pump();

    expect(find.byType(FixtureLoadingView), findsOneWidget);
    expect(find.byType(FixtureCard), findsNothing);
  });

  testWidgets('shows an error state with a retry action', (tester) async {
    await tester.pumpWidget(_app(fail: true));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('fixtures-error')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows an offline state when the device has no connection', (
    tester,
  ) async {
    await tester.pumpWidget(_app(online: false));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('fixtures-offline')), findsOneWidget);
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byType(FixtureCard), findsNothing);
  });

  testWidgets('switches between live, completed, and upcoming fixtures', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(FixtureCard), findsWidgets);
    expect(_cardTextContaining('Live'), findsWidgets);

    await tester.tap(find.text('Completed'));
    await tester.pump();

    expect(_cardText('Full time'), findsWidgets);
    expect(_cardText('Upcoming'), findsNothing);

    await tester.tap(find.byKey(const Key('matchweek-9')));
    await tester.pump();

    expect(_cardText('Upcoming'), findsWidgets);
    expect(_cardText('Full time'), findsNothing);
    expect(find.byType(FixtureCard), findsWidgets);
  });
}

Finder _cardText(String text) {
  return find.descendant(
    of: find.byType(FixtureCard),
    matching: find.text(text),
  );
}

Finder _cardTextContaining(String text) {
  return find.descendant(
    of: find.byType(FixtureCard),
    matching: find.textContaining(text),
  );
}

Widget _app({bool online = true, bool hang = false, bool fail = false}) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith(
        online ? OnlineConnectivity.new : OfflineConnectivity.new,
      ),
      leagueApiProvider.overrideWithValue(MockLeagueApi(delay: Duration.zero)),
      if (hang)
        fixtureBoardProvider.overrideWith(
          (ref) => Completer<FixtureBoard>().future,
        ),
      if (fail)
        fixtureBoardProvider.overrideWith((ref) async {
          throw Exception('Server unavailable');
        }),
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
