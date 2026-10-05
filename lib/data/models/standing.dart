import 'package:equatable/equatable.dart';
import 'package:league_track/core/constants/app_constants.dart';

enum FormResult { win, draw, loss }

extension FormResultLabel on FormResult {
  String get shortLabel => switch (this) {
    FormResult.win => 'W',
    FormResult.draw => 'D',
    FormResult.loss => 'L',
  };
}

class Standing extends Equatable {
  const Standing({
    required this.position,
    required this.teamId,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.form,
  });

  final int position;
  final String teamId;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;

  /// Oldest result first, at most the last five finished matches.
  final List<FormResult> form;

  int get goalDifference => goalsFor - goalsAgainst;

  int get points =>
      won * AppConstants.pointsForWin +
      drawn * AppConstants.pointsForDraw +
      lost * AppConstants.pointsForLoss;

  @override
  List<Object?> get props => [
    position,
    teamId,
    played,
    won,
    drawn,
    lost,
    goalsFor,
    goalsAgainst,
    form,
  ];
}
