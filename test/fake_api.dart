import 'package:dinecircle/core/api/dine_api.dart';
import 'package:dinecircle/data/mock_data.dart';
import 'package:dinecircle/models/booking.dart';
import 'package:dinecircle/models/dinner_event.dart';
import 'package:dinecircle/models/restaurant.dart';
import 'package:dinecircle/models/social.dart';
import 'package:dinecircle/models/user.dart';

/// A [DineApi] implementation backed by [MockData] so the widget suite runs
/// entirely offline without a real server.
class FakeDineApi implements DineApi {
  final List<DinnerEvent> _events = MockData.events();
  final List<Booking> _bookings = MockData.bookings();
  final Set<String> _saved = {};
  final Set<String> _following = {};
  int _nextBookingId = 100;

  // ── Auth ────────────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> requestOtp(String phone) async => {
    'status': 'sent',
  };

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async => {
    'token': 'fake-token',
    'user': MockData.users.first.toJson(),
  };

  @override
  Future<AppUser> me() async => MockData.users.first;

  @override
  Future<void> signOut() async {}

  // ── Events ──────────────────────────────────────────────────────────────
  @override
  Future<List<DinnerEvent>> fetchEvents({
    String? type,
    String? hostId,
    String? venueId,
    bool upcoming = true,
    String? q,
  }) async => _events;

  @override
  Future<Map<String, dynamic>> fetchEventDetail(String id) async => {};

  @override
  Future<DinnerEvent> createEvent(Map<String, dynamic> payload) async {
    final event = DinnerEvent.fromJson(payload);
    _events.add(event);
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {}

  // ── Bookings ────────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> fetchBookings({String? guestId}) async => {
    'bookings': _bookings.map((b) => b.toJson()).toList(),
  };

  @override
  Future<List<Booking>> fetchGuestList(String eventId) async =>
      _bookings.where((b) => b.eventId == eventId).toList();

  @override
  Future<Map<String, dynamic>> createBooking(
    String eventId, {
    required int seats,
    required String paymentLabel,
  }) async {
    final booking = Booking(
      id: 'b_${_nextBookingId++}',
      eventId: eventId,
      guestId: MockData.meId,
      seats: seats,
      pricePerSeat: 0,
      createdAt: DateTime.now(),
      reference: 'DC-TEST',
      paymentLabel: paymentLabel,
    );
    _bookings.add(booking);
    return {'booking': booking.toJson()};
  }

  @override
  Future<Map<String, dynamic>> cancelBooking(String id) async => {
    'booking': {'id': id, 'eventId': '', 'status': 'cancelled'},
  };

  @override
  Future<void> checkIn(String bookingId) async {}

  // ── Reviews ─────────────────────────────────────────────────────────────
  @override
  Future<List<Review>> fetchReviews({String? hostId, String? eventId}) async =>
      MockData.reviews();

  @override
  Future<Review> submitReview(
    String eventId, {
    required double rating,
    required String text,
  }) async => Review(
    id: 'r_test',
    eventId: eventId,
    authorId: MockData.meId,
    rating: rating,
    text: text,
    createdAt: DateTime.now(),
    authorName: MockData.users.first.name,
  );

  // ── Saved ───────────────────────────────────────────────────────────────
  @override
  Future<List<DinnerEvent>> fetchSaved() async =>
      _events.where((e) => _saved.contains(e.id)).toList();

  @override
  Future<void> saveEvent(String eventId) async => _saved.add(eventId);

  @override
  Future<void> unsaveEvent(String eventId) async => _saved.remove(eventId);

  // ── Users / Follows ────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> fetchUserProfile(String id) async {
    final user = MockData.users.firstWhere(
      (u) => u.id == id,
      orElse: () => MockData.users.first,
    );
    return {
      'user': user.toJson(),
      'viewerFollows': _following.contains(id),
      'hostedUpcoming': _events
          .where((e) => e.hostId == id && e.isUpcoming)
          .map((e) => e.toJson())
          .toList(),
      'reviews': MockData.reviews().map((r) => r.toJson()).toList(),
    };
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String city,
    String bio = '',
    List<String> tastes = const [],
  }) async => MockData.users.first;

  @override
  Future<Map<String, dynamic>> followUser(String userId) async {
    _following.add(userId);
    return {'following': true};
  }

  @override
  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    _following.remove(userId);
    return {'following': false};
  }

  // ── Activity ────────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> fetchActivity() async => {
    'activity': MockData.activity().map((a) => a.toJson()).toList(),
  };

  @override
  Future<void> markActivityRead() async {}

  // ── Chat ────────────────────────────────────────────────────────────────
  @override
  Future<List<ChatMessage>> fetchMessages(String eventId) async =>
      MockData.chatFor(eventId);

  @override
  Future<ChatMessage> sendMessage(String eventId, String text) async =>
      ChatMessage(
        id: 'msg_test',
        authorId: MockData.meId,
        text: text,
        sentAt: DateTime.now(),
        authorName: MockData.users.first.name,
      );

  // ── Hosts / Earnings ───────────────────────────────────────────────────
  @override
  Future<List<EarningsPoint>> fetchTrend(String hostId) async =>
      MockData.earningsTrend;

  @override
  Future<List<Payout>> fetchPayouts(String hostId) async => MockData.payouts();

  @override
  Future<Map<String, dynamic>> fetchEarningsSummary(String hostId) async => {
    'earned': 520.0,
    'inTransit': 736.0,
    'scheduled': 208.0,
    'lifetimeGross': 1464.0,
    'seatsSold': 30,
    'averageSeatPrice': 48.8,
  };

  // ── Restaurants ─────────────────────────────────────────────────────────
  @override
  Future<List<Restaurant>> fetchRestaurants({
    bool partner = false,
    String? q,
  }) async => MockData.restaurants;

  @override
  Future<Map<String, dynamic>> fetchRestaurantDetail(String id) async => {};
}
