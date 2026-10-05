import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/data/models/models.dart';
import 'package:league_track/providers/league_providers.dart';

/// Everything the match screen renders for one fixture.
class MatchDetails {
  const MatchDetails({
    required this.fixture,
    required this.home,
    required this.away,
    required this.events,
    required this.standings,
    required this.players,
    required this.eventsAvailable,
  });

  final Fixture fixture;
  final Team home;
  final Team away;
  final List<MatchEvent> events;
  final List<Standing> standings;
  final List<Player> players;

  /// False when the event feed failed and the rest of the match is still shown.
  final bool eventsAvailable;

  Standing? standingFor(String teamId) {
    for (final row in standings) {
      if (row.teamId == teamId) {
        return row;
      }
    }
    return null;
  }

  Player? playerById(String id) {
    for (final player in players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }
}

/// Reloads when the fixture list or the table is invalidated after a result.
final matchDetailsProvider = FutureProvider.family<MatchDetails, String>((
  ref,
  fixtureId,
) async {
  final fixture = await ref.watch(fixtureProvider(fixtureId).future);
  final home = await ref.watch(teamProvider(fixture.homeTeamId).future);
  final away = await ref.watch(teamProvider(fixture.awayTeamId).future);
  final standings = await ref.watch(standingsProvider.future);
  final eventsFuture = ref.watch(fixtureEventsProvider(fixtureId).future);
  final playersFuture = ref.watch(playersProvider.future);
  List<MatchEvent> events;
  var eventsAvailable = true;
  try {
    events = await eventsFuture;
  } catch (_) {
    events = const [];
    eventsAvailable = false;
  }
  List<Player> players;
  try {
    players = await playersFuture;
  } catch (_) {
    players = const [];
  }
  return MatchDetails(
    fixture: fixture,
    home: home,
    away: away,
    events: events,
    standings: standings,
    players: players,
    eventsAvailable: eventsAvailable,
  );
}, retry: (_, _) => null);
