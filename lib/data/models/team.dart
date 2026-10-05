import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';

class Team extends Equatable {
  const Team({
    required this.id,
    required this.leagueId,
    required this.name,
    required this.shortName,
    required this.city,
    required this.stadium,
    required this.stadiumCapacity,
    required this.founded,
    required this.manager,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String id;
  final String leagueId;
  final String name;
  final String shortName;
  final String city;
  final String stadium;
  final int stadiumCapacity;
  final int founded;
  final String manager;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  List<Object?> get props => [
    id,
    leagueId,
    name,
    shortName,
    city,
    stadium,
    stadiumCapacity,
    founded,
    manager,
    primaryColor,
    secondaryColor,
  ];
}
