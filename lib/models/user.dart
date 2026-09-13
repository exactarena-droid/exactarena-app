import 'json.dart';

class User {
  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final String? bio;
  final String? country;
  final bool isPremium;
  final String? email; // self only
  final DateTime? premiumUntil; // self only
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.bio,
    this.country,
    this.isPremium = false,
    this.email,
    this.premiumUntil,
    this.createdAt,
  });

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: asInt(j['id']),
        name: asString(j['name'], 'Fan'),
        username: asStringOrNull(j['username']),
        avatar: asStringOrNull(j['avatar']),
        bio: asStringOrNull(j['bio']),
        country: asStringOrNull(j['country']),
        isPremium: asBool(j['is_premium']),
        email: asStringOrNull(j['email']),
        premiumUntil: asDate(j['premium_until']),
        createdAt: asDate(j['created_at']),
      );
}
