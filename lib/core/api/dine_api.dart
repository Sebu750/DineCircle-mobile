import '../../models/booking.dart';
import '../../models/dinner_event.dart';
import '../../models/restaurant.dart';
import '../../models/social.dart';
import '../../models/user.dart';

/// Thrown when the API returns a non-2xx response.
class ApiException implements Exception {
  const ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'ApiException($status): $message';
}

/// Every backend call the app can make, typed end-to-end.
///
/// The concrete implementation lives in `api_client.dart`; tests inject a
/// `FakeDineApi` that mirrors the seed data so the widget suite runs offline.
abstract class DineApi {
  // ── Auth ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String code);
  Future<AppUser> me();
  Future<void> signOut();

  // ── Events ──────────────────────────────────────────────────────────────
  Future<List<DinnerEvent>> fetchEvents({
    String? type,
    String? hostId,
    String? venueId,
    bool upcoming = true,
    String? q,
  });

  /// Full event detail including menu, venue and attendee list.
  Future<Map<String, dynamic>> fetchEventDetail(String id);

  Future<DinnerEvent> createEvent(Map<String, dynamic> payload);
  Future<void> deleteEvent(String id);

  // ── Bookings ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchBookings({String? guestId});
  Future<List<Booking>> fetchGuestList(String eventId);
  Future<Map<String, dynamic>> createBooking(
    String eventId, {
    required int seats,
    required String paymentLabel,
  });

  Future<Map<String, dynamic>> cancelBooking(String id);
  Future<void> checkIn(String bookingId);

  // ── Reviews ─────────────────────────────────────────────────────────────
  Future<List<Review>> fetchReviews({String? hostId, String? eventId});
  Future<Review> submitReview(
    String eventId, {
    required double rating,
    required String text,
  });

  // ── Saved ───────────────────────────────────────────────────────────────
  Future<List<DinnerEvent>> fetchSaved();
  Future<void> saveEvent(String eventId);
  Future<void> unsaveEvent(String eventId);

  // ── Users / Follows ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchUserProfile(String id);
  Future<AppUser> updateProfile({
    required String name,
    required String city,
    String bio = '',
    List<String> tastes = const [],
  });

  Future<Map<String, dynamic>> followUser(String userId);
  Future<Map<String, dynamic>> unfollowUser(String userId);

  // ── Activity ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchActivity();
  Future<void> markActivityRead();

  // ── Chat ────────────────────────────────────────────────────────────────
  Future<List<ChatMessage>> fetchMessages(String eventId);
  Future<ChatMessage> sendMessage(String eventId, String text);

  // ── Hosts / Earnings ───────────────────────────────────────────────────
  Future<List<EarningsPoint>> fetchTrend(String hostId);
  Future<List<Payout>> fetchPayouts(String hostId);
  Future<Map<String, dynamic>> fetchEarningsSummary(String hostId);

  // ── Restaurants ─────────────────────────────────────────────────────────
  Future<List<Restaurant>> fetchRestaurants({bool partner = false, String? q});
  Future<Map<String, dynamic>> fetchRestaurantDetail(String id);
}
