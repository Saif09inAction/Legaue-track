import 'package:flutter/painting.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/data/models/models.dart';

class PlayerDraft {
  const PlayerDraft(
    this.name,
    this.position,
    this.number,
    this.nationality,
    this.age,
  );

  final String name;
  final PlayerPosition position;
  final int number;
  final String nationality;
  final int age;
}

/// Club profile plus the core squad used to build mock match events.
class TeamSeed {
  const TeamSeed({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
    required this.stadium,
    required this.stadiumCapacity,
    required this.founded,
    required this.manager,
    required this.strength,
    required this.primary,
    required this.secondary,
    required this.squad,
  });

  final String id;
  final String name;
  final String shortName;
  final String city;
  final String stadium;
  final int stadiumCapacity;
  final int founded;
  final String manager;

  /// Attack and defence rating from 1 to 100. Used only to simulate scores.
  final int strength;
  final int primary;
  final int secondary;
  final List<PlayerDraft> squad;

  Team toTeam() {
    return Team(
      id: id,
      leagueId: AppConstants.leagueId,
      name: name,
      shortName: shortName,
      city: city,
      stadium: stadium,
      stadiumCapacity: stadiumCapacity,
      founded: founded,
      manager: manager,
      primaryColor: Color(primary),
      secondaryColor: Color(secondary),
    );
  }

  List<Player> toPlayers() {
    return [
      for (final player in squad)
        Player(
          id: '${id}_${player.number}',
          teamId: id,
          name: player.name,
          position: player.position,
          shirtNumber: player.number,
          nationality: player.nationality,
          age: player.age,
        ),
    ];
  }
}

