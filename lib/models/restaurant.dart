/// A partner venue that opens its tables to DineCircle hosts.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.neighborhood,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.distanceMeters,
    required this.heroAsset,
    required this.description,
    this.gallery = const [],
    this.tags = const [],
    this.isPartner = false,
    this.partnerPerk,
    this.openingHours = 'Tue – Sun · 6 pm – 12 am',
    this.seatsAvailable = 0,
  });

  final String id;
  final String name;

  /// e.g. `Modern Italian`.
  final String cuisine;

  final String neighborhood;
  final String address;
  final double rating;
  final int reviewCount;

  /// 1 – 4, rendered as `$$`.
  final int priceLevel;

  final double distanceMeters;
  final String heroAsset;
  final List<String> gallery;
  final String description;
  final List<String> tags;
  final bool isPartner;

  /// Benefit offered exclusively to DineCircle guests.
  final String? partnerPerk;

  final String openingHours;

  /// Seats the venue can still allocate to new tables this month.
  final int seatsAvailable;

  String get priceLevelLabel => List.filled(priceLevel, r'$').join();

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 1,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      heroAsset: json['heroAsset'] as String? ?? '',
      gallery:
          (json['gallery'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      isPartner: json['isPartner'] as bool? ?? false,
      partnerPerk: json['partnerPerk'] as String?,
      openingHours:
          json['openingHours'] as String? ?? 'Tue – Sun · 6 pm – 12 am',
      seatsAvailable: (json['seatsAvailable'] as num?)?.toInt() ?? 0,
    );
  }
}
