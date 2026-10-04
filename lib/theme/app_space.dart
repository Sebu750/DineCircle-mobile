import 'package:flutter/widgets.dart';

/// Layout rhythm for DineCircle — 4pt base grid.
abstract final class Space {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const giant = 56.0;

  /// Standard horizontal gutter for full-width page content.
  static const gutter = 20.0;

  /// Bottom padding that keeps content clear of the floating navigation bar.
  static const navClearance = 108.0;
}

/// Corner radii. Generous rounding is a core part of the visual identity.
abstract final class Radii {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 26.0;
  static const xxl = 34.0;
  static const pill = 999.0;
}

/// Motion tokens — short, confident, never bouncy.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);
  static const page = Duration(milliseconds: 420);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Elevation is expressed as soft, warm-tinted shadows.
abstract final class Elevation {
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0A3A2E25), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x103A2E25), blurRadius: 14, offset: Offset(0, 5)),
    BoxShadow(color: Color(0x083A2E25), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x163A2E25), blurRadius: 26, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A3A2E25), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F2B211A), blurRadius: 44, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x0D2B211A), blurRadius: 10, offset: Offset(0, 3)),
  ];

  /// Floating chrome (nav bar, sticky action bars) picks up a slight glow.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x242B211A), blurRadius: 34, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x142B211A), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Dark surfaces rely on a deep, near-black halo instead of brown tint.
  static const List<BoxShadow> darkMd = [
    BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> darkFloating = [
    BoxShadow(color: Color(0x8A000000), blurRadius: 36, offset: Offset(0, 16)),
  ];
}
