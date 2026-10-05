import 'package:flutter_test/flutter_test.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/core/utils/date_formatters.dart';
import 'package:league_track/data/mock/mock_league_data.dart';
import 'package:league_track/data/models/models.dart';

void main() {
  final data = MockLeagueData.instance;
  final teamsById = {for (final team in data.teams) team.id: team};

  List<Fixture> fixtures({
    MatchStatus? status,
    String? teamId,
    int? matchWeek,
  }) {
    return [
      for (final fixture in data.fixtures)
        if ((status == null || fixture.status == status) &&
            (teamId == null ||
                fixture.homeTeamId == teamId ||
                fixture.awayTeamId == teamId) &&
            (matchWeek == null || fixture.matchWeek == matchWeek))
          fixture,
    ];
  }

  List<MatchEvent> eventsFor(String fixtureId) {
    return [
      for (final event in data.events)
        if (event.fixtureId == fixtureId) event,
    ];
  }

  test('season, squads, and fixtures form a full early-season league', () {
    expect(data.league.season, '2026/27');
    expect(data.league.name, AppConstants.leagueName);
    expect(data.teams, hasLength(8));
    expect(data.players, hasLength(88));
    expect(data.fixtures, hasLength(36));

    final names = data.players.map((player) => player.name).toSet();
    expect(names, hasLength(88));

    for (final team in data.teams) {
      final squad = data.players.where((player) => player.teamId == team.id);
      expect(squad, hasLength(11));
      expect(squad.map((player) => player.shirtNumber).toSet(), hasLength(11));
      expect(
        squad.where((player) => player.position == PlayerPosition.goalkeeper),
        isNotEmpty,
      );
      for (final player in squad) {
        expect(player.age, inInclusiveRange(16, 42));
        expect(player.shirtNumber, inInclusiveRange(1, 99));
      }
    }
  });

  test('each matchweek pairs every club once', () {
    for (var week = 1; week <= 9; week++) {
      final weekFixtures = fixtures(matchWeek: week);
      expect(weekFixtures, hasLength(4));
      final clubs = <String>[];
      final weekPairs = <String>{};
      for (final fixture in weekFixtures) {
        expect(fixture.homeTeamId, isNot(fixture.awayTeamId));
        expect(fixture.leagueId, AppConstants.leagueId);
        expect(fixture.venue, teamsById[fixture.homeTeamId]!.stadium);
        clubs
          ..add(fixture.homeTeamId)
          ..add(fixture.awayTeamId);
        final pair = [fixture.homeTeamId, fixture.awayTeamId]..sort();
        expect(weekPairs.add(pair.join('-')), isTrue, reason: fixture.id);
      }
      expect(clubs.toSet(), hasLength(8));
    }
  });

  test('results, the live game, and the table stay consistent', () {
    final allFixtures = fixtures();
    final finished = fixtures(status: MatchStatus.finished);
    final live = fixtures(status: MatchStatus.live);
    final scheduled = fixtures(status: MatchStatus.scheduled);

    expect(finished, hasLength(31));
    expect(live, hasLength(1));
    expect(scheduled, hasLength(4));

    final mondayNight = live.single;
    expect(mondayNight.kickoff, DateTime(2026, 10, 5, 20));
    expect(mondayNight.minute, 86);
    expect(mondayNight.hasScore, isTrue);
    expect(
      DateFormatters.formatKickoff(mondayNight.kickoff),
      'Mon 5 Oct 2026, 20:00',
    );

    var goalsFor = 0;
    var goalsAgainst = 0;
    for (final standing in data.standings) {
      expect(standing.played, standing.won + standing.drawn + standing.lost);
      expect(standing.points, standing.won * 3 + standing.drawn);
      expect(standing.form.length, lessThanOrEqualTo(5));
      goalsFor += standing.goalsFor;
      goalsAgainst += standing.goalsAgainst;
    }
    expect(goalsFor, goalsAgainst);

    final table = data.standings;
    expect(
      table.map((row) => row.position).toList(),
      List.generate(8, (index) => index + 1),
    );
    for (var index = 1; index < table.length; index++) {
      final previous = table[index - 1];
      final current = table[index];
      final betterPoints = previous.points > current.points;
      final samePointsBetterDifference =
          previous.points == current.points &&
          previous.goalDifference > current.goalDifference;
      final sameDifferenceBetterGoals =
          previous.points == current.points &&
          previous.goalDifference == current.goalDifference &&
          previous.goalsFor >= current.goalsFor;
      expect(
        betterPoints || samePointsBetterDifference || sameDifferenceBetterGoals,
        isTrue,
      );
    }

    final playedCounts = table.map((row) => row.played).toList()..sort();
    expect(playedCounts.where((played) => played == 7), hasLength(2));
    expect(playedCounts.where((played) => played == 8), hasLength(6));

    for (final fixture in allFixtures) {
      final events = eventsFor(fixture.id);
      if (fixture.status == MatchStatus.scheduled) {
        expect(fixture.homeScore, isNull);
        expect(fixture.awayScore, isNull);
        expect(events, isEmpty);
        continue;
      }

      expect(fixture.homeScore, _goals(events, fixture.homeTeamId));
      expect(fixture.awayScore, _goals(events, fixture.awayTeamId));
      for (final event in events) {
        expect(event.minute, greaterThan(0));
        if (fixture.status == MatchStatus.live) {
          expect(event.minute, lessThanOrEqualTo(fixture.minute!));
        }
        final player = data.players.firstWhere(
          (candidate) => candidate.id == event.playerId,
        );
        expect(player.teamId, event.teamId);
        final assistId = event.assistPlayerId;
        if (assistId != null) {
          expect(event.type, MatchEventType.goal);
          final assist = data.players.firstWhere(
            (candidate) => candidate.id == assistId,
          );
          expect(assist.teamId, event.teamId);
          expect(assist.id, isNot(player.id));
        }
      }
    }
  });

  test('player totals match the events that produced them', () {
    var eventGoals = 0;
    var statGoals = 0;
    for (final player in data.players) {
      final stats = data.stats[player.id]!;
      final goals = fixtures(teamId: player.teamId)
          .expand((fixture) => eventsFor(fixture.id))
          .where(
            (event) =>
                event.type == MatchEventType.goal &&
                event.playerId == player.id,
          )
          .length;
      final assists = data.fixtures
          .expand((fixture) => eventsFor(fixture.id))
          .where((event) => event.assistPlayerId == player.id)
          .length;
      expect(stats.goals, goals);
      expect(stats.assists, assists);
      expect(stats.appearances, inInclusiveRange(7, 8));
      expect(stats.rating, inInclusiveRange(6, 8.8));
      eventGoals += goals;
      statGoals += stats.goals;
    }
    expect(statGoals, eventGoals);

    final scorers = data.stats.values.toList()
      ..sort((a, b) => b.goals.compareTo(a.goals));
    expect(scorers.first.goals, greaterThan(0));
    expect(scorers.take(10), hasLength(10));

    expect(
      DateFormatters.formatKickoff(DateTime(2026, 8, 15, 16)),
      'Sat 15 Aug 2026, 16:00',
    );
  });
}

int _goals(List<MatchEvent> events, String teamId) {
  return events
      .where(
        (event) => event.type == MatchEventType.goal && event.teamId == teamId,
      )
      .length;
}
