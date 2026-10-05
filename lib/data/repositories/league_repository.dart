import 'package:league_track/data/models/models.dart';

/// App-facing league data. Screens should use this instead of [LeagueApi].
abstract interface class LeagueRepository {
  Future<League> getLeague();

  Future<List<Team>> getTeams();

  Future<Team> teamById(String id);

  Future<List<Player>> getPlayers({String? teamId});

  Future<Player> playerById(String id);

  Future<List<Fixture>> getFixtures({
    MatchStatus? status,
    String? teamId,
    int? matchWeek,
  });

  Future<List<MatchEvent>> getEvents(String fixtureId);

  Future<List<Standing>> getStandings();

  Future<PlayerStats> statsFor(String playerId);

  Future<List<PlayerStats>> topScorers({int limit = 10});

  /// Persists a full-time score. Standings are derived again from fixtures.
  Future<Fixture> recordResult({
    required String fixtureId,
    required int homeScore,
    required int awayScore,
  });

  String kickoffLabel(Fixture fixture);
}
