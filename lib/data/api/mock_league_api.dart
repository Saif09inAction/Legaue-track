import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/api/league_api.dart';
import 'package:league_track/data/mock/mock_league_data.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/domain/standings/standing_calculator.dart';
import 'package:league_track/domain/stats/player_stats_calculator.dart';

/// In-memory league feed that pauses with [Future.delayed] so callers use async/await
/// the same way they will for a real HTTP client.
class MockLeagueApi implements LeagueApi {
  MockLeagueApi({Duration? delay, MockLeagueData? data})
    : delay = delay ?? AppConstants.simulatedApiDelay,
      _data = data ?? MockLeagueData.instance;

  final Duration delay;
  final MockLeagueData _data;

  /// When set, every request fails after the simulated delay.
  bool failRequests = false;

  /// Copies of the season that this client can update without touching the shared seed.
  late final List<Fixture> _fixtures = List<Fixture>.of(_data.fixtures);
  late final List<MatchEvent> _events = List<MatchEvent>.of(_data.events);
  late List<Standing> _standings = List<Standing>.of(_data.standings);
  late Map<String, PlayerStats> _stats = Map<String, PlayerStats>.of(
    _data.stats,
  );

  Future<T> _simulate<T>(T value) async {
    await Future<void>.delayed(delay);
    if (failRequests) {
      throw StateError('Mock API unavailable');
    }
    return value;
  }

  @override
  Future<League> fetchLeague() async {
    return _simulate(_data.league);
  }

  @override
  Future<List<Team>> fetchTeams() async {
    return _simulate(List<Team>.unmodifiable(_data.teams));
  }

  @override
  Future<Team> fetchTeam(String id) async {
    await _simulate(null);
    return _data.teams.firstWhere(
      (team) => team.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown team'),
    );
  }

  @override
  Future<List<Player>> fetchPlayers({String? teamId}) async {
    final players = [
      for (final player in _data.players)
        if (teamId == null || player.teamId == teamId) player,
    ];
    return _simulate(List<Player>.unmodifiable(players));
  }

  @override
  Future<Player> fetchPlayer(String id) async {
    await _simulate(null);
    return _data.players.firstWhere(
      (player) => player.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown player'),
    );
  }

  @override
  Future<List<Fixture>> fetchFixtures({
    MatchStatus? status,
    String? teamId,
    int? matchWeek,
  }) async {
    final fixtures = [
      for (final fixture in _fixtures)
        if ((status == null || fixture.status == status) &&
            (teamId == null ||
                fixture.homeTeamId == teamId ||
                fixture.awayTeamId == teamId) &&
            (matchWeek == null || fixture.matchWeek == matchWeek))
          fixture,
    ];
    return _simulate(List<Fixture>.unmodifiable(fixtures));
  }

  @override
  Future<List<MatchEvent>> fetchEvents(String fixtureId) async {
    final events = [
      for (final event in _events)
        if (event.fixtureId == fixtureId) event,
    ];
    return _simulate(List<MatchEvent>.unmodifiable(events));
  }

  @override
  Future<List<Standing>> fetchStandings() async {
    return _simulate(List<Standing>.unmodifiable(_standings));
  }

  @override
  Future<PlayerStats> fetchPlayerStats(String playerId) async {
    await _simulate(null);
    final stats = _stats[playerId];
    if (stats == null) {
      throw ArgumentError.value(playerId, 'playerId', 'Unknown player');
    }
    return stats;
  }

  @override
  Future<List<PlayerStats>> fetchTopScorers({int limit = 10}) async {
    final ordered = _stats.values.toList()
      ..sort((a, b) {
        final byGoals = b.goals.compareTo(a.goals);
        if (byGoals != 0) {
          return byGoals;
        }
        final byAssists = b.assists.compareTo(a.assists);
        if (byAssists != 0) {
          return byAssists;
        }
        return a.playerId.compareTo(b.playerId);
      });
    final page = ordered.length <= limit
        ? ordered
        : ordered.take(limit).toList();
    return _simulate(List<PlayerStats>.unmodifiable(page));
  }

  @override
  Future<Fixture> recordResult({
    required String fixtureId,
    required int homeScore,
    required int awayScore,
  }) async {
    if (homeScore < 0 || awayScore < 0) {
      throw ArgumentError('Scores cannot be negative.');
    }

    await _simulate(null);
    final index = _fixtures.indexWhere((fixture) => fixture.id == fixtureId);
    if (index == -1) {
      throw ArgumentError.value(fixtureId, 'fixtureId', 'Unknown fixture');
    }

    final updated = _fixtures[index].withResult(
      homeScore: homeScore,
      awayScore: awayScore,
    );
    _fixtures[index] = updated;
    _standings = StandingCalculator.calculate(
      teams: _data.teams,
      fixtures: _fixtures,
    );
    _stats = PlayerStatsCalculator.calculate(
      players: _data.players,
      fixtures: _fixtures,
      events: _events,
    );
    return updated;
  }
}
