import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/providers/cache_providers.dart';
import 'package:league_track/providers/league_providers.dart';

/// Table rows plus the clubs needed to label them.
class StandingsBoard {
  const StandingsBoard({required this.standings, required this.teams});

  final List<Standing> standings;
  final Map<String, Team> teams;

  Team? teamById(String id) => teams[id];
}

/// Reloads when [standingsProvider] is invalidated after a result is saved.
/// A failed fetch falls back to the last cached table.
final standingsBoardProvider = FutureProvider<StandingsBoard>((ref) async {
  final online = ref.watch(isOnlineProvider);
  if (!online) {
    final cached = await _cachedStandings(ref);
    if (cached == null) {
      throw const OfflineException();
    }
    ref.read(leagueCacheProvider).markStale(standings: true, teams: true);
    await publishCacheNotice(ref, offline: true);
    return cached;
  }

  final standings = await ref.watch(standingsProvider.future);
  final teams = await ref.watch(teamsProvider.future);
  await publishCacheNotice(ref, offline: false);
  return StandingsBoard(
    standings: standings,
    teams: {for (final team in teams) team.id: team},
  );
}, retry: (_, _) => null);

Future<StandingsBoard?> _cachedStandings(Ref ref) async {
  final snapshot = await ref.read(leagueCacheProvider).read();
  if (snapshot == null || !snapshot.hasStandings) {
    return null;
  }
  return StandingsBoard(
    standings: snapshot.standings,
    teams: {for (final team in snapshot.teams) team.id: team},
  );
}
