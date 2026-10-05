import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/app/league_track_app.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/core/theme/app_colors.dart';
import 'package:league_track/core/theme/app_theme.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/providers/league_providers.dart';

void main() {
  testWidgets('app shell opens the fixtures screen with the league theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith(OnlineConnectivity.new),
          leagueApiProvider.overrideWithValue(
            MockLeagueApi(delay: Duration.zero),
          ),
        ],
        child: const LeagueTrackApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, AppConstants.appName);
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.colorScheme.primary, AppColors.pitch);
    expect(app.darkTheme?.colorScheme.primary, AppColors.pitch);
    expect(app.theme?.extension<LeagueTrackColors>(), LeagueTrackColors.light);
    expect(find.text('Fixtures'), findsWidgets);
    expect(find.text('Standings'), findsOneWidget);
    expect(
      find.text('${AppConstants.leagueName} · ${AppConstants.season}'),
      findsOneWidget,
    );
  });

  test('light and dark themes expose score and form colors', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.paper);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.navy);
    expect(AppTheme.dark.extension<LeagueTrackColors>()?.live, AppColors.live);
    expect(AppTheme.light.textTheme.displaySmall?.fontSize, 32);
  });
}

class OnlineConnectivity extends ConnectivityController {
  @override
  bool build() => true;
}
