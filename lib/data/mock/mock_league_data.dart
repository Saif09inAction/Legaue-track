import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/mock/fixture_factory.dart';
import 'package:league_track/data/mock/team_seeds.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/domain/standings/standing_calculator.dart';
import 'package:league_track/domain/stats/player_stats_calculator.dart';

/// In-memory 2026/27 local sports league, built once and reused.
class MockLeagueData {
  MockLeagueData._({
    required this.league,
    required this.teams,
    required this.players,
    required this.fixtures,
    required this.events,
    required this.standings,
    required this.stats,
  });

  static final MockLeagueData instance = _build();

  final League league;
  final List<Team> teams;
  final List<Player> players;
  final List<Fixture> fixtures;
  final List<MatchEvent> events;
  final List<Standing> standings;
  final Map<String, PlayerStats> stats;

  static MockLeagueData _build() {
    final teams = [for (final seed in TeamSeeds.all) seed.toTeam()];
    final players = [for (final seed in TeamSeeds.all) ...seed.toPlayers()];
    final generated = FixtureFactory.create(
      teams: teams,
      players: players,
      strengthByTeamId: {
        for (final seed in TeamSeeds.all) seed.id: seed.strength,
      },
    );
    final standings = StandingCalculator.calculate(
      teams: teams,
      fixtures: generated.fixtures,
    );
    final stats = PlayerStatsCalculator.calculate(
      players: players,
      fixtures: generated.fixtures,
      events: generated.events,
    );

    return MockLeagueData._(
      league: const League(
        id: AppConstants.leagueId,
        name: AppConstants.leagueName,
        shortName: AppConstants.leagueShortName,
        country: AppConstants.country,
        season: AppConstants.season,
        matchWeeks: AppConstants.seasonMatchWeeks,
      ),
      teams: List.unmodifiable(teams),
      players: List.unmodifiable(players),
      fixtures: List.unmodifiable(generated.fixtures),
      events: List.unmodifiable(generated.events),
      standings: List.unmodifiable(standings),
      stats: Map.unmodifiable(stats),
    );
  }
}
