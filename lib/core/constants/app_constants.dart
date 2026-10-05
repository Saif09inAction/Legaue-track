/// Shared values for the league season the rest of the app reads.
abstract final class AppConstants {
  static const appName = 'League Track';
  static const leagueId = 'lsl';
  static const leagueName = 'Local Sports League';
  static const leagueShortName = 'LSL';
  static const country = 'India';
  static const season = '2026/27';
  static const seasonMatchWeeks = 14;
  static const pointsForWin = 3;
  static const pointsForDraw = 1;
  static const pointsForLoss = 0;

  /// Fixed clock for mock fixtures so results stay stable between runs.
  /// Monday 5 October 2026, 21:26 — during the matchweek 8 Monday game.
  static final mockNow = DateTime(2026, 10, 5, 21, 26);

  /// Pause used by the simulated league API.
  static const simulatedApiDelay = Duration(milliseconds: 350);
}
