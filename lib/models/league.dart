import 'json.dart';

class League {
  final int id;
  final String name;
  final String slug;
  final String? country;
  final String? logo;
  final String? type;
  final String? currentSeason;
  final bool isFeatured;

  const League({
    required this.id,
    required this.name,
    required this.slug,
    this.country,
    this.logo,
    this.type,
    this.currentSeason,
    this.isFeatured = false,
  });

  factory League.fromJson(Map<String, dynamic> j) => League(
        id: asInt(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
        country: asStringOrNull(j['country']),
        logo: asStringOrNull(j['logo']),
        type: asStringOrNull(j['type']),
        currentSeason: asStringOrNull(j['current_season']),
        isFeatured: asBool(j['is_featured']),
      );
}
