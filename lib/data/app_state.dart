import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/dine_api.dart';
import '../core/config.dart';
import '../models/booking.dart';
import '../models/dinner_event.dart';
import '../models/restaurant.dart';
import '../models/social.dart';
import '../models/user.dart';

/// How the discover feed is currently filtered.
enum FeedSort { soonest, priceLow, priceHigh, bestRated }

/// The single source of truth for the app.
///
/// All data flows through here from the API. Mutations notify listeners so the
/// whole widget tree rebuilds on change. [bootstrap] restores the session
/// token from [SharedPreferences] and pre-loads every domain in parallel.
class AppState extends ChangeNotifier {
  AppState(this._api);

  final DineApi _api;

  // ── Session ──────────────────────────────────────────────────────────────
  AppUser? _me;
  bool _onboardingSeen = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _bootstrapped = false;
  bool _booting = false;

  AppUser? get me => _me;
  bool get signedIn => _me != null;
  bool get onboardingSeen => _onboardingSeen;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get bootstrapped => _bootstrapped;
  bool get booting => _booting;

  void completeOnboarding() {
    _onboardingSeen = true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ── Bootstrap ────────────────────────────────────────────────────────────

  /// Restore token from disk, verify it, then load all domains.
  Future<void> bootstrap() async {
    if (_booting) return;
    _booting = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(DcConfig.tokenKey);
      if (token != null && token.isNotEmpty) {
        // Inject token into the API client before calling /auth/me.
        if (_api is ApiClient) {
          _api.setToken(token);
        }
        try {
          _me = await _api.me();
          await loadAll();
        } catch (_) {
          // Token expired or invalid — clear it.
          await prefs.remove(DcConfig.tokenKey);
          if (_api is ApiClient) {
            _api.setToken(null);
          }
        }
      }
      final seen = prefs.getBool('dc_onboarding_seen');
      if (seen == true) _onboardingSeen = true;
    } finally {
      _booting = false;
      _bootstrapped = true;
      notifyListeners();
    }
  }

