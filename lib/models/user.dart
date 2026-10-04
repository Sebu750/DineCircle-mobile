/// Roles and trust markers a person can hold inside DineCircle.
enum UserBadge {
  /// Identity confirmed by DineCircle.
  verified,

  /// Publishes food content and hosts public tables at scale.
  influencer,

  /// Represents a partner venue.
  restaurant,

  /// Has hosted at least one paid table.
  host,

  /// Rising host with strong guest ratings.
  risingHost,
}

/// A person using DineCircle — guest, host, influencer or venue owner.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.handle,
    required this.city,
    required this.bio,
    required this.followers,
    required this.following,
    required this.dinnersHosted,
    required this.dinnersJoined,
    required this.rating,
    required this.reviewCount,
    this.avatarAsset,
    this.badges = const [],
    this.tastes = const [],
    this.accentHex,
    this.joinedYear = 2024,
  });

  final String id;
  final String name;
  final String handle;
  final String city;

  /// One-line introduction shown on profile headers.
  final String bio;

  final int followers;
  final int following;
  final int dinnersHosted;
  final int dinnersJoined;
  final double rating;
  final int reviewCount;

  /// Bundled photo. When null, the UI falls back to a monogram avatar.
  final String? avatarAsset;

  final List<UserBadge> badges;

  /// Food preferences — used to personalise the discover feed copy.
  final List<String> tastes;

  /// Optional brand tint for monogram avatars.
  final int? accentHex;

  final int joinedYear;

  String get firstName => name.split(' ').first;

  bool get isInfluencer => badges.contains(UserBadge.influencer);
  bool get isVerified => badges.contains(UserBadge.verified);
  bool get isVenue => badges.contains(UserBadge.restaurant);

  /// Label shown next to the name on cards, e.g. `Food creator`.
  String get primaryRole {
    if (isInfluencer) return 'Food creator';
    if (isVenue) return 'Venue partner';
    if (dinnersHosted > 0) return 'Host';
    return 'Guest';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      city: json['city'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      dinnersHosted: (json['dinnersHosted'] as num?)?.toInt() ?? 0,
      dinnersJoined: (json['dinnersJoined'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      avatarAsset: json['avatarAsset'] as String?,
      badges: _parseBadges(json['badges']),
      tastes:
          (json['tastes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      accentHex: _parseAccentHex(json['accentHex']),
      joinedYear: (json['joinedYear'] as num?)?.toInt() ?? 2024,
    );
  }

  static List<UserBadge> _parseBadges(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List<dynamic>).map((e) => e.toString()).map((s) {
      return UserBadge.values.firstWhere(
        (b) => b.name == s,
        orElse: () => UserBadge.verified,
      );
    }).toList();
  }

  static int? _parseAccentHex(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is String) {
      return int.tryParse(raw.replaceFirst('#', ''), radix: 16);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'handle': handle,
    'city': city,
    'bio': bio,
    'followers': followers,
    'following': following,
    'dinnersHosted': dinnersHosted,
    'dinnersJoined': dinnersJoined,
    'rating': rating,
    'reviewCount': reviewCount,
    'avatarAsset': avatarAsset,
    'badges': badges.map((b) => b.name).toList(),
    'tastes': tastes,
    'accentHex': accentHex,
    'joinedYear': joinedYear,
  };
}
