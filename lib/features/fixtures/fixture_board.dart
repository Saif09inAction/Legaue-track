import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/providers/cache_providers.dart';
import 'package:league_track/providers/league_providers.dart';

/// Thrown when fixtures cannot be requested because the device is offline.
class OfflineException implements Exception {
  const OfflineException();
}

/// Fixtures plus the clubs needed to render them.
class FixtureBoard {
  const FixtureBoard({required this.fixtures, required this.teams});

  final List<Fixture> fixtures;
  final Map<String, Team> teams;

  Team? teamById(String id) => teams[id];
}

/// Loads fixtures from the repository, or from the local cache when that fails.
final fixtureBoardProvider = FutureProvider<FixtureBoard>((ref) async {
  final online = ref.watch(isOnlineProvider);
  if (!online) {
    final cached = await _cachedFixtures(ref);
    if (cached == null) {
      throw const OfflineException();
    }
    ref.read(leagueCacheProvider).markStale(fixtures: true, teams: true);
    await publishCacheNotice(ref, offline: true);
    return cached;
  }

  final fixtures = await ref.watch(
    fixturesProvider(const FixtureQuery()).future,
  );
  final teams = await ref.watch(teamsProvider.future);
  await publishCacheNotice(ref, offline: false);
  return FixtureBoard(
    fixtures: fixtures,
    teams: {for (final team in teams) team.id: team},
  );
}, retry: (_, _) => null);

Future<FixtureBoard?> _cachedFixtures(Ref ref) async {
  final snapshot = await ref.read(leagueCacheProvider).read();
  if (snapshot == null || !snapshot.hasFixtures) {
    return null;
  }
  return FixtureBoard(
    fixtures: snapshot.fixtures,
    teams: {for (final team in snapshot.teams) team.id: team},
  );
}
