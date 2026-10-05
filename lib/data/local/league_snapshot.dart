import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:league_track/data/models/models.dart';

/// Fixtures, standings, and the clubs needed to label them.
class LeagueSnapshot {
  const LeagueSnapshot({
    required this.fixtures,
    required this.standings,
    required this.teams,
    required this.updatedAt,
  });

  final List<Fixture> fixtures;
  final List<Standing> standings;
  final List<Team> teams;
  final DateTime updatedAt;

  bool get hasFixtures => fixtures.isNotEmpty;

  bool get hasStandings => standings.isNotEmpty;
}

/// JSON stored in the Hive league box. No generated adapters.
abstract final class LeagueSnapshotCodec {
  static String encode(LeagueSnapshot snapshot) {
    return jsonEncode({
      'updatedAt': snapshot.updatedAt.toIso8601String(),
      'fixtures': snapshot.fixtures.map(_fixture).toList(),
      'standings': snapshot.standings.map(_standing).toList(),
      'teams': snapshot.teams.map(_team).toList(),
    });
  }

  static LeagueSnapshot decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic> && json is! Map) {
      throw const FormatException('League cache is not an object.');
    }
    final map = Map<String, dynamic>.from(json);
    return LeagueSnapshot(
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      fixtures: [
        for (final item in map['fixtures'] as List<dynamic>)
          _readFixture(Map<String, dynamic>.from(item as Map)),
      ],
      standings: [
        for (final item in map['standings'] as List<dynamic>)
          _readStanding(Map<String, dynamic>.from(item as Map)),
      ],
      teams: [
        for (final item in map['teams'] as List<dynamic>)
          _readTeam(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  static Map<String, Object?> _fixture(Fixture fixture) {
    return {
      'id': fixture.id,
      'leagueId': fixture.leagueId,
      'matchWeek': fixture.matchWeek,
      'homeTeamId': fixture.homeTeamId,
      'awayTeamId': fixture.awayTeamId,
      'kickoff': fixture.kickoff.toIso8601String(),
      'venue': fixture.venue,
      'status': fixture.status.name,
      'homeScore': fixture.homeScore,
      'awayScore': fixture.awayScore,
      'minute': fixture.minute,
    };
  }

  static Fixture _readFixture(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      matchWeek: json['matchWeek'] as int,
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      kickoff: DateTime.parse(json['kickoff'] as String),
      venue: json['venue'] as String,
      status: MatchStatus.values.byName(json['status'] as String),
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      minute: json['minute'] as int?,
    );
  }

  static Map<String, Object?> _standing(Standing standing) {
    return {
      'position': standing.position,
      'teamId': standing.teamId,
      'played': standing.played,
      'won': standing.won,
      'drawn': standing.drawn,
      'lost': standing.lost,
      'goalsFor': standing.goalsFor,
      'goalsAgainst': standing.goalsAgainst,
      'form': standing.form.map((result) => result.name).toList(),
    };
  }

  static Standing _readStanding(Map<String, dynamic> json) {
    return Standing(
      position: json['position'] as int,
      teamId: json['teamId'] as String,
      played: json['played'] as int,
      won: json['won'] as int,
      drawn: json['drawn'] as int,
      lost: json['lost'] as int,
      goalsFor: json['goalsFor'] as int,
      goalsAgainst: json['goalsAgainst'] as int,
      form: [
        for (final item in json['form'] as List<dynamic>)
          FormResult.values.byName(item as String),
      ],
    );
  }

  static Map<String, Object?> _team(Team team) {
    return {
      'id': team.id,
      'leagueId': team.leagueId,
      'name': team.name,
      'shortName': team.shortName,
      'city': team.city,
      'stadium': team.stadium,
      'stadiumCapacity': team.stadiumCapacity,
      'founded': team.founded,
      'manager': team.manager,
      'primaryColor': team.primaryColor.toARGB32(),
      'secondaryColor': team.secondaryColor.toARGB32(),
    };
  }

  static Team _readTeam(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      city: json['city'] as String,
      stadium: json['stadium'] as String,
      stadiumCapacity: json['stadiumCapacity'] as int,
      founded: json['founded'] as int,
      manager: json['manager'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
    );
  }
}