  /// Persist onboarding-seen flag.
  Future<void> persistOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dc_onboarding_seen', _onboardingSeen);
  }

  /// Load every domain in parallel. Called after sign-in and bootstrap.
  Future<void> loadAll() async {
    await Future.wait([
      refreshEvents(),
      refreshVenues(),
      refreshBookings(),
      refreshActivity(),
      refreshSaved(),
      if (_me != null) refreshPayouts(_me!.id),
    ]);
  }

  Future<void> refresh() => loadAll();

  // ── Loading / error flags ────────────────────────────────────────────────
  bool _eventsLoading = false;
  bool _venuesLoading = false;
  bool _bookingsLoading = false;
  bool get activityLoading => _activityLoading;
  bool _activityLoading = false;
  String? _eventsError;
  String? _venuesError;
  String? _bookingsError;

  bool get eventsLoading => _eventsLoading;
  bool get venuesLoading => _venuesLoading;
  bool get bookingsLoading => _bookingsLoading;
  String? get eventsError => _eventsError;
  String? get venuesError => _venuesError;
  String? get bookingsError => _bookingsError;

  // ── Caches ───────────────────────────────────────────────────────────────
  List<DinnerEvent> _events = [];
  List<Restaurant> _restaurants = [];
  final Map<String, AppUser> _userCache = {};
  List<Booking> _bookings = [];
  List<Payout> _payouts = [];
  List<EarningsPoint> _trend = [];
  Map<String, dynamic> _earningsSummary = {};
  List<Review> _reviews = [];

  // ── Identity ─────────────────────────────────────────────────────────────

  AppUser user(String id) =>
      _userCache[id] ??
      AppUser(
        id: id,
        name: 'Unknown',
        handle: '',
        city: '',
        bio: '',
        followers: 0,
        following: 0,
        dinnersHosted: 0,
        dinnersJoined: 0,
        rating: 0,
        reviewCount: 0,
      );

  Restaurant venue(String id) => _restaurants.firstWhere(
    (r) => r.id == id,
    orElse: () => _restaurants.isEmpty
        ? Restaurant(
            id: id,
            name: 'Unknown',
            cuisine: '',
            neighborhood: '',
            address: '',
            rating: 0,
            reviewCount: 0,
            priceLevel: 1,
            distanceMeters: 0,
            heroAsset: '',
            description: '',
          )
        : _restaurants.first,
  );

  DinnerEvent event(String id) =>
      _events.firstWhere((e) => e.id == id, orElse: () => _events.first);

  bool hasEvent(String id) => _events.any((e) => e.id == id);

  List<AppUser> get influencers =>
      _userCache.values.where((u) => u.isInfluencer).toList(growable: false);

  List<AppUser> get otherHosts => _userCache.values
      .where((u) => u.id != _me?.id && u.dinnersHosted > 0)
      .toList(growable: false);

  Restaurant restaurantFor(DinnerEvent e) {
    // Use embedded name if available, otherwise fall back to cache.
    if (e.restaurantName != null &&
        !_restaurants.any((r) => r.id == e.restaurantId)) {
      return Restaurant(
        id: e.restaurantId,
        name: e.restaurantName!,
        cuisine: '',
        neighborhood: e.restaurantNeighborhood ?? '',
        address: '',
        rating: 0,
        reviewCount: 0,
        priceLevel: 1,
        distanceMeters: 0,
        heroAsset: '',
        description: '',
      );
    }
    return venue(e.restaurantId);
  }

  AppUser hostOf(DinnerEvent e) {
    if (_userCache.containsKey(e.hostId)) return _userCache[e.hostId]!;
    if (e.hostName != null) {
      return AppUser(
        id: e.hostId,
        name: e.hostName!,
        handle: e.hostHandle ?? '',
        city: '',
        bio: '',
        followers: 0,
        following: 0,
        dinnersHosted: 0,
        dinnersJoined: 0,
        rating: 0,
        reviewCount: 0,
        avatarAsset: e.hostAvatarAsset,
      );
    }
    return user(e.hostId);
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestOtp(String phone) =>
      _api.requestOtp(phone);

  Future<void> signIn(String phone, String code) async {
    final result = await _api.verifyOtp(phone, code);
    final token = result['token'] as String?;
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(DcConfig.tokenKey, token);
    }
    _me = AppUser.fromJson(result['user'] as Map<String, dynamic>);
    _userCache[_me!.id] = _me!;
    await loadAll();
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _api.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(DcConfig.tokenKey);
    _me = null;
    _events = [];
    _bookings = [];
    _payouts = [];
    _trend = [];
    _reviews = [];
    _activity = [];
    _saved = {};
    _following = {};
    _threads.clear();
    notifyListeners();
  }

  // ── Catalogue ────────────────────────────────────────────────────────────

  Future<void> refreshEvents() async {
    _eventsLoading = true;
    _eventsError = null;
    notifyListeners();
    try {
      _events = await _api.fetchEvents();
      // Cache any host info embedded in events.
      for (final e in _events) {
        if (e.hostName != null && !_userCache.containsKey(e.hostId)) {
          _userCache[e.hostId] = AppUser(
            id: e.hostId,
            name: e.hostName!,
            handle: e.hostHandle ?? '',
            city: '',
            bio: '',
            followers: 0,
            following: 0,
            dinnersHosted: 0,
            dinnersJoined: 0,
            rating: 0,
            reviewCount: 0,
            avatarAsset: e.hostAvatarAsset,
          );
        }
      }
    } catch (e) {
      _eventsError = e.toString();
    } finally {
      _eventsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshVenues() async {
    _venuesLoading = true;
    _venuesError = null;
    notifyListeners();
    try {
      _restaurants = await _api.fetchRestaurants();
    } catch (e) {
      _venuesError = e.toString();
    } finally {
      _venuesLoading = false;
      notifyListeners();
    }
  }

  List<DinnerEvent> get allEvents => List.unmodifiable(_events);

  List<DinnerEvent> get upcomingEvents =>
      _events.where((e) => e.isUpcoming).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  List<DinnerEvent> get featuredEvents =>
      upcomingEvents.where((e) => e.isFeatured).toList(growable: false);

  List<DinnerEvent> get openEvents =>
      upcomingEvents.where((e) => !e.isSoldOut).toList(growable: false);

  /// Tables that can still be booked, closest first.
  List<DinnerEvent> get nearbyEvents {
    final list = openEvents.toList()
      ..sort(
        (a, b) =>
            restaurantFor(a).distanceMeters
                .compareTo(restaurantFor(b).distanceMeters),
      );
    return list;
  }

  List<DinnerEvent> byHost(String hostId) =>
      (List<DinnerEvent>.from(_events)
            ..sort((a, b) => a.start.compareTo(b.start)))
          .where((e) => e.hostId == hostId)
          .toList(growable: false);

  List<DinnerEvent> atVenue(String restaurantId) => upcomingEvents
      .where((e) => e.restaurantId == restaurantId)
      .toList(growable: false);

  List<Restaurant> get partnerVenues =>
      _restaurants.where((r) => r.isPartner).toList(growable: false);

  List<Restaurant> get allVenues => List.unmodifiable(_restaurants);

  /// Distinct cuisines present in the catalogue, for the filter rail.
  List<String> get cuisines {
    final set = <String>{};
    for (final venue in _restaurants) {
      set.add(venue.cuisine.split(' ').first);
    }
    return set.toList()..sort();
  }

  // ── Discover filtering ───────────────────────────────────────────────────
  ExperienceType? _typeFilter;
  String _cuisineFilter = 'All';
  String _query = '';
  bool _onlyAvailable = true;
  bool _onlyPartners = false;
  FeedSort _sort = FeedSort.soonest;

  ExperienceType? get typeFilter => _typeFilter;
  String get cuisineFilter => _cuisineFilter;
  String get query => _query;
  bool get onlyAvailable => _onlyAvailable;
  bool get onlyPartners => _onlyPartners;
  FeedSort get sort => _sort;

  bool get hasActiveFilters =>
      _typeFilter != null ||
      _cuisineFilter != 'All' ||
      _onlyPartners ||
      !_onlyAvailable;

  void setTypeFilter(ExperienceType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCuisineFilter(String cuisine) {
    _cuisineFilter = cuisine;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setOnlyAvailable(bool value) {
    _onlyAvailable = value;
    notifyListeners();
  }

  void setOnlyPartners(bool value) {
    _onlyPartners = value;
    notifyListeners();
  }

  void setSort(FeedSort value) {
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _typeFilter = null;
    _cuisineFilter = 'All';
    _onlyPartners = false;
    _onlyAvailable = true;
    _sort = FeedSort.soonest;
    notifyListeners();
  }

  /// Applies the active discover filters, then sorts the result.
  List<DinnerEvent> get filteredEvents {
    final needle = _query.trim().toLowerCase();
    final list = upcomingEvents.where((event) {
      if (_onlyAvailable && event.isSoldOut) return false;
      if (_typeFilter != null && event.type != _typeFilter) return false;
      if (_onlyPartners && !restaurantFor(event).isPartner) return false;
      if (_cuisineFilter != 'All') {
        final v = restaurantFor(event);
        if (!v.cuisine.toLowerCase().contains(_cuisineFilter.toLowerCase())) {
          return false;
        }
      }
      if (needle.isNotEmpty) {
        final haystack = [
          event.title,
          event.tagline,
          hostOf(event).name,
          restaurantFor(event).name,
          restaurantFor(event).neighborhood,
          event.type.label,
          ...event.tags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(needle)) return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case FeedSort.soonest:
        list.sort((a, b) => a.start.compareTo(b.start));
      case FeedSort.priceLow:
        list.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
      case FeedSort.priceHigh:
        list.sort((a, b) => b.pricePerSeat.compareTo(a.pricePerSeat));
      case FeedSort.bestRated:
        list.sort(
          (a, b) => restaurantFor(b).rating.compareTo(restaurantFor(a).rating),
        );
    }
    return list;
  }

  // ── Saved tables ─────────────────────────────────────────────────────────
  Set<String> _saved = {};

  Set<String> get savedIds => Set.unmodifiable(_saved);
  bool isSaved(String eventId) => _saved.contains(eventId);

  List<DinnerEvent> get savedEvents =>
      _events.where((e) => _saved.contains(e.id)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  Future<void> refreshSaved() async {
    try {
      final list = await _api.fetchSaved();
      _saved = list.map((e) => e.id).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleSaved(String eventId) async {
    final wasSaved = _saved.contains(eventId);
    if (wasSaved) {
      _saved.remove(eventId);
      notifyListeners();
      try {
        await _api.unsaveEvent(eventId);
      } catch (_) {
        _saved.add(eventId);
        notifyListeners();
      }
    } else {
      _saved.add(eventId);
      notifyListeners();
      try {
        await _api.saveEvent(eventId);
      } catch (_) {
        _saved.remove(eventId);
        notifyListeners();
      }
    }
  }

  // ── Following ────────────────────────────────────────────────────────────
  Set<String> _following = {};

  bool isFollowing(String userId) => _following.contains(userId);
  Set<String> get followingIds => Set.unmodifiable(_following);

  Future<void> toggleFollow(String userId) async {
    final wasFollowing = _following.contains(userId);
    if (wasFollowing) {
      _following.remove(userId);
      notifyListeners();
      try {
        await _api.unfollowUser(userId);
      } catch (_) {
        _following.add(userId);
        notifyListeners();
      }
    } else {
      _following.add(userId);
      notifyListeners();
      try {
        await _api.followUser(userId);
      } catch (_) {
        _following.remove(userId);
        notifyListeners();
      }
    }
  }

  // ── Bookings ─────────────────────────────────────────────────────────────

  Future<void> refreshBookings() async {
    _bookingsLoading = true;
    _bookingsError = null;
    notifyListeners();
    try {
      final res = await _api.fetchBookings();
      final all = (res['bookings'] as List<dynamic>)
          .map((b) => Booking.fromJson(b as Map<String, dynamic>))
          .toList();
      _bookings = all;
    } catch (e) {
      _bookingsError = e.toString();
    } finally {
      _bookingsLoading = false;
      notifyListeners();
    }
  }

  List<Booking> get bookings => List.unmodifiable(_bookings);

  List<Booking> get myUpcomingBookings {
    final meId = _me?.id ?? '';
    final list =
        _bookings
            .where(
              (b) =>
                  b.guestId == meId &&
                  b.status != BookingStatus.cancelled &&
                  hasEvent(b.eventId) &&
                  event(b.eventId).isUpcoming,
            )
            .toList()
          ..sort(
            (a, b) => event(a.eventId).start.compareTo(event(b.eventId).start),
          );
    return list;
  }

  List<Booking> get myPastBookings {
    final meId = _me?.id ?? '';
    return _bookings
        .where(
          (b) =>
              b.guestId == meId &&
              (!hasEvent(b.eventId) || !event(b.eventId).isUpcoming),
        )
        .toList()
      ..sort(
        (a, b) => event(b.eventId).start.compareTo(event(a.eventId).start),
      );
  }

  Booking? bookingFor(String eventId) {
    final meId = _me?.id ?? '';
    for (final booking in _bookings) {
      if (booking.eventId == eventId &&
          booking.guestId == meId &&
          booking.status != BookingStatus.cancelled) {
        return booking;
      }
    }
    return null;
  }

  bool hasBooked(String eventId) => bookingFor(eventId) != null;

  /// Seats still purchasable, accounting for the guest's own reservation.
  int seatsLeftFor(String eventId) {
    if (!hasEvent(eventId)) return 0;
    final target = event(eventId);
    final mine = bookingFor(eventId)?.seats ?? 0;
    return (target.seatsLeft + mine).clamp(0, target.seatsTotal);
  }

  /// Commits a reservation via the API and updates local state.
  Future<Booking> book({
    required String eventId,
    required int seats,
    required String paymentLabel,
  }) async {
    final res = await _api.createBooking(
      eventId,
      seats: seats,
      paymentLabel: paymentLabel,
    );
    final booking = Booking.fromJson(res['booking'] as Map<String, dynamic>);

    // Update local event seat count.
    final eventRes = res['event'] as Map<String, dynamic>?;
    if (eventRes != null) {
      final taken = (eventRes['seatsTaken'] as num?)?.toInt() ?? 0;
      final target = event(eventId);
      _replace(target.copyWith(seatsTaken: taken));
    }

    _bookings.removeWhere(
      (b) =>
          b.eventId == eventId &&
          b.guestId == (_me?.id ?? '') &&
          b.status != BookingStatus.cancelled,
    );
    _bookings.add(booking);
    notifyListeners();
    return booking;
  }

  Future<void> cancelBooking(String bookingId) async {
    final res = await _api.cancelBooking(bookingId);
    final bookingRes = res['booking'] as Map<String, dynamic>;
    final id = bookingRes['eventId'] as String;

    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.cancelled,
      );
    }

    final eventRes = res['event'] as Map<String, dynamic>?;
    if (eventRes != null && hasEvent(id)) {
      final taken = (eventRes['seatsTaken'] as num?)?.toInt() ?? 0;
      final target = event(id);
      _replace(target.copyWith(seatsTaken: taken));
    }
    notifyListeners();
  }

  Future<void> checkIn(String bookingId) async {
    await _api.checkIn(bookingId);
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(checkedIn: true);
      notifyListeners();
    }
  }

  // ── Hosting ──────────────────────────────────────────────────────────────

  List<DinnerEvent> get myHostedEvents {
    final meId = _me?.id ?? '';
    return byHost(meId);
  }

  List<DinnerEvent> get myHostedUpcoming =>
      myHostedEvents.where((e) => e.isUpcoming).toList(growable: false);

  List<DinnerEvent> get myHostedPast =>
      myHostedEvents.where((e) => !e.isUpcoming).toList(growable: false);

  Future<void> publish(DinnerEvent draft) async {
    final created = await _api.createEvent(draft.toJson());
    _events.add(created);
    notifyListeners();
  }

  void updateEvent(DinnerEvent event) {
    _replace(event);
    notifyListeners();
  }

  /// Guests joining a host's table, for the host console.
  Future<List<Booking>> guestsFor(String eventId) async {
    return await _api.fetchGuestList(eventId);
  }

  // ── Earnings ─────────────────────────────────────────────────────────────

  Future<void> refreshPayouts(String hostId) async {
    try {
      final results = await Future.wait([
        _api.fetchPayouts(hostId),
        _api.fetchTrend(hostId),
        _api.fetchEarningsSummary(hostId),
      ]);
      _payouts = results[0] as List<Payout>;
      _trend = results[1] as List<EarningsPoint>;
      _earningsSummary = results[2] as Map<String, dynamic>;
      notifyListeners();
    } catch (_) {}
  }

  List<Payout> get payouts =>
      List<Payout>.from(_payouts)..sort((a, b) => b.date.compareTo(a.date));

  List<EarningsPoint> get trend => List.unmodifiable(_trend);

  double get totalEarned =>
      (_earningsSummary['earned'] as num?)?.toDouble() ??
      _payouts
          .where((p) => p.status == PayoutStatus.paid)
          .fold(0.0, (s, p) => s + p.net);

  double get inTransit =>
      (_earningsSummary['inTransit'] as num?)?.toDouble() ??
      _payouts
          .where((p) => p.status == PayoutStatus.inTransit)
          .fold(0.0, (s, p) => s + p.net);

  double get scheduledEarnings =>
      (_earningsSummary['scheduled'] as num?)?.toDouble() ??
      _payouts
          .where((p) => p.status == PayoutStatus.scheduled)
          .fold(0.0, (s, p) => s + p.net);

  double get lifetimeGross =>
      (_earningsSummary['lifetimeGross'] as num?)?.toDouble() ??
      _payouts.fold(0.0, (s, p) => s + p.gross);

  int get seatsSold =>
      (_earningsSummary['seatsSold'] as num?)?.toInt() ??
      _payouts.fold(0, (s, p) => s + p.seatsSold);

  double get averageSeatPrice =>
      (_earningsSummary['averageSeatPrice'] as num?)?.toDouble() ??
      (seatsSold == 0 ? 0 : lifetimeGross / seatsSold);

  double get averageFillRate {
    final fromSummary = (_earningsSummary['averageFillRate'] as num?)
        ?.toDouble();
    if (fromSummary != null) return fromSummary;
    final hosted = myHostedEvents;
    if (hosted.isEmpty) return 0;
    return hosted.fold<double>(0, (sum, e) => sum + e.occupancy) /
        hosted.length;
  }

  DateTime get nextPayoutDate {
    final raw = _earningsSummary['nextPayoutDate'] as String?;
    if (raw != null) {
      return DateTime.tryParse(raw) ??
          DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  // ── Threads ──────────────────────────────────────────────────────────────
  final Map<String, List<ChatMessage>> _threads = {};

  List<ChatMessage> thread(String eventId) => _threads[eventId] ?? const [];

  Future<void> loadThread(String eventId) async {
    try {
      final messages = await _api.fetchMessages(eventId);
      _threads[eventId] = messages;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendMessage(String eventId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final sent = await _api.sendMessage(eventId, trimmed);
    _threads.putIfAbsent(eventId, () => []);
    _threads[eventId]!.add(sent);
    notifyListeners();
  }

  // ── Activity ─────────────────────────────────────────────────────────────
  List<ActivityItem> _activity = [];

  List<ActivityItem> get activity =>
      List<ActivityItem>.from(_activity)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadCount => _activity.where((a) => a.isUnread).length;

  Future<void> refreshActivity() async {
    _activityLoading = true;
    notifyListeners();
    try {
      final res = await _api.fetchActivity();
      final list = (res['activity'] as List<dynamic>?) ?? [];
      _activity = list
          .map((a) => ActivityItem.fromJson(a as Map<String, dynamic>))
          .toList();
      // Cache actor info.
      for (final a in _activity) {
        final actorId = a.actorId;
        if (actorId != null &&
            a.actorName != null &&
            !_userCache.containsKey(actorId)) {
          _userCache[actorId] = AppUser(
            id: actorId,
            name: a.actorName!,
            handle: a.actorHandle ?? '',
            city: '',
            bio: '',
            followers: 0,
            following: 0,
            dinnersHosted: 0,
            dinnersJoined: 0,
            rating: 0,
            reviewCount: 0,
            avatarAsset: a.actorAvatarAsset,
          );
        }
      }
    } catch (_) {}
    _activityLoading = false;
    notifyListeners();
  }

  Future<void> markActivityRead() async {
    await _api.markActivityRead();
    for (var i = 0; i < _activity.length; i++) {
      final item = _activity[i];
      if (item.isUnread) {
        _activity[i] = ActivityItem(
          id: item.id,
          kind: item.kind,
          title: item.title,
          body: item.body,
          createdAt: item.createdAt,
          actorId: item.actorId,
          eventId: item.eventId,
          amount: item.amount,
          actorName: item.actorName,
          actorHandle: item.actorHandle,
          actorAvatarAsset: item.actorAvatarAsset,
        );
      }
    }
    notifyListeners();
  }

  // ── Reviews ──────────────────────────────────────────────────────────────

  Future<void> refreshReviews({String? hostId, String? eventId}) async {
    try {
      final list = await _api.fetchReviews(hostId: hostId, eventId: eventId);
      _reviews = list;
      notifyListeners();
    } catch (_) {}
  }

  List<Review> get reviews =>
      List<Review>.from(_reviews)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Review> reviewsForEvent(String eventId) =>
      reviews.where((r) => r.eventId == eventId).toList(growable: false);

  List<Review> reviewsForHost(String hostId) {
    final hostedIds = byHost(hostId).map((e) => e.id).toSet();
    return reviews
        .where((r) => hostedIds.contains(r.eventId))
        .toList(growable: false);
  }

  Future<Review> submitReview(
    String eventId, {
    required double rating,
    required String text,
  }) async {
    final review = await _api.submitReview(eventId, rating: rating, text: text);
    _reviews.insert(0, review);
    notifyListeners();
    return review;
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String name,
    required String city,
    String bio = '',
    List<String> tastes = const [],
  }) async {
    final updated = await _api.updateProfile(
      name: name,
      city: city,
      bio: bio,
      tastes: tastes,
    );
    _me = updated;
    _userCache[updated.id] = updated;
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchUserProfile(String id) =>
      _api.fetchUserProfile(id);

  // ── Create-dinner draft ──────────────────────────────────────────────────

  double suggestedPrice(Restaurant venue) {
    final base = switch (venue.priceLevel) {
      1 => 32.0,
      2 => 48.0,
      3 => 72.0,
      _ => 105.0,
    };
    return base;
  }

  // ── Internals ────────────────────────────────────────────────────────────

  void _replace(DinnerEvent event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      _events.add(event);
    } else {
      _events[index] = event;
    }
  }

  /// Human-readable summary of the guest's activity, used on the profile.
  String get membershipSummary =>
      'Member since ${_me?.joinedYear ?? DateTime.now().year}';

  /// Test-only: inject a user and load all data without going through auth.
  Future<void> debugSetUser(AppUser user) async {
    _me = user;
    _userCache[user.id] = user;
    await loadAll();
    notifyListeners();
  }
}
