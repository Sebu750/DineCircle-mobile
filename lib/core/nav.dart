import 'package:flutter/material.dart';

import '../screens/chat_screen.dart';
import '../screens/create_dinner_screen.dart';
import '../screens/dinner_detail_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/earnings_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/host_profile_screen.dart';
import '../screens/my_tables_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../screens/venue_screen.dart';

/// Cross-screen navigation, kept in one place so no screen needs to import
/// another. Page transitions come from the theme.
abstract final class Go {
  static Future<T?> _push<T>(BuildContext context, Widget screen) {
    return Navigator.of(context)
        .push<T>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  /// The full search and filter surface.
  static Future<void> search(BuildContext context) =>
      _push(context, const SearchScreen());

  /// A single table, with the menu, the host and the reserve bar.
  static Future<void> dinner(BuildContext context, String eventId) =>
      _push(context, DinnerDetailScreen(eventId: eventId));

  /// A restaurant profile, with the tables open there.
  static Future<void> venue(BuildContext context, String venueId) =>
      _push(context, VenueScreen(venueId: venueId));

  /// The browse surface, used when a "See all" action needs a full screen.
  static Future<void> browse(BuildContext context, {int tab = 0}) =>
      _push(context, ExploreScreen(initialTab: tab));

  /// The host wizard for building a new table.
  static Future<void> create(BuildContext context) =>
      _push(context, const CreateDinnerScreen());

  /// The guest's tickets, host console and earnings.
  static Future<void> tables(BuildContext context) =>
      _push(context, const MyTablesScreen());

  /// The guest's own profile.
  static Future<void> profile(BuildContext context) =>
      _push(context, const ProfileScreen());

  /// A host's public profile — bio, stats, follow, tables, reviews.
  static Future<void> host(BuildContext context, String userId) =>
      _push(context, HostProfileScreen(userId: userId));

  /// The table's group chat thread.
  static Future<void> chat(BuildContext context, String eventId) =>
      _push(context, ChatScreen(eventId: eventId));

  /// The activity / notifications feed.
  static Future<void> notifications(BuildContext context) =>
      _push(context, const NotificationsScreen());

  /// Edit the signed-in user's profile.
  static Future<void> editProfile(BuildContext context) =>
      _push(context, const EditProfileScreen());

  /// The host earnings dashboard.
  static Future<void> earnings(BuildContext context) =>
      _push(context, const EarningsScreen());
}
