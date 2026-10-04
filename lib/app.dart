import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_scope.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/theme.dart';

/// Root of the DineCircle prototype.
///
/// Owns the [MaterialApp], resolves the two bundled themes and hands the body
/// over to [_RootGate], which routes between onboarding, sign-in and the
/// signed-in shell based on the store.
class DineCircleApp extends StatelessWidget {
  const DineCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;

    return MaterialApp(
      title: 'DineCircle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.themeMode,
      scrollBehavior: const _DcScrollBehavior(),
      home: const _RootGate(),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: app.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Decides which surface the guest should see, and cross-fades between them.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  static const _splashDuration = Duration(milliseconds: 2100);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Wait for the AppState bootstrap to finish, or the splash timeout —
    // whichever comes last — before showing the next surface.
    _timer = Timer(_splashDuration, _maybeDismiss);
    context.app.addListener(_maybeDismiss);
  }

  void _maybeDismiss() {
    final app = context.app;
    if (app.bootstrapped && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    context.app.removeListener(_maybeDismiss);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;

    final Widget screen;
    if (!app.bootstrapped) {
      screen = const SplashScreen(key: ValueKey('splash'));
    } else if (!app.onboardingSeen) {
      screen = const OnboardingScreen(key: ValueKey('onboarding'));
    } else if (!app.signedIn) {
      screen = const AuthScreen(key: ValueKey('auth'));
    } else {
      screen = const ShellScreen(key: ValueKey('shell'));
    }

    return AnimatedSwitcher(
      duration: Motion.page,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: screen,
    );
  }
}

/// Adds drag-to-scroll on desktop and prevents the default glow overscroll
/// from looking out of place on the warm canvas.
class _DcScrollBehavior extends MaterialScrollBehavior {
  const _DcScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
