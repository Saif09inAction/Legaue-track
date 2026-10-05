import 'package:equatable/equatable.dart';

enum MatchStatus { scheduled, live, finished, postponed }

extension MatchStatusLabel on MatchStatus {
  String get label => switch (this) {
    MatchStatus.scheduled => 'Scheduled',
    MatchStatus.live => 'Live',
    MatchStatus.finished => 'Full time',
    MatchStatus.postponed => 'Postponed',
  };
}

class Fixture extends Equatable {
  const Fixture({
    required this.id,
    required this.leagueId,
    required this.matchWeek,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.kickoff,
    required this.venue,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.minute,
  });

  final String id;
  final String leagueId;
  final int matchWeek;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime kickoff;
  final String venue;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;

  /// Elapsed minute while [status] is [MatchStatus.live].
  final int? minute;

  bool get hasScore => homeScore != null && awayScore != null;

  /// Full-time copy used when a result is recorded.
  Fixture withResult({required int homeScore, required int awayScore}) {
    return Fixture(
      id: id,
      leagueId: leagueId,
      matchWeek: matchWeek,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      kickoff: kickoff,
      venue: venue,
      status: MatchStatus.finished,
      homeScore: homeScore,
      awayScore: awayScore,
      minute: null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    leagueId,
    matchWeek,
    homeTeamId,
    awayTeamId,
    kickoff,
    venue,
    status,
    homeScore,
    awayScore,
    minute,
  ];
}
