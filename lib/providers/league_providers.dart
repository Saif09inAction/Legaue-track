import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/api/league_api.dart';
import 'package:league_track/data/api/mock_league_api.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/data/repositories/league_repository.dart';
import 'package:league_track/data/repositories/league_repository_impl.dart';
import 'package:league_track/providers/cache_providers.dart';

/// Filters for [fixturesProvider]. An empty query returns every fixture.
class FixtureQuery {
  const FixtureQuery({this.status, this.teamId, this.matchWeek});

  final MatchStatus? status;
  final String? teamId;
  final int? matchWeek;

  @override
  bool operator ==(Object other) {
    return other is FixtureQuery &&
        other.status == status &&
        other.teamId == teamId &&
        other.matchWeek == matchWeek;
  }

  @override
  int get hashCode => Object.hash(status, teamId, matchWeek);
}

final leagueApiProvider = Provider<LeagueApi>((ref) {
  return MockLeagueApi(delay: AppConstants.simulatedApiDelay);
});

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepositoryImpl(
    api: ref.watch(leagueApiProvider),
    cache: ref.watch(leagueCacheProvider),
  );
});

final leagueProvider = FutureProvider<League>((ref) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getLeague();
});

final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getTeams();
});

final teamProvider = FutureProvider.family<Team, String>((ref, id) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.teamById(id);
});

final playersProvider = FutureProvider<List<Player>>((ref) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getPlayers();
});

final squadProvider = FutureProvider.family<List<Player>, String>((
  ref,
  teamId,
) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getPlayers(teamId: teamId);
});

final playerProvider = FutureProvider.family<Player, String>((ref, id) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.playerById(id);
});

final fixturesProvider = FutureProvider.family<List<Fixture>, FixtureQuery>((
  ref,
  query,
) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getFixtures(
    status: query.status,
    teamId: query.teamId,
    matchWeek: query.matchWeek,
  );
});

final fixtureProvider = FutureProvider.family<Fixture, String>((ref, id) async {
  final fixtures = await ref.watch(
    fixturesProvider(const FixtureQuery()).future,
  );
  for (final fixture in fixtures) {
    if (fixture.id == id) {
      return fixture;
    }
  }
  throw ArgumentError.value(id, 'id', 'Unknown fixture');
});

final fixtureEventsProvider = FutureProvider.family<List<MatchEvent>, String>((
  ref,
  fixtureId,
) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getEvents(fixtureId);
});

final standingsProvider = FutureProvider<List<Standing>>((ref) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.getStandings();
});

final topScorersProvider = FutureProvider.family<List<PlayerStats>, int>((
  ref,
  limit,
) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.topScorers(limit: limit);
});

final playerStatsProvider = FutureProvider.family<PlayerStats, String>((
  ref,
  playerId,
) async {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.statsFor(playerId);
});
