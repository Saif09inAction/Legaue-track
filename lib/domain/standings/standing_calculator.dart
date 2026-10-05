import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/models/models.dart';

/// Builds the table from finished fixtures only.
///
/// Order is points, goal difference, goals scored, then team id.
abstract final class StandingCalculator {
  static List<Standing> calculate({
    required List<Team> teams,
    required List<Fixture> fixtures,
  }) {
    final rows = {for (final team in teams) team.id: _Row(team.id)};
    final finished =
        fixtures
            .where((fixture) => fixture.status == MatchStatus.finished)
            .toList()
          ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    for (final fixture in finished) {
      final homeScore = fixture.homeScore;
      final awayScore = fixture.awayScore;
      if (homeScore == null || awayScore == null) {
        throw StateError('Finished fixture ${fixture.id} is missing a score.');
      }

      final home = rows[fixture.homeTeamId];
      final away = rows[fixture.awayTeamId];
      if (home == null || away == null) {
        throw StateError(
          'Finished fixture ${fixture.id} references an unknown team.',
        );
      }

      home.played += 1;
      home.goalsFor += homeScore;
      home.goalsAgainst += awayScore;
      away.played += 1;
      away.goalsFor += awayScore;
      away.goalsAgainst += homeScore;

      if (homeScore > awayScore) {
        home.won++;
        away.lost++;
        home.form.add(FormResult.win);
        away.form.add(FormResult.loss);
      } else if (homeScore == awayScore) {
        home.drawn++;
        away.drawn++;
        home.form.add(FormResult.draw);
        away.form.add(FormResult.draw);
      } else {
        away.won++;
        home.lost++;
        away.form.add(FormResult.win);
        home.form.add(FormResult.loss);
      }
    }

    final ordered = rows.values.toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) {
          return byPoints;
        }
        final byDifference = b.goalDifference.compareTo(a.goalDifference);
        if (byDifference != 0) {
          return byDifference;
        }
        final byGoals = b.goalsFor.compareTo(a.goalsFor);
        if (byGoals != 0) {
          return byGoals;
        }
        return a.teamId.compareTo(b.teamId);
      });

    return [
      for (var index = 0; index < ordered.length; index++)
        ordered[index].toStanding(index + 1),
    ];
  }
}

class _Row {
  _Row(this.teamId);

  final String teamId;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  final List<FormResult> form = [];

  int get goalDifference => goalsFor - goalsAgainst;

  int get points =>
      won * AppConstants.pointsForWin +
      drawn * AppConstants.pointsForDraw +
      lost * AppConstants.pointsForLoss;

  Standing toStanding(int position) {
    final recent = form.length <= 5 ? form : form.sublist(form.length - 5);
    return Standing(
      position: position,
      teamId: teamId,
      played: played,
      won: won,
      drawn: drawn,
      lost: lost,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      form: List.unmodifiable(recent),
    );
  }
}
