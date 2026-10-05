import 'package:equatable/equatable.dart';

class PlayerStats extends Equatable {
  const PlayerStats({
    required this.playerId,
    required this.appearances,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.rating,
  });

  final String playerId;
  final int appearances;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;

  /// Match rating on a 6.0–8.8 scale, derived from the mock events.
  final double rating;

  @override
  List<Object?> get props => [
    playerId,
    appearances,
    goals,
    assists,
    yellowCards,
    redCards,
    rating,
  ];
}
