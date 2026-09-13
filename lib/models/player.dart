import 'json.dart';
import 'team.dart';

class PlayerStat {
  final String season;
  final int appearances;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int minutes;

  const PlayerStat({
    required this.season,
    required this.appearances,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.minutes,
  });

  factory PlayerStat.fromJson(Map<String, dynamic> j) => PlayerStat(
        season: asString(j['season']),
        appearances: asInt(j['appearances']),
        goals: asInt(j['goals']),
        assists: asInt(j['assists']),
        yellowCards: asInt(j['yellow_cards']),
        redCards: asInt(j['red_cards']),
        minutes: asInt(j['minutes']),
      );
}

class Player {
  final int id;
  final String name;
  final String slug;
  final String? position;
  final String? nationality;
  final String? photo;
  final DateTime? dateOfBirth;
  final int? shirtNumber;
  final Map<String, dynamic>? meta;
  final Team? team;
  final List<PlayerStat> stats;

  const Player({
    required this.id,
    required this.name,
    required this.slug,
    this.position,
    this.nationality,
    this.photo,
    this.dateOfBirth,
    this.shirtNumber,
    this.meta,
    this.team,
    this.stats = const [],
  });

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      a--;
    }
    return a;
  }

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: asInt(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
        position: asStringOrNull(j['position']),
        nationality: asStringOrNull(j['nationality']),
        photo: asStringOrNull(j['photo']),
        dateOfBirth: asDate(j['date_of_birth']),
        shirtNumber: asIntOrNull(j['shirt_number']),
        meta: asMap(j['meta']),
        team: asMap(j['team']) == null ? null : Team.fromJson(asMap(j['team'])!),
        stats: asMapList(j['stats']).map(PlayerStat.fromJson).toList(),
      );
}
