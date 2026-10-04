/// A guest review left after attending a table.
class Review {
  const Review({
    required this.id,
    required this.authorId,
    required this.eventId,
    required this.eventTitle,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.authorHandle,
    this.authorAvatarAsset,
  });

  final String id;
  final String authorId;
  final String eventId;
  final String eventTitle;
  final double rating;
  final String text;
  final DateTime createdAt;

  /// Populated from the API's nested `author` object.
  final String? authorName;
  final String? authorHandle;
  final String? authorAvatarAsset;

  factory Review.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String,
      authorId: author?['id'] as String? ?? json['authorId'] as String? ?? '',
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      authorName: author?['name'] as String?,
      authorHandle: author?['handle'] as String?,
      authorAvatarAsset: author?['avatarAsset'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'eventId': eventId,
    'eventTitle': eventTitle,
    'rating': rating,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'author': {
      'id': authorId,
      'name': authorName,
      'handle': authorHandle,
      'avatarAsset': authorAvatarAsset,
    },
  };
}

/// A message inside a table's group thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.text,
    required this.sentAt,
    this.isSystem = false,
    this.authorName,
    this.authorHandle,
    this.authorAvatarAsset,
  });

  final String id;
  final String authorId;
  final String text;
  final DateTime sentAt;

  /// System messages are centred notices such as "Nora joined the table".
  final bool isSystem;

  final String? authorName;
  final String? authorHandle;
  final String? authorAvatarAsset;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as String,
      authorId: author?['id'] as String? ?? json['authorId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      sentAt:
          DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
      isSystem: json['isSystem'] as bool? ?? false,
      authorName: author?['name'] as String?,
      authorHandle: author?['handle'] as String?,
      authorAvatarAsset: author?['avatarAsset'] as String?,
    );
  }
}

/// What a notification is about — drives its icon and accent colour.
enum ActivityKind {
  newGuest,
  payment,
  reminder,
  follower,
  payout,
  invite,
  review,
}

/// An entry in the activity feed.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actorId,
    this.eventId,
    this.isUnread = false,
    this.amount,
    this.actorName,
    this.actorHandle,
    this.actorAvatarAsset,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Person who triggered the activity, when relevant.
  final String? actorId;

  /// Related table, when relevant.
  final String? eventId;

  final bool isUnread;

  /// Money moved, when relevant.
  final double? amount;

  final String? actorName;
  final String? actorHandle;
  final String? actorAvatarAsset;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return ActivityItem(
      id: json['id'] as String,
      kind: ActivityKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ActivityKind.reminder,
      ),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      actorId: actor?['id'] as String? ?? json['actorId'] as String?,
      eventId: json['eventId'] as String?,
      isUnread: json['isUnread'] as bool? ?? false,
      amount: (json['amount'] as num?)?.toDouble(),
      actorName: actor?['name'] as String?,
      actorHandle: actor?['handle'] as String?,
      actorAvatarAsset: actor?['avatarAsset'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'actorId': actorId,
    'eventId': eventId,
    'isUnread': isUnread,
    'amount': amount,
    'actor': {
      'id': actorId,
      'name': actorName,
      'handle': actorHandle,
      'avatarAsset': actorAvatarAsset,
    },
  };
}
