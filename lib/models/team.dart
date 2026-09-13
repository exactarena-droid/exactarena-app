import 'json.dart';
import 'league.dart';

class Team {
  final int id;
  final String name;
  final String? shortName;
  final String slug;
  final String? logo;
  final String? country;
  final int? founded;
  final String? venue;
  final League? league;
  final bool? isFollowing;

  const Team({
    required this.id,
    required this.name,
    this.shortName,
    required this.slug,
    this.logo,
    this.country,
    this.founded,
    this.venue,
    this.league,
    this.isFollowing,
  });

  /// A 2–3 letter crest label used when [logo] is null.
  String get initials {
    final source = (shortName != null && shortName!.isNotEmpty) ? shortName! : name;
    final words = source.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 3 ? 3 : words.first.length).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  String get displayName => (shortName != null && shortName!.isNotEmpty) ? shortName! : name;

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: asInt(j['id']),
        name: asString(j['name']),
        shortName: asStringOrNull(j['short_name']),
        slug: asString(j['slug']),
        logo: asStringOrNull(j['logo']),
        country: asStringOrNull(j['country']),
        founded: asIntOrNull(j['founded']),
        venue: asStringOrNull(j['venue']),
        league: asMap(j['league']) == null ? null : League.fromJson(asMap(j['league'])!),
        isFollowing: j.containsKey('is_following') ? asBool(j['is_following']) : null,
      );
}