/// Fictional clubs for the local sports league. Names and grounds are invented.
abstract final class TeamSeeds {
  static final all = <TeamSeed>[
    TeamSeed(
      id: 'mum',
      name: 'Mumbai Warriors',
      shortName: 'MUM',
      city: 'Mumbai',
      stadium: 'Shivaji Ground',
      stadiumCapacity: 4500,
      founded: 1998,
      manager: 'Anil Kapse',
      strength: 84,
      primary: 0xFF1D4ED8,
      secondary: 0xFFF5C451,
      squad: _xi([
        'Ayaan Kulkarni',
        'Rohan Deshmukh',
        'Vihaan Patil',
        'Arjun More',
        'Kabir Shah',
        'Dev Sharma',
        'Ishaan Joshi',
        'Neel Kadam',
        'Reyansh Pawar',
        'Aarav Naik',
        'Vivaan Bhosale',
      ]),
    ),
    TeamSeed(
      id: 'che',
      name: 'Chembur United',
      shortName: 'CHU',
      city: 'Chembur',
      stadium: 'Chembur Sports Complex',
      stadiumCapacity: 3200,
      founded: 2004,
      manager: 'Suresh Rane',
      strength: 78,
      primary: 0xFF7F1D1D,
      secondary: 0xFFFFFFFF,
      squad: _xi([
        'Samar Jadhav',
        'Yash Chavan',
        'Omkar Rane',
        'Harsh Sawant',
        'Kunal Ghorpade',
        'Tanmay Bhagat',
        'Parth Dalvi',
        'Soham Khedekar',
        'Aditya Salvi',
        'Manav Tawde',
        'Rudra Kamble',
      ]),
    ),
    TeamSeed(
      id: 'gov',
      name: 'Govandi FC',
      shortName: 'GOV',
      city: 'Govandi',
      stadium: 'Govandi Community Ground',
      stadiumCapacity: 2800,
      founded: 2011,
      manager: 'Imtiaz Dalwai',
      strength: 74,
      primary: 0xFF166534,
      secondary: 0xFFFFFFFF,
      squad: _xi([
        'Farhan Shaikh',
        'Imran Qureshi',
        'Zaid Ansari',
        'Rehan Khan',
        'Ayaan Siddiqui',
        'Bilal Merchant',
        'Hamza Dalwai',
        'Saif Parkar',
        'Omar Chaudhary',
        'Yusuf Memon',
        'Irfan Sayed',
      ]),
    ),
    TeamSeed(
      id: 'tal',
      name: 'Taloja Titans',
      shortName: 'TAL',
      city: 'Taloja',
      stadium: 'Taloja Sports Arena',
      stadiumCapacity: 5000,
      founded: 2008,
      manager: 'Prakash Mhatre',
      strength: 80,
      primary: 0xFFC2410C,
      secondary: 0xFF0F172A,
      squad: _xi([
        'Siddharth Mhatre',
        'Tejas Patankar',
        'Nikhil Bhoir',
        'Pranav Gharat',
        'Rohit Tandel',
        'Amit Thakur',
        'Karan Mokal',
        'Varun Gharat',
        'Harshad Patil',
        'Nilesh Bhoir',
        'Swapnil Tandel',
      ]),
    ),
    TeamSeed(
      id: 'nvm',
      name: 'Navi Mumbai FC',
      shortName: 'NMF',
      city: 'Navi Mumbai',
      stadium: 'Navi Mumbai Stadium',
      stadiumCapacity: 8000,
      founded: 2001,
      manager: 'Meera Koli',
      strength: 76,
      primary: 0xFF0F766E,
      secondary: 0xFFFFFFFF,
      squad: _xi([
        'Advait Koli',
        'Rishi Mahajan',
        'Dhruv Shetty',
        'Aryan Kamat',
        'Laksh Pujari',
        'Neil Dhumal',
        'Shaurya Naik',
        'Vedant Koli',
        'Atharv Shetty',
        'Krish Mahajan',
        'Yuvan Kamat',
      ]),
    ),
    TeamSeed(
      id: 'kur',
      name: 'Kurla Rangers',
      shortName: 'KUR',
      city: 'Kurla',
      stadium: 'Chembur Sports Complex',
      stadiumCapacity: 3200,
      founded: 1996,
      manager: 'Joseph Dsouza',
      strength: 70,
      primary: 0xFF6D28D9,
      secondary: 0xFFF5C451,
      squad: _xi([
        'Ryan Dsouza',
        'Joel Fernandes',
        'Aaron Pereira',
        'Nathan Lobo',
        'Chris Dcosta',
        'Evan Rodrigues',
        'Mark Gonsalves',
        'Sean Fernandes',
        'Luke Pereira',
        'Caleb Lobo',
        'Ivan Dsouza',
      ]),
    ),
    TeamSeed(
      id: 'ban',
      name: 'Bandra Athletic',
      shortName: 'BAN',
      city: 'Bandra',
      stadium: 'Shivaji Ground',
      stadiumCapacity: 4500,
      founded: 1992,
      manager: 'Rakesh Mehta',
      strength: 72,
      primary: 0xFFB91C1C,
      secondary: 0xFF111827,
      squad: _xi([
        'Aarush Mehta',
        'Kabir Malhotra',
        'Reyansh Kapoor',
        'Vivaan Sethi',
        'Arnav Khanna',
        'Ishaan Oberoi',
        'Ayaan Bhatia',
        'Devansh Mehra',
        'Shaurya Kapoor',
        'Vihaan Malhotra',
        'Rudra Sethi',
      ]),
    ),
    TeamSeed(
      id: 'tha',
      name: 'Thane United',
      shortName: 'THU',
      city: 'Thane',
      stadium: 'Taloja Sports Arena',
      stadiumCapacity: 5000,
      founded: 2006,
      manager: 'Nitin Wagh',
      strength: 68,
      primary: 0xFF0369A1,
      secondary: 0xFFFFFFFF,
      squad: _xi([
        'Om Wagh',
        'Sai Kadam',
        'Raj Shinde',
        'Aniket Gaikwad',
        'Piyush Jadhav',
        'Gaurav More',
        'Sanket Pawar',
        'Mahesh Shinde',
        'Tushar Gaikwad',
        'Akash Kadam',
        'Pratik Wagh',
      ]),
    ),
  ];
}

const _positions = <PlayerPosition>[
  PlayerPosition.goalkeeper,
  PlayerPosition.defender,
  PlayerPosition.defender,
  PlayerPosition.defender,
  PlayerPosition.defender,
  PlayerPosition.midfielder,
  PlayerPosition.midfielder,
  PlayerPosition.midfielder,
  PlayerPosition.forward,
  PlayerPosition.forward,
  PlayerPosition.forward,
];

List<PlayerDraft> _xi(List<String> names) {
  return [
    for (var index = 0; index < names.length; index++)
      PlayerDraft(
        names[index],
        _positions[index],
        index + 1,
        'India',
        19 + index,
      ),
  ];
}
