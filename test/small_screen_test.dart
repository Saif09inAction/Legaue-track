import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/app/home_shell.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/features/fixtures/widgets/fixture_card.dart';
import 'package:league_track/providers/league_providers.dart';

void main() {
  testWidgets('fixtures, match details, and standings fit a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith(OnlineConnectivity.new),
          leagueApiProvider.overrideWithValue(
            MockLeagueApi(delay: Duration.zero),
          ),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.takeException(), isNull);
    expect(find.byType(FixtureCard), findsWidgets);

    await tester.tap(find.byType(FixtureCard).first);
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
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Match statistics'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.text('Match details'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('nav-standings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const Key('standings-table')), findsOneWidget);
    expect(find.text('PTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class OnlineConnectivity extends ConnectivityController {
  @override
  bool build() => true;
}
