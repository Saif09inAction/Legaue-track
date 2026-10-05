import 'package:league_track/data/models/models.dart';

/// Season totals derived from fixtures and match events.
///
/// Listed players are each club's core squad, so everyone in that squad is
/// marked as having appeared in the matches their club has started.
abstract final class PlayerStatsCalculator {
  static Map<String, PlayerStats> calculate({
    required List<Player> players,
    required List<Fixture> fixtures,
    required List<MatchEvent> events,
  }) {
    final startedByTeam = <String, int>{};
    for (final fixture in fixtures) {
      if (fixture.status != MatchStatus.finished &&
          fixture.status != MatchStatus.live) {
        continue;
      }
      startedByTeam[fixture.homeTeamId] =
          (startedByTeam[fixture.homeTeamId] ?? 0) + 1;
      startedByTeam[fixture.awayTeamId] =
          (startedByTeam[fixture.awayTeamId] ?? 0) + 1;
    }

    final goals = <String, int>{};
    final assists = <String, int>{};
    final yellowCards = <String, int>{};
    final redCards = <String, int>{};

    for (final event in events) {
      switch (event.type) {
        case MatchEventType.goal:
          goals[event.playerId] = (goals[event.playerId] ?? 0) + 1;
          final assist = event.assistPlayerId;
          if (assist != null) {
            assists[assist] = (assists[assist] ?? 0) + 1;
          }
        case MatchEventType.yellowCard:
          yellowCards[event.playerId] = (yellowCards[event.playerId] ?? 0) + 1;
        case MatchEventType.redCard:
          redCards[event.playerId] = (redCards[event.playerId] ?? 0) + 1;
      }
    }

    return {
      for (final player in players)
        player.id: PlayerStats(
          playerId: player.id,
          appearances: startedByTeam[player.teamId] ?? 0,
          goals: goals[player.id] ?? 0,
          assists: assists[player.id] ?? 0,
          yellowCards: yellowCards[player.id] ?? 0,
          redCards: redCards[player.id] ?? 0,
          rating: _rating(
            player: player,
            appearances: startedByTeam[player.teamId] ?? 0,
            goals: goals[player.id] ?? 0,
            assists: assists[player.id] ?? 0,
            yellowCards: yellowCards[player.id] ?? 0,
            redCards: redCards[player.id] ?? 0,
          ),
        ),
    };
  }

  static double _rating({
    required Player player,
    required int appearances,
    required int goals,
    required int assists,
    required int yellowCards,
    required int redCards,
  }) {
    final base = switch (player.position) {
      PlayerPosition.goalkeeper => 6.7,
      PlayerPosition.defender => 6.6,
      PlayerPosition.midfielder => 6.7,
      PlayerPosition.forward => 6.6,
    };
    if (appearances == 0) {
      return base;
    }
    final raw =
        base +
        (goals * 0.22) +
        (assists * 0.12) -
        (yellowCards * 0.04) -
        (redCards * 0.35);
    final clamped = raw < 6.0 ? 6.0 : (raw > 8.8 ? 8.8 : raw);
    return (clamped * 10).round() / 10;
  }
}
