import 'package:equatable/equatable.dart';

enum MatchEventType { goal, yellowCard, redCard }

class MatchEvent extends Equatable {
  const MatchEvent({
    required this.id,
    required this.fixtureId,
    required this.minute,
    required this.type,
    required this.teamId,
    required this.playerId,
    this.assistPlayerId,
  });

  final String id;
  final String fixtureId;
  final int minute;
  final MatchEventType type;
  final String teamId;
  final String playerId;
  final String? assistPlayerId;

  @override
  List<Object?> get props => [
    id,
    fixtureId,
    minute,
    type,
    teamId,
    playerId,
    assistPlayerId,
  ];
}
