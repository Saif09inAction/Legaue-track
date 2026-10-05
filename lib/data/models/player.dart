import 'package:equatable/equatable.dart';

enum PlayerPosition { goalkeeper, defender, midfielder, forward }

extension PlayerPositionLabel on PlayerPosition {
  String get label => switch (this) {
    PlayerPosition.goalkeeper => 'Goalkeeper',
    PlayerPosition.defender => 'Defender',
    PlayerPosition.midfielder => 'Midfielder',
    PlayerPosition.forward => 'Forward',
  };

  String get shortLabel => switch (this) {
    PlayerPosition.goalkeeper => 'GK',
    PlayerPosition.defender => 'DF',
    PlayerPosition.midfielder => 'MF',
    PlayerPosition.forward => 'FW',
  };
}

class Player extends Equatable {
  const Player({
    required this.id,
    required this.teamId,
    required this.name,
    required this.position,
    required this.shirtNumber,
    required this.nationality,
    required this.age,
  });

  final String id;
  final String teamId;
  final String name;
  final PlayerPosition position;
  final int shirtNumber;
  final String nationality;
  final int age;

  @override
  List<Object?> get props => [
    id,
    teamId,
    name,
    position,
    shirtNumber,
    nationality,
    age,
  ];
}
