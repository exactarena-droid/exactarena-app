import 'json.dart';

class Plan {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final String currency;
  final String? interval;
  final List<String> features;
  final bool isFree;
  final bool isFeatured;

  const Plan({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.price = 0,
    this.currency = 'USD',
    this.interval,
    this.features = const [],
    this.isFree = false,
    this.isFeatured = false,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: asInt(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
        description: asStringOrNull(j['description']),
        price: asDouble(j['price']),
        currency: asString(j['currency'], 'USD'),
        interval: asStringOrNull(j['interval']),
        features: asStringList(j['features']),
        isFree: asBool(j['is_free']),
        isFeatured: asBool(j['is_featured']),
      );
}
