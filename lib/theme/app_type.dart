import 'package:flutter/material.dart';

/// Font families bundled with the app.
///
/// Both are variable fonts, so every weight is rendered by driving the `wght`
/// axis directly rather than relying on synthetic bolding.
abstract final class DcFont {
  /// Geometric-humanist sans used for all interface and body copy.
  static const sans = 'PlusJakartaSans';

  /// Soft editorial serif reserved for display moments — names, headlines,
  /// prices and section titles.
  static const serif = 'Fraunces';
}

/// The DineCircle type system.
///
/// Two voices: [serif] for editorial warmth, [sans] for clean utility. Both
/// expose numeric weights that map onto variable-font axes.
abstract final class AppType {
  static const _wght = 'wght';
  static const _opsz = 'opsz';

  /// Maps a numeric weight onto the closest [FontWeight] so that text scaling,
  /// accessibility tooling and fallback fonts still behave correctly.
  static FontWeight fontWeightOf(double value) {
    if (value <= 150) return FontWeight.w100;
    if (value <= 250) return FontWeight.w200;
    if (value <= 350) return FontWeight.w300;
    if (value <= 450) return FontWeight.w400;
    if (value <= 550) return FontWeight.w500;
    if (value <= 650) return FontWeight.w600;
    if (value <= 750) return FontWeight.w700;
    if (value <= 850) return FontWeight.w800;
    return FontWeight.w900;
  }

  /// Sans style. Default weight (450) is deliberately between regular and
  /// medium — denser than a standard 400 without feeling heavy.
  static TextStyle sans(
    double size, {
    double weight = 450,
    double height = 1.45,
    double tracking = 0,
    Color? color,
    FontStyle style = FontStyle.normal,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: DcFont.sans,
      fontSize: size,
      height: height,
      letterSpacing: tracking,
      color: color,
      fontStyle: style,
      fontWeight: fontWeightOf(weight),
      decoration: decoration,
      fontVariations: [FontVariation(_wght, weight)],
    );
  }

  /// Serif style. `opticalSize` drives Fraunces' `opsz` axis — higher values
  /// give the high-contrast, drawn look expected of display type.
  static TextStyle serif(
    double size, {
    double weight = 500,
    double? height,
    double? tracking,
    double? opticalSize,
    double soft = 0,
    double wonk = 0,
    Color? color,
    FontStyle style = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: DcFont.serif,
      fontSize: size,
      height: height ?? 1.14,
      letterSpacing: tracking ?? -0.02 * size,
      color: color,
      fontStyle: style,
      fontWeight: fontWeightOf(weight),
      fontVariations: [
        FontVariation(_wght, weight),
        FontVariation(_opsz, (opticalSize ?? size * 1.5).clamp(14, 144)),
        if (soft != 0) FontVariation('SOFT', soft),
        if (wonk != 0) FontVariation('WONK', wonk),
      ],
    );
  }

  /// Uppercase micro-label used for eyebrows and category markers.
  static TextStyle overline({
    double size = 11,
    double weight = 700,
    double tracking = 1.4,
    Color? color,
  }) {
    return sans(
      size,
      weight: weight,
      tracking: tracking,
      height: 1.2,
      color: color,
    );
  }

  /// Full Material text theme wired to the active semantic palette.
  static TextTheme textTheme(DcThemeTokens tokens) {
    final ink = tokens.ink;
    final muted = tokens.inkMuted;
    final faint = tokens.inkFaint;

    return TextTheme(
      // ── Editorial display — serif ──────────────────────────────────────
      displayLarge: serif(
        40,
        weight: 520,
        height: 1.04,
        tracking: -1.1,
        color: ink,
      ),
      displayMedium: serif(
        33,
        weight: 520,
        height: 1.08,
        tracking: -0.9,
        color: ink,
      ),
      displaySmall: serif(
        28,
        weight: 520,
        height: 1.12,
        tracking: -0.7,
        color: ink,
      ),
      headlineLarge: serif(
        24,
        weight: 540,
        height: 1.16,
        tracking: -0.5,
        color: ink,
      ),
      headlineMedium: serif(
        21,
        weight: 540,
        height: 1.22,
        tracking: -0.4,
        color: ink,
      ),
      headlineSmall: serif(
        18.5,
        weight: 560,
        height: 1.28,
        tracking: -0.3,
        color: ink,
      ),

      // ── Interface titles — sans ────────────────────────────────────────
      titleLarge: sans(
        17,
        weight: 660,
        height: 1.32,
        tracking: -0.25,
        color: ink,
      ),
      titleMedium: sans(
        15.5,
        weight: 630,
        height: 1.38,
        tracking: -0.15,
        color: ink,
      ),
      titleSmall: sans(14, weight: 600, height: 1.4, color: ink),

      // ── Body — sans ────────────────────────────────────────────────────
      bodyLarge: sans(15.5, height: 1.58, color: ink),
      bodyMedium: sans(14, height: 1.55, color: muted),
      bodySmall: sans(12.5, height: 1.5, color: faint),

      // ── Labels — sans ──────────────────────────────────────────────────
      labelLarge: sans(
        14.5,
        weight: 650,
        height: 1.2,
        tracking: 0.05,
        color: ink,
      ),
      labelMedium: sans(
        12,
        weight: 640,
        height: 1.2,
        tracking: 0.4,
        color: muted,
      ),
      labelSmall: sans(
        11,
        weight: 700,
        height: 1.2,
        tracking: 0.7,
        color: faint,
      ),
    );
  }
}

/// A minimal, dependency-free view of the theme tokens [AppType] needs.
///
/// Implemented by `DcTheme` so typography can be composed without a circular
/// import between the theme extension and the type system.
abstract interface class DcThemeTokens {
  Color get ink;
  Color get inkMuted;
  Color get inkFaint;
}
