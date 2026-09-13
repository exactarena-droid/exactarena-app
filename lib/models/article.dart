import 'json.dart';

class Category {
  final int id;
  final String name;
  final String slug;

  const Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: asInt(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
      );
}

class Author {
  final int? id;
  final String name;
  final String? avatar;

  const Author({this.id, required this.name, this.avatar});

  factory Author.fromJson(Map<String, dynamic> j) => Author(
        id: asIntOrNull(j['id']),
        name: asString(j['name']),
        avatar: asStringOrNull(j['avatar']),
      );
}

class Article {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? heroImage;
  final String? videoUrl;
  final bool isPremium;
  final bool isSponsored;
  final String? sponsorName;
  final String? sourceName;
  final String? sourceUrl;
  final bool isLocked;
  final int readingMinutes;
  final int views;
  final DateTime? publishedAt;
  final Category? category;
  final Author? author;
  final String? body;

  const Article({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.heroImage,
    this.videoUrl,
    this.isPremium = false,
    this.isSponsored = false,
    this.sponsorName,
    this.sourceName,
    this.sourceUrl,
    this.isLocked = false,
    this.readingMinutes = 0,
    this.views = 0,
    this.publishedAt,
    this.category,
    this.author,
    this.body,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: asInt(j['id']),
        title: asString(j['title']),
        slug: asString(j['slug']),
        excerpt: asStringOrNull(j['excerpt']),
        heroImage: asStringOrNull(j['hero_image']),
        videoUrl: asStringOrNull(j['video_url']),
        isPremium: asBool(j['is_premium']),
        isSponsored: asBool(j['is_sponsored']),
        sponsorName: asStringOrNull(j['sponsor_name']),
        sourceName: asStringOrNull(j['source_name']),
        sourceUrl: asStringOrNull(j['source_url']),
        isLocked: asBool(j['is_locked']),
        readingMinutes: asInt(j['reading_minutes']),
        views: asInt(j['views']),
        publishedAt: asDate(j['published_at']),
        category: asMap(j['category']) == null ? null : Category.fromJson(asMap(j['category'])!),
        author: asMap(j['author']) == null ? null : Author.fromJson(asMap(j['author'])!),
        body: asStringOrNull(j['body']),
      );
}
