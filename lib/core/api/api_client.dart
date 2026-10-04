import 'dart:convert';

import 'package:http/http.dart';

import '../config.dart';
import '../../models/booking.dart';
import '../../models/dinner_event.dart';
import '../../models/restaurant.dart';
import '../../models/social.dart';
import '../../models/user.dart';
import 'dine_api.dart';

/// Concrete [DineApi] backed by `package:http` JSON calls against the
/// local Express server. Holds the session token and attaches it as a
/// `Bearer` header on every authenticated request.
class ApiClient implements DineApi {
  ApiClient({Client? client}) : _client = client ?? Client();

  final Client _client;
  String? _token;

  String get baseUrl => DcConfig.apiBase;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  // ── HTTP primitives ────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final encoded = body != null ? jsonEncode(body) : null;
    final Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: _headers);
      case 'POST':
        response = await _client.post(uri, headers: _headers, body: encoded);
      case 'PATCH':
        response = await _client.patch(uri, headers: _headers, body: encoded);
      case 'DELETE':
        response = await _client.delete(uri, headers: _headers);
      default:
        throw UnsupportedError(method);
    }

    if (response.statusCode >= 400) {
      String message;
      try {
        message =
            (jsonDecode(response.body) as Map)['error']?.toString() ??
            'Request failed';
      } catch (_) {
        message = response.body.isNotEmpty
            ? response.body
            : 'HTTP ${response.statusCode}';
      }
      throw ApiException(response.statusCode, message);
    }

    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  // ── Auth ────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await post('/api/auth/otp/request', {'phone': phone});
    return res as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await post('/api/auth/otp/verify', {
      'phone': phone,
      'code': code,
    });
    final map = res as Map<String, dynamic>;
    _token = map['token'] as String?;
    return map;
  }

  @override
  Future<AppUser> me() async {
    final res = await get('/api/auth/me');
    return AppUser.fromJson(
      (res as Map<String, dynamic>)['user'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> signOut() async {
    await post('/api/auth/signout');
    _token = null;
  }

  // ── Events ──────────────────────────────────────────────────────────────

  @override
  Future<List<DinnerEvent>> fetchEvents({
    String? type,
    String? hostId,
    String? venueId,
    bool upcoming = true,
    String? q,
  }) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (hostId != null) params['hostId'] = hostId;
    if (venueId != null) params['venueId'] = venueId;
    if (!upcoming) params['upcoming'] = 'false';
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = '/api/events${query.isEmpty ? '' : '?$query'}';
    final res = await get(path);
    final list = (res as Map<String, dynamic>)['events'] as List<dynamic>;
    return list
        .map((e) => DinnerEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> fetchEventDetail(String id) async {
    final res = await get('/api/events/$id');
    return res as Map<String, dynamic>;
  }

  @override
  Future<DinnerEvent> createEvent(Map<String, dynamic> payload) async {
    final res = await post('/api/events', payload);
    final map = res as Map<String, dynamic>;
    return DinnerEvent.fromJson(map['event'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEvent(String id) => delete('/api/events/$id');

  // ── Bookings ────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> fetchBookings({String? guestId}) async {
    final path = guestId != null
        ? '/api/bookings?guestId=${Uri.encodeComponent(guestId)}'
        : '/api/bookings';
    final res = await get(path);
    return res as Map<String, dynamic>;
  }

  @override
  Future<List<Booking>> fetchGuestList(String eventId) async {
    final res = await get(
      '/api/bookings?eventId=${Uri.encodeComponent(eventId)}',
    );
    final list = (res as Map<String, dynamic>)['bookings'] as List<dynamic>;
    return list
        .map((b) => Booking.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createBooking(
    String eventId, {
    required int seats,
    required String paymentLabel,
  }) async {
    final res = await post('/api/events/$eventId/bookings', {
      'seats': seats,
      'paymentLabel': paymentLabel,
    });
    return res as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> cancelBooking(String id) async {
    final res = await post('/api/bookings/$id/cancel');
    return res as Map<String, dynamic>;
  }

  @override
  Future<void> checkIn(String bookingId) async {
    await post('/api/bookings/$bookingId/checkin');
  }

  // ── Reviews ─────────────────────────────────────────────────────────────

  @override
  Future<List<Review>> fetchReviews({String? hostId, String? eventId}) async {
    final params = <String, String>{};
    if (hostId != null) params['hostId'] = hostId;
    if (eventId != null) params['eventId'] = eventId;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = '/api/reviews${query.isEmpty ? '' : '?$query'}';
    final res = await get(path);
    final list = (res as Map<String, dynamic>)['reviews'] as List<dynamic>;
    return list.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<Review> submitReview(
    String eventId, {
    required double rating,
    required String text,
  }) async {
    final res = await post('/api/events/$eventId/reviews', {
      'rating': rating,
      'text': text,
    });
    return Review.fromJson(
      (res as Map<String, dynamic>)['review'] as Map<String, dynamic>,
    );
  }

  // ── Saved ───────────────────────────────────────────────────────────────

  @override
  Future<List<DinnerEvent>> fetchSaved() async {
    final res = await get('/api/me/saved');
    final list = (res as Map<String, dynamic>)['saved'] as List<dynamic>;
    return list
        .map((e) => DinnerEvent.fromJsonSaved(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveEvent(String eventId) => post('/api/events/$eventId/save');

  @override
  Future<void> unsaveEvent(String eventId) =>
      delete('/api/events/$eventId/save');

  // ── Users / Follows ────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> fetchUserProfile(String id) async {
    final res = await get('/api/users/$id');
    return res as Map<String, dynamic>;
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String city,
    String bio = '',
    List<String> tastes = const [],
  }) async {
    final res = await patch('/api/users/me', {
      'name': name,
      'city': city,
      'bio': bio,
      'tastes': tastes,
    });
    return AppUser.fromJson(
      (res as Map<String, dynamic>)['user'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> followUser(String userId) =>
      post('/api/users/$userId/follow').then((r) => r as Map<String, dynamic>);

  @override
  Future<Map<String, dynamic>> unfollowUser(String userId) =>
      delete('/api/users/$userId/follow')
          .then((r) => r as Map<String, dynamic>);

  // ── Activity ────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> fetchActivity() async {
    final res = await get('/api/activity');
    return res as Map<String, dynamic>;
  }

  @override
  Future<void> markActivityRead() => post('/api/activity/read');

  // ── Chat ────────────────────────────────────────────────────────────────

  @override
  Future<List<ChatMessage>> fetchMessages(String eventId) async {
    final res = await get('/api/events/$eventId/messages');
    final list = (res as Map<String, dynamic>)['messages'] as List<dynamic>;
    return list
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(String eventId, String text) async {
    final res = await post('/api/events/$eventId/messages', {'text': text});
    return ChatMessage.fromJson(
      (res as Map<String, dynamic>)['message'] as Map<String, dynamic>,
    );
  }

  // ── Hosts / Earnings ───────────────────────────────────────────────────

  @override
  Future<List<EarningsPoint>> fetchTrend(String hostId) async {
    final res = await get('/api/hosts/$hostId/trend');
    final list = (res as Map<String, dynamic>)['trend'] as List<dynamic>;
    return list
        .map((t) => EarningsPoint.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Payout>> fetchPayouts(String hostId) async {
    final res = await get('/api/hosts/$hostId/payouts');
    final list = (res as Map<String, dynamic>)['payouts'] as List<dynamic>;
    return list.map((p) => Payout.fromJson(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchEarningsSummary(String hostId) async {
    final res = await get('/api/hosts/$hostId/summary');
    return res as Map<String, dynamic>;
  }

  // ── Restaurants ─────────────────────────────────────────────────────────

  @override
  Future<List<Restaurant>> fetchRestaurants({
    bool partner = false,
    String? q,
  }) async {
    final params = <String, String>{};
    if (partner) params['partner'] = 'true';
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = '/api/restaurants${query.isEmpty ? '' : '?$query'}';
    final res = await get(path);
    final list = (res as Map<String, dynamic>)['restaurants'] as List<dynamic>;
    return list
        .map((r) => Restaurant.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> fetchRestaurantDetail(String id) async {
    final res = await get('/api/restaurants/$id');
    return res as Map<String, dynamic>;
  }
}
