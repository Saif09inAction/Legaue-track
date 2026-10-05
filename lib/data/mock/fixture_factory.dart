import 'dart:math';

import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/models/models.dart';

class GeneratedFixtures {
  const GeneratedFixtures({required this.fixtures, required this.events});

  final List<Fixture> fixtures;
  final List<MatchEvent> events;
}

/// Nine matchweeks of the 2026/27 local season, starting Saturday 15 August 2026.
///
/// Scores come from team strength with home advantage, then goals, assists,
/// and cards are assigned to the squads so the table and player totals match.
abstract final class FixtureFactory {
  static const matchWeeksToBuild = 9;

  static GeneratedFixtures create({
    required List<Team> teams,
    required List<Player> players,
    required Map<String, int> strengthByTeamId,
    Random? random,
  }) {
    final rng = random ?? Random(20261005);
    final playersByTeam = <String, List<Player>>{};
    for (final player in players) {
      playersByTeam.putIfAbsent(player.teamId, () => []).add(player);
    }

    final pairings = _roundRobin(teams.length);
    final seasonStart = DateTime(2026, 8, 15);
    final fixtures = <Fixture>[];
    final events = <MatchEvent>[];
    var eventSerial = 0;

    for (var weekIndex = 0; weekIndex < matchWeeksToBuild; weekIndex++) {
      final matchWeek = weekIndex + 1;
      final saturday = seasonStart.add(Duration(days: 7 * weekIndex));
      final round = weekIndex % pairings.length;
      final returnLeg = weekIndex >= pairings.length;
      final pairs = pairings[round];

      for (var matchIndex = 0; matchIndex < pairs.length; matchIndex++) {
        var homeIndex = pairs[matchIndex].$1;
        var awayIndex = pairs[matchIndex].$2;
        if (returnLeg) {
          final swap = homeIndex;
          homeIndex = awayIndex;
          awayIndex = swap;
        }
        final home = teams[homeIndex];
        final away = teams[awayIndex];
        final slot = _kickoffSlots[matchIndex];
        final kickoff = DateTime(
          saturday.year,
          saturday.month,
          saturday.day + slot.dayOffset,
          slot.hour,
          slot.minute,
        );
        final status = _statusFor(kickoff);
        final maxMinute = switch (status) {
          MatchStatus.live => _liveMinute(kickoff),
          MatchStatus.finished => 90 + rng.nextInt(5),
          MatchStatus.scheduled || MatchStatus.postponed => 0,
        };
        final fixtureId = 'mw${matchWeek}_${home.id}_${away.id}';
        final matchEvents =
            status == MatchStatus.scheduled || status == MatchStatus.postponed
            ? const <MatchEvent>[]
            : _eventsForMatch(
                random: rng,
                fixtureId: fixtureId,
                home: home,
                away: away,
                homeStrength: strengthByTeamId[home.id] ?? 60,
                awayStrength: strengthByTeamId[away.id] ?? 60,
                maxMinute: maxMinute,
                homeSquad: playersByTeam[home.id] ?? const [],
                awaySquad: playersByTeam[away.id] ?? const [],
                nextId: () => '${fixtureId}_e${eventSerial++}',
              );

        events.addAll(matchEvents);
        fixtures.add(
          Fixture(
            id: fixtureId,
            leagueId: home.leagueId,
            matchWeek: matchWeek,
            homeTeamId: home.id,
            awayTeamId: away.id,
            kickoff: kickoff,
            venue: home.stadium,
            status: status,
            homeScore: _goalsFor(matchEvents, home.id, status),
            awayScore: _goalsFor(matchEvents, away.id, status),
            minute: status == MatchStatus.live ? maxMinute : null,
          ),
        );
      }
    }

    return GeneratedFixtures(fixtures: fixtures, events: events);
  }

  static const _kickoffSlots = <({int dayOffset, int hour, int minute})>[
    (dayOffset: 0, hour: 16, minute: 0),
    (dayOffset: 0, hour: 18, minute: 30),
    (dayOffset: 1, hour: 16, minute: 0),
    (dayOffset: 2, hour: 20, minute: 0),
  ];

  static MatchStatus _statusFor(DateTime kickoff) {
    if (kickoff.isAfter(AppConstants.mockNow)) {
      return MatchStatus.scheduled;
    }
    final elapsed = AppConstants.mockNow.difference(kickoff);
    if (elapsed.inMinutes < 100) {
      return MatchStatus.live;
    }
    return MatchStatus.finished;
  }

  static int _liveMinute(DateTime kickoff) {
    final elapsed = AppConstants.mockNow.difference(kickoff).inMinutes;
    if (elapsed < 1) {
      return 1;
    }
    if (elapsed > 90) {
      return 90;
    }
    return elapsed;
  }

  static int? _goalsFor(
    List<MatchEvent> events,
    String teamId,
    MatchStatus status,
  ) {
    if (status == MatchStatus.scheduled || status == MatchStatus.postponed) {
      return null;
    }
    return events
        .where(
          (event) =>
              event.type == MatchEventType.goal && event.teamId == teamId,
        )
        .length;
  }

