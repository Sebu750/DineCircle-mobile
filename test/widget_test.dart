import 'package:dinecircle/data/app_scope.dart';
import 'package:dinecircle/data/app_state.dart';
import 'package:dinecircle/screens/create_dinner_screen.dart';
import 'package:dinecircle/screens/dinner_detail_screen.dart';
import 'package:dinecircle/screens/explore_screen.dart';
import 'package:dinecircle/screens/my_tables_screen.dart';
import 'package:dinecircle/screens/onboarding_screen.dart';
import 'package:dinecircle/screens/profile_screen.dart';
import 'package:dinecircle/screens/search_screen.dart';
import 'package:dinecircle/screens/shell_screen.dart';
import 'package:dinecircle/screens/splash_screen.dart';
import 'package:dinecircle/screens/venue_screen.dart';
import 'package:dinecircle/theme/theme.dart';
import 'package:dinecircle/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders every surface on a phone-sized canvas. Any overflow, bad asset or
/// broken constraint shows up here as a failed test before it reaches a device.
void main() {
  late AppState state;

  // Real font metrics, so a test only flags an overflow a handset would show
  // rather than the test font's square glyphs.
  setUpAll(() async {
    const families = {
      'PlusJakartaSans': 'assets/fonts/PlusJakartaSans-Variable.ttf',
      'Fraunces': 'assets/fonts/Fraunces-Variable.ttf',
    };
    for (final font in families.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  setUp(() => state = AppState());

  Widget harness(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: child,
      ),
    );
  }

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('splash and onboarding render', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(harness(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('DineCircle'), findsOneWidget);

    await tester.pumpWidget(harness(const OnboardingScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('shell renders every destination', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(harness(const ShellScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nora'), findsWidgets);

    // Labels repeat across screens, so tap the nav bar's own copy.
    Finder navLabel(String label) =>
        find.descendant(of: find.byType(DcNavBar), matching: find.text(label));

    for (final tab in ['Explore', 'Tables', 'Profile', 'Discover']) {
      await tester.tap(navLabel(tab));
      await tester.pumpAndSettle();
    }
    expect(state.signedIn, isFalse); // the shell never signs anyone in
  });

  testWidgets('shell renders in dark mode', (tester) async {
    usePhone(tester);
    state.toggleTheme();
    await tester.pumpWidget(harness(const ShellScreen(), mode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsWidgets);
  });

  testWidgets('table detail opens the join sheet and books a seat', (
    tester,
  ) async {
    usePhone(tester);
    // e1 happens to be sold out in the mock data, so pick the first open
    // event from the store — the one the reserve bar will actually label
    // 'Reserve a seat'.
    final event = state.openEvents.first;
    await tester.pumpWidget(harness(DinnerDetailScreen(eventId: event.id)));
    await tester.pumpAndSettle();

    // The reserve bar lives in the scaffold's bottom bar, always on screen.
    await tester.tap(find.text('Reserve a seat'));
    await tester.pumpAndSettle();
    expect(find.text('Reserve your seat'), findsOneWidget);

    // The pay button sits below the fold of the sheet, so scroll it into view.
    final pay = find.textContaining('Confirm and pay');
    await tester.ensureVisible(pay);
    await tester.pumpAndSettle();
    await tester.tap(pay);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(state.hasBooked(event.id), isTrue);
  });

  testWidgets('venue, search and explore render', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(harness(const VenueScreen(venueId: 'r_bistro')));
    await tester.pumpAndSettle();
    expect(find.text('Maison Lumen'), findsWidgets);

    await tester.pumpWidget(harness(const ExploreScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venues'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hosts'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(harness(const SearchScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('my tables screen renders bookings and earnings', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(harness(const MyTablesScreen()));
    await tester.pumpAndSettle();

    // The earnings panel is visible because the mock data seeds payouts.
    expect(find.text('EARNINGS'), findsOneWidget);
    expect(find.text('My tables'), findsOneWidget);

    // At least one upcoming booking tile is rendered.
    expect(find.textContaining('DC-'), findsWidgets);
  });

  testWidgets('profile screen renders summary and settings', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(harness(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    // The user's name appears in the summary card.
    expect(find.textContaining('Nora'), findsWidgets);
    // Dark mode toggle is present.
    expect(find.text('Dark mode'), findsOneWidget);
  });

  testWidgets('host wizard publishes a table end to end', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(harness(const CreateDinnerScreen()));
    await tester.pumpAndSettle();

    // Step 1 — pick a room.
    await tester.tap(find.text('Maison Lumen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2 — the table, defaults are already valid.
    expect(find.text('Where are you hosting?'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3 — menu: fill it from a template.
    await tester.tap(find.text('Use a template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4 — price, then publish.
    expect(find.text('Publish table'), findsOneWidget);
    final before = state.myHostedEvents.length;
    await tester.tap(find.text('Publish table'));
    await tester.pumpAndSettle();
    expect(state.myHostedEvents.length, before + 1);
    expect(find.text('Your table is live'), findsOneWidget);
  });
}
