import 'package:league_track/data/models/models.dart';

/// Remote league feed. The current implementation is simulated, not a network client.
abstract interface class LeagueApi {
  Future<League> fetchLeague();

  Future<List<Team>> fetchTeams();

  Future<Team> fetchTeam(String id);

  Future<List<Player>> fetchPlayers({String? teamId});

  Future<Player> fetchPlayer(String id);

  Future<List<Fixture>> fetchFixtures({
    MatchStatus? status,
    String? teamId,
    int? matchWeek,
  });

  Future<List<MatchEvent>> fetchEvents(String fixtureId);

  Future<List<Standing>> fetchStandings();

  Future<PlayerStats> fetchPlayerStats(String playerId);

  Future<List<PlayerStats>> fetchTopScorers({int limit = 10});

  /// Stores a full-time score and returns the updated fixture.
  Future<Fixture> recordResult({
    required String fixtureId,
    required int homeScore,
    required int awayScore,
  });
}
