import 'package:flutter/material.dart';

/// The kind of food experience a host is putting on the table.
enum ExperienceType {
  dinner('Dinner', Icons.restaurant_rounded),
  tasting('Tasting', Icons.wine_bar_rounded),
  supperClub('Supper club', Icons.nightlife_rounded),
  brunch('Brunch', Icons.free_breakfast_rounded),
  workshop('Workshop', Icons.school_rounded),
  festival('Food festival', Icons.celebration_rounded);

  const ExperienceType(this.label, this.icon);

  final String label;
  final IconData icon;

  static ExperienceType parse(String? value) {
    return ExperienceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExperienceType.dinner,
    );
  }
}

/// Who is allowed to see and book a table.
enum Audience {
  public('Public', 'Anyone on DineCircle', Icons.public_rounded),
  followers('Followers', 'People who follow you', Icons.people_alt_rounded),
  friends('Friends', 'People you follow back', Icons.favorite_rounded),
  inviteOnly('Invite only', 'Only people you invite', Icons.lock_rounded);

  const Audience(this.label, this.hint, this.icon);

  final String label;
  final String hint;
  final IconData icon;

  static Audience parse(String? value) {
    return Audience.values.firstWhere(
      (a) => a.name == value,
      orElse: () => Audience.public,
    );
  }
}

/// How the food is served.
enum MenuStyle {
  setMenu('Set menu'),
  tastingMenu('Tasting menu'),
  familyStyle('Family style'),
  sharing('Sharing plates'),
  buffet('Buffet');

  const MenuStyle(this.label);

  final String label;

  static MenuStyle parse(String? value) {
    return MenuStyle.values.firstWhere(
      (m) => m.name == value,
      orElse: () => MenuStyle.familyStyle,
    );
  }
}

/// A single course or dish on the table's menu.
class MenuItem {
  const MenuItem({
    required this.name,
    required this.description,
    this.pairing,
    this.isSignature = false,
  });

  final String name;
  final String description;

  /// Optional wine or non-alcoholic pairing offered alongside the dish.
  final String? pairing;

  /// Flagged as the host's signature course.
  final bool isSignature;
}

/// A bookable dining experience created by a host at a partner venue.
class DinnerEvent {
  const DinnerEvent({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.hostId,
    required this.restaurantId,
    required this.imageAsset,
    required this.start,
    required this.seatsTotal,
    required this.seatsTaken,
    required this.pricePerSeat,
    required this.type,
    required this.audience,
    required this.menuStyle,
    required this.included,
    required this.tags,
    required this.menu,
    required this.gallery,
    this.durationMinutes = 150,
    this.language = 'English',
    this.dressCode = 'Smart casual',
    this.isFeatured = false,
    this.hostNote = '',
    this.attendeeIds = const [],
    this.cancellation = 'Free cancellation up to 48 hours before',
    this.hostName,
    this.hostHandle,
    this.hostAvatarAsset,
    this.restaurantName,
    this.restaurantNeighborhood,
  });

  final String id;
  final String title;

  /// Short editorial line shown under the title on cards.
  final String tagline;

  final String description;
  final String hostId;
  final String restaurantId;
  final String imageAsset;
  final List<String> gallery;

  final DateTime start;
  final int durationMinutes;

  final int seatsTotal;
  final int seatsTaken;

  /// Price for one seat, in whole currency units.
  final double pricePerSeat;

  final ExperienceType type;
  final Audience audience;
  final MenuStyle menuStyle;

  /// Everything already covered by the seat price.
  final List<String> included;

  /// Vibe markers: `Wine pairing`, `Vegetarian friendly`, `Rooftop`.
  final List<String> tags;

  final List<MenuItem> menu;
  final String language;
  final String dressCode;
  final bool isFeatured;

  /// Personal note from the host, surfaced on the detail screen.
  final String hostNote;

  final List<String> attendeeIds;
  final String cancellation;

  /// Lightweight host info from the API list endpoint.
  final String? hostName;
  final String? hostHandle;
  final String? hostAvatarAsset;

  /// Lightweight venue info from the API list endpoint.
  final String? restaurantName;
  final String? restaurantNeighborhood;

  int get seatsLeft => (seatsTotal - seatsTaken).clamp(0, seatsTotal);

  bool get isSoldOut => seatsLeft <= 0;

  /// 0 – 1 fill ratio, used by the seat meter.
  double get occupancy =>
      seatsTotal == 0 ? 0 : (seatsTaken / seatsTotal).clamp(0, 1);

  Duration get duration => Duration(minutes: durationMinutes);

  DateTime get end => start.add(duration);

  bool get isUpcoming => start.isAfter(DateTime.now());

  int get courseCount => menu.length;

  /// Marketing line for the seat meter, e.g. `3 seats left`.
  String get seatsLabel {
    if (isSoldOut) return 'Sold out';
    if (seatsLeft == 1) return 'Last seat';
    if (seatsLeft <= 3) return '$seatsLeft seats left';
    return '$seatsLeft of $seatsTotal seats open';
  }

