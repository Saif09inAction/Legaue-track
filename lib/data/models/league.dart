import 'package:equatable/equatable.dart';

class League extends Equatable {
  const League({
    required this.id,
    required this.name,
    required this.shortName,
    required this.country,
    required this.season,
    required this.matchWeeks,
  });

  final String id;
  final String name;
  final String shortName;
  final String country;
  final String season;
  final int matchWeeks;

  @override
  List<Object?> get props => [id, name, shortName, country, season, matchWeeks];
}