  static List<MatchEvent> _eventsForMatch({
    required Random random,
    required String fixtureId,
    required Team home,
    required Team away,
    required int homeStrength,
    required int awayStrength,
    required int maxMinute,
    required List<Player> homeSquad,
    required List<Player> awaySquad,
    required String Function() nextId,
  }) {
    final drafts = <_DraftEvent>[
      ..._goals(
        random: random,
        team: home,
        squad: homeSquad,
        count: _goalCount(
          random,
          attack: homeStrength,
          defense: awayStrength,
          home: true,
        ),
        maxMinute: maxMinute,
      ),
      ..._goals(
        random: random,
        team: away,
        squad: awaySquad,
        count: _goalCount(
          random,
          attack: awayStrength,
          defense: homeStrength,
          home: false,
        ),
        maxMinute: maxMinute,
      ),
      ..._cards(
        random: random,
        squad: [...homeSquad, ...awaySquad],
        maxMinute: maxMinute,
      ),
    ]..sort((a, b) => a.minute.compareTo(b.minute));

    return [
      for (final draft in drafts)
        MatchEvent(
          id: nextId(),
          fixtureId: fixtureId,
          minute: draft.minute,
          type: draft.type,
          teamId: draft.teamId,
          playerId: draft.playerId,
          assistPlayerId: draft.assistPlayerId,
        ),
    ];
  }

  static int _goalCount(
    Random random, {
    required int attack,
    required int defense,
    required bool home,
  }) {
    final edge = (attack - defense) / 40;
    final raw = 1.15 + edge + (home ? 0.32 : 0);
    final lambda = raw < 0.3 ? 0.3 : (raw > 2.85 ? 2.85 : raw);
    final goals = _poisson(random, lambda);
    return goals > 6 ? 6 : goals;
  }

  static int _poisson(Random random, double lambda) {
    final limit = exp(-lambda);
    var count = 0;
    var product = 1.0;
    while (product > limit) {
      count++;
      product *= random.nextDouble();
    }
    return count - 1;
  }

  static List<_DraftEvent> _goals({
    required Random random,
    required Team team,
    required List<Player> squad,
    required int count,
    required int maxMinute,
  }) {
    if (count == 0 || squad.isEmpty) {
      return const [];
    }
    return [
      for (var index = 0; index < count; index++)
        _goalDraft(random, team, squad, 1 + random.nextInt(maxMinute)),
    ];
  }

  static _DraftEvent _goalDraft(
    Random random,
    Team team,
    List<Player> squad,
    int minute,
  ) {
    final scorer = _pick(random, squad, (player) {
      return switch (player.position) {
        PlayerPosition.forward => 58,
        PlayerPosition.midfielder => 28,
        PlayerPosition.defender => 12,
        PlayerPosition.goalkeeper => 2,
      };
    });
    return _DraftEvent(
      minute: minute,
      type: MatchEventType.goal,
      teamId: team.id,
      playerId: scorer.id,
      assistPlayerId: _assistId(random, squad, scorer),
    );
  }

  static String? _assistId(Random random, List<Player> squad, Player scorer) {
    if (random.nextDouble() > 0.72) {
      return null;
    }
    final candidates = squad
        .where(
          (player) =>
              player.id != scorer.id &&
              player.position != PlayerPosition.goalkeeper,
        )
        .toList();
    if (candidates.isEmpty) {
      return null;
    }
    return _pick(random, candidates, (player) {
      return switch (player.position) {
        PlayerPosition.midfielder => 50,
        PlayerPosition.forward => 35,
        PlayerPosition.defender => 15,
        PlayerPosition.goalkeeper => 0,
      };
    }).id;
  }

  static List<_DraftEvent> _cards({
    required Random random,
    required List<Player> squad,
    required int maxMinute,
  }) {
    final booked = <String>{};
    final cards = <_DraftEvent>[];
    final yellowCount = 2 + random.nextInt(4);
    for (var index = 0; index < yellowCount; index++) {
      final available = squad
          .where((player) => !booked.contains(player.id))
          .toList();
      if (available.isEmpty) {
        break;
      }
      final player = available[random.nextInt(available.length)];
      booked.add(player.id);
      cards.add(
        _DraftEvent(
          minute: 1 + random.nextInt(maxMinute),
          type: MatchEventType.yellowCard,
          teamId: player.teamId,
          playerId: player.id,
        ),
      );
    }

    if (random.nextDouble() < 0.045 && squad.isNotEmpty) {
      final player = squad[random.nextInt(squad.length)];
      cards.add(
        _DraftEvent(
          minute: 1 + random.nextInt(maxMinute),
          type: MatchEventType.redCard,
          teamId: player.teamId,
          playerId: player.id,
        ),
      );
    }
    return cards;
  }

  static Player _pick(
    Random random,
    List<Player> players,
    int Function(Player player) weight,
  ) {
    final total = players.fold<int>(0, (sum, player) => sum + weight(player));
    if (total <= 0) {
      return players.first;
    }
    var ticket = random.nextInt(total);
    for (final player in players) {
      ticket -= weight(player);
      if (ticket < 0) {
        return player;
      }
    }
    return players.last;
  }

  /// Circle method. Team 0 stays fixed and the rest rotate.
  static List<List<(int, int)>> _roundRobin(int teamCount) {
    final rotation = List.generate(teamCount - 1, (index) => index + 1);
    final rounds = <List<(int, int)>>[];

    for (var round = 0; round < teamCount - 1; round++) {
      final cycle = [0, ...rotation];
      final pairs = <(int, int)>[];
      for (var index = 0; index < teamCount ~/ 2; index++) {
        var left = cycle[index];
        var right = cycle[teamCount - 1 - index];
        if (round.isOdd) {
          final swap = left;
          left = right;
          right = swap;
        }
        pairs.add((left, right));
      }
      rounds.add(pairs);
      final last = rotation.removeLast();
      rotation.insert(0, last);
    }
    return rounds;
  }
}

class _DraftEvent {
  const _DraftEvent({
    required this.minute,
    required this.type,
    required this.teamId,
    required this.playerId,
    this.assistPlayerId,
  });

  final int minute;
  final MatchEventType type;
  final String teamId;
  final String playerId;
  final String? assistPlayerId;
}