  String get timeRangeLabel {
    final endLocal = end;
    return '${_clock(start)} – ${_clock(endLocal)}';
  }

  static String _clock(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'pm' : 'am';
    return minute == '00' ? '$hour$period' : '$hour:$minute$period';
  }

  /// Used by the store when seats are sold, edited or the table is republished.
  DinnerEvent copyWith({
    int? seatsTaken,
    int? seatsTotal,
    List<String>? attendeeIds,
    DateTime? start,
    double? pricePerSeat,
    Audience? audience,
    bool? isFeatured,
  }) {
    return DinnerEvent(
      id: id,
      title: title,
      tagline: tagline,
      description: description,
      hostId: hostId,
      restaurantId: restaurantId,
      imageAsset: imageAsset,
      gallery: gallery,
      start: start ?? this.start,
      durationMinutes: durationMinutes,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsTaken: seatsTaken ?? this.seatsTaken,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      type: type,
      audience: audience ?? this.audience,
      menuStyle: menuStyle,
      included: included,
      tags: tags,
      menu: menu,
      language: language,
      dressCode: dressCode,
      isFeatured: isFeatured ?? this.isFeatured,
      hostNote: hostNote,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      cancellation: cancellation,
      hostName: hostName,
      hostHandle: hostHandle,
      hostAvatarAsset: hostAvatarAsset,
      restaurantName: restaurantName,
      restaurantNeighborhood: restaurantNeighborhood,
    );
  }

  /// Parses the list-endpoint shape (no menu / venue / attendees).
  factory DinnerEvent.fromJson(Map<String, dynamic> json) {
    final host = json['host'] as Map<String, dynamic>?;
    final rest = json['restaurant'] as Map<String, dynamic>?;
    return DinnerEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      imageAsset: json['imageAsset'] as String? ?? '',
      start:
          DateTime.tryParse(json['startAt']?.toString() ?? '') ??
          DateTime.now(),
      seatsTotal: (json['seatsTotal'] as num?)?.toInt() ?? 0,
      seatsTaken: (json['seatsTaken'] as num?)?.toInt() ?? 0,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble() ?? 0,
      type: ExperienceType.parse(json['type'] as String?),
      audience: Audience.parse(json['audience'] as String?),
      menuStyle: MenuStyle.parse(json['menuStyle'] as String?),
      included: _strList(json['included']),
      tags: _strList(json['tags']),
      menu: const [],
      gallery: _strList(json['gallery']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 150,
      language: json['language'] as String? ?? 'English',
      dressCode: json['dressCode'] as String? ?? 'Smart casual',
      isFeatured: json['isFeatured'] as bool? ?? false,
      hostNote: json['hostNote'] as String? ?? '',
      attendeeIds: _strList(json['attendeeIds']),
      cancellation:
          json['cancellation'] as String? ??
          'Free cancellation up to 48 hours before',
      hostName: host?['name'] as String?,
      hostHandle: host?['handle'] as String?,
      hostAvatarAsset: host?['avatarAsset'] as String?,
      restaurantName: rest?['name'] as String?,
      restaurantNeighborhood: rest?['neighborhood'] as String?,
    );
  }

  /// Parses the saved-events endpoint shape (lighter, no host/venue objects).
  factory DinnerEvent.fromJsonSaved(Map<String, dynamic> json) {
    return DinnerEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: '',
      hostId: '',
      restaurantId: '',
      imageAsset: json['imageAsset'] as String? ?? '',
      start:
          DateTime.tryParse(json['startAt']?.toString() ?? '') ??
          DateTime.now(),
      seatsTotal: (json['seatsTotal'] as num?)?.toInt() ?? 0,
      seatsTaken: (json['seatsTaken'] as num?)?.toInt() ?? 0,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble() ?? 0,
      type: ExperienceType.parse(json['type'] as String?),
      audience: Audience.public,
      menuStyle: MenuStyle.familyStyle,
      included: const [],
      tags: const [],
      menu: const [],
      gallery: const [],
      hostName: json['hostName'] as String?,
    );
  }

  /// Builds the JSON body for POST /api/events.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'tagline': tagline,
      'description': description,
      'restaurantId': restaurantId,
      'imageAsset': imageAsset,
      'gallery': gallery,
      'startAt': start.toIso8601String(),
      'durationMinutes': durationMinutes,
      'seatsTotal': seatsTotal,
      'seatsTaken': seatsTaken,
      'pricePerSeat': pricePerSeat,
      'type': type.name,
      'audience': audience.name,
      'menuStyle': menuStyle.name,
      'included': included,
      'tags': tags,
      'isFeatured': isFeatured,
      'hostNote': hostNote,
      'menu': menu
          .map(
            (m) => {
              'name': m.name,
              'description': m.description,
              if (m.pairing != null) 'pairing': m.pairing,
              'isSignature': m.isSignature,
            },
          )
          .toList(),
    };
  }

  static List<String> _strList(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List<dynamic>).map((e) => e.toString()).toList();
  }
}
