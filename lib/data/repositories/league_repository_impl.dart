import 'package:league_track/core/utils/date_formatters.dart';
import 'package:league_track/data/api/league_api.dart';
import 'package:league_track/data/local/league_cache.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/data/repositories/league_repository.dart';
import 'package:league_track/domain/standings/standing_calculator.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  LeagueRepositoryImpl({required this.api, LeagueCache? cache})
    : cache = cache ?? MemoryLeagueCache();

  final LeagueApi api;
  final LeagueCache cache;

  @override
  Future<League> getLeague() async {
    return api.fetchLeague();
  }

  @override
  Future<List<Team>> getTeams() async {
    try {
      final teams = await api.fetchTeams();
      await cache.save(teams: teams);
      return List<Team>.unmodifiable(teams);
    } catch (_) {
      final snapshot = await cache.read();
      final teams = snapshot?.teams;
      if (teams == null || teams.isEmpty) {
        rethrow;
      }
      cache.markStale(teams: true);
      return List<Team>.unmodifiable(teams);
    }
  }

  @override
  Future<Team> teamById(String id) async {
    try {
      return await api.fetchTeam(id);
    } catch (_) {
      final snapshot = await cache.read();
      for (final team in snapshot?.teams ?? const <Team>[]) {
        if (team.id == id) {
          cache.markStale(teams: true);
          return team;
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<Player>> getPlayers({String? teamId}) async {
    final players = await api.fetchPlayers(teamId: teamId);
    return List<Player>.unmodifiable(players);
  }

  @override
  Future<Player> playerById(String id) async {
    return api.fetchPlayer(id);
  }

  @override
  Future<List<Fixture>> getFixtures({
    MatchStatus? status,
    String? teamId,
    int? matchWeek,
  }) async {
    try {
      final fixtures = await api.fetchFixtures(
        status: status,
        teamId: teamId,
        matchWeek: matchWeek,
      );
      if (status == null && teamId == null && matchWeek == null) {
        await cache.save(fixtures: fixtures);
      }
      return List<Fixture>.unmodifiable(fixtures);
    } catch (_) {
      final snapshot = await cache.read();
      final fixtures = snapshot?.fixtures;
      if (fixtures == null || fixtures.isEmpty) {
        rethrow;
      }
      cache.markStale(fixtures: true);
      return List<Fixture>.unmodifiable([
        for (final fixture in fixtures)
          if (_matches(
            fixture,
            status: status,
            teamId: teamId,
            matchWeek: matchWeek,
          ))
            fixture,
      ]);
    }
  }

  @override
  Future<List<MatchEvent>> getEvents(String fixtureId) async {
    final events = await api.fetchEvents(fixtureId);
    return List<MatchEvent>.unmodifiable(events);
  }

  @override
  Future<List<Standing>> getStandings() async {
    try {
      final standings = await api.fetchStandings();
      await cache.save(standings: standings);
      return List<Standing>.unmodifiable(standings);
    } catch (_) {
      final snapshot = await cache.read();
      final standings = snapshot?.standings;
      if (standings == null || standings.isEmpty) {
        rethrow;
      }
      cache.markStale(standings: true);
      return List<Standing>.unmodifiable(standings);
    }
  }

  @override
  Future<PlayerStats> statsFor(String playerId) async {
    return api.fetchPlayerStats(playerId);
  }

  @override
  Future<List<PlayerStats>> topScorers({int limit = 10}) async {
    final scorers = await api.fetchTopScorers(limit: limit);
    return List<PlayerStats>.unmodifiable(scorers);
  }

  @override
  Future<Fixture> recordResult({
    required String fixtureId,
    required int homeScore,
    required int awayScore,
  }) async {
    final updated = await api.recordResult(
      fixtureId: fixtureId,
      homeScore: homeScore,
      awayScore: awayScore,
    );
    try {
      final fixtures = await api.fetchFixtures();
      final standings = await api.fetchStandings();
      await cache.save(fixtures: fixtures, standings: standings);
    } catch (_) {
      await _cacheRecordedResult(updated);
    }
    return updated;
  }

  Future<void> _cacheRecordedResult(Fixture updated) async {
    final snapshot = await cache.read();
    if (snapshot == null || snapshot.teams.isEmpty) {
      return;
    }
    final fixtures = <Fixture>[
      for (final fixture in snapshot.fixtures)
        if (fixture.id == updated.id) updated else fixture,
    ];
    if (!fixtures.any((fixture) => fixture.id == updated.id)) {
      fixtures.add(updated);
    }
    final standings = StandingCalculator.calculate(
      teams: snapshot.teams,
      fixtures: fixtures,
    );
    await cache.save(fixtures: fixtures, standings: standings);
  }

  bool _matches(
    Fixture fixture, {
    required MatchStatus? status,
    required String? teamId,
    required int? matchWeek,
  }) {
    return (status == null || fixture.status == status) &&
        (teamId == null ||
            fixture.homeTeamId == teamId ||
            fixture.awayTeamId == teamId) &&
        (matchWeek == null || fixture.matchWeek == matchWeek);
  }

  @override
  String kickoffLabel(Fixture fixture) {
    return DateFormatters.formatKickoff(fixture.kickoff);
  }
}
