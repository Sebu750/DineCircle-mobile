import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_space.dart';
import 'app_type.dart';

/// Semantic design tokens resolved for the active [Brightness].
///
/// Widgets read these through `context.dc` rather than hard-coding palette
/// values, which keeps light and dark mode perfectly in sync and makes the
/// identity adjustable from one place.
@immutable
class DcTheme extends ThemeExtension<DcTheme> implements DcThemeTokens {
  const DcTheme({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSunken,
    required this.line,
    required this.lineSoft,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.inkInverse,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.onAccent,
    required this.gold,
    required this.goldSoft,
    required this.onGold,
    required this.pine,
    required this.pineSoft,
    required this.onPine,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.scrim,
    required this.skeleton,
    required this.glass,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowFloating,
    required this.accentGradient,
    required this.heroScrim,
    required this.cardScrim,
  });

  final Brightness brightness;

  // ── Surfaces ─────────────────────────────────────────────────────────────
  /// Page background.
  final Color canvas;

  /// Cards, sheets and raised containers.
  final Color surface;

  /// Recessed blocks sitting inside a [surface].
  final Color surfaceAlt;

  /// Deepest neutral — input wells, image placeholders.
  final Color surfaceSunken;

  /// Hairline borders and dividers.
  final Color line;

  /// Barely-there separators inside dense lists.
  final Color lineSoft;

  // ── Text ─────────────────────────────────────────────────────────────────
  @override
  final Color ink;
  @override
  final Color inkMuted;
  @override
  final Color inkFaint;

  /// Copy placed on top of imagery or dark chrome.
  final Color inkInverse;

  // ── Brand ────────────────────────────────────────────────────────────────
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color onAccent;
  final Color gold;
  final Color goldSoft;
  final Color onGold;
  final Color pine;
  final Color pineSoft;
  final Color onPine;

  // ── Status ───────────────────────────────────────────────────────────────
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  // ── Effects ──────────────────────────────────────────────────────────────
  final Color scrim;
  final Color skeleton;

  /// Translucent surface used behind backdrop-blurred chrome.
  final Color glass;

  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowFloating;

  /// Rich brand wash — used for premium surfaces and host highlights.
  final LinearGradient accentGradient;

  /// Readability scrim laid over full-bleed hero photography.
  final LinearGradient heroScrim;

  /// Lighter scrim used inside compact image cards.
  final LinearGradient cardScrim;

  bool get isDark => brightness == Brightness.dark;

  @override
  DcTheme copyWith() => this;

  @override
  DcTheme lerp(covariant DcTheme? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return DcTheme(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      line: mix(line, other.line),
      lineSoft: mix(lineSoft, other.lineSoft),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkFaint: mix(inkFaint, other.inkFaint),
      inkInverse: mix(inkInverse, other.inkInverse),
      accent: mix(accent, other.accent),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccent: mix(onAccent, other.onAccent),
      gold: mix(gold, other.gold),
      goldSoft: mix(goldSoft, other.goldSoft),
      onGold: mix(onGold, other.onGold),
      pine: mix(pine, other.pine),
      pineSoft: mix(pineSoft, other.pineSoft),
      onPine: mix(onPine, other.onPine),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      info: mix(info, other.info),
      infoSoft: mix(infoSoft, other.infoSoft),
      scrim: mix(scrim, other.scrim),
      skeleton: mix(skeleton, other.skeleton),
      glass: mix(glass, other.glass),
      shadowSm: t < 0.5 ? shadowSm : other.shadowSm,
      shadowMd: t < 0.5 ? shadowMd : other.shadowMd,
      shadowLg: t < 0.5 ? shadowLg : other.shadowLg,
      shadowFloating: t < 0.5 ? shadowFloating : other.shadowFloating,
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
      heroScrim: LinearGradient.lerp(heroScrim, other.heroScrim, t)!,
      cardScrim: LinearGradient.lerp(cardScrim, other.cardScrim, t)!,
    );
  }

  /// The warm, luminous palette — daylight dining.
  static const DcTheme light = DcTheme(
    brightness: Brightness.light,
    canvas: AppColors.cream100,
    surface: AppColors.white,
    surfaceAlt: AppColors.cream200,
    surfaceSunken: AppColors.cream300,
    line: AppColors.cream300,
    lineSoft: AppColors.cream200,
    ink: AppColors.espresso900,
    inkMuted: AppColors.espresso500,
    inkFaint: AppColors.espresso400,
    inkInverse: AppColors.cream50,
    accent: AppColors.clay500,
    accentPressed: AppColors.clay600,
    accentSoft: AppColors.clay100,
    onAccent: AppColors.white,
    gold: AppColors.gold500,
    goldSoft: AppColors.gold100,
    onGold: AppColors.gold900,
    pine: AppColors.pine600,
    pineSoft: AppColors.pine50,
    onPine: AppColors.white,
    success: AppColors.pine500,
    successSoft: AppColors.pine50,
    danger: AppColors.danger500,
    dangerSoft: Color(0xFFFAE4E0),
    info: AppColors.info500,
    infoSoft: Color(0xFFE3EEF5),
    scrim: Color(0x66120C08),
    skeleton: AppColors.cream300,
    glass: Color(0xE6FDFBF8),
    shadowSm: Elevation.sm,
    shadowMd: Elevation.md,
    shadowLg: Elevation.lg,
    shadowFloating: Elevation.floating,
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD0663A), Color(0xFF9E3F1B)],
    ),
    heroScrim: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x1F120C08), Color(0xCC120C08)],
      stops: [0.30, 0.58, 1.0],
    ),
    cardScrim: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x8F120C08)],
      stops: [0.42, 1.0],
    ),
  );

  /// The night palette — candlelit, low-light dining rooms.
  static const DcTheme dark = DcTheme(
    brightness: Brightness.dark,
    canvas: AppColors.night950,
    surface: AppColors.night800,
    surfaceAlt: AppColors.night700,
    surfaceSunken: AppColors.night900,
    line: AppColors.night600,
    lineSoft: AppColors.night700,
    ink: AppColors.night100,
    inkMuted: AppColors.night200,
    inkFaint: AppColors.night300,
    inkInverse: AppColors.espresso900,
    accent: AppColors.clay400,
    accentPressed: AppColors.clay500,
    accentSoft: Color(0xFF3B2418),
    onAccent: AppColors.espresso900,
    gold: AppColors.gold400,
    goldSoft: Color(0xFF3A2C12),
    onGold: AppColors.gold900,
    pine: AppColors.pine200,
    pineSoft: Color(0xFF1E2E24),
    onPine: AppColors.pine900,
    success: Color(0xFF79BA92),
    successSoft: Color(0xFF1C2C22),
    danger: AppColors.danger400,
    dangerSoft: Color(0xFF3A1E1A),
    info: AppColors.info400,
    infoSoft: Color(0xFF17262F),
    scrim: Color(0x99000000),
    skeleton: AppColors.night600,
    glass: Color(0xE61C1815),
    shadowSm: Elevation.darkMd,
    shadowMd: Elevation.darkMd,
    shadowLg: Elevation.darkFloating,
    shadowFloating: Elevation.darkFloating,
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE0804F), Color(0xFFB24B21)],
    ),
    heroScrim: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x33000000), Color(0xE6000000)],
      stops: [0.30, 0.58, 1.0],
    ),
    cardScrim: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0xA6000000)],
      stops: [0.42, 1.0],
    ),
  );
}

/// Convenient access to design tokens from any widget.
extension DcBuildContext on BuildContext {
  /// Semantic colour, elevation and gradient tokens.
  DcTheme get dc => Theme.of(this).extension<DcTheme>()!;

  /// Type scale.
  TextTheme get text => Theme.of(this).textTheme;

  /// Material colour roles.
  ColorScheme get colors => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Assembles the full Material theme on top of the DineCircle tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(DcTheme.light);
  static ThemeData dark() => _build(DcTheme.dark);

  /// Builds the [ThemeData] used by both brightnesses.
  static ThemeData _build(DcTheme dc) {
    final textTheme = AppType.textTheme(dc);

    final scheme = ColorScheme(
      brightness: dc.brightness,
      primary: dc.accent,
      onPrimary: dc.onAccent,
      primaryContainer: dc.accentSoft,
      onPrimaryContainer: dc.isDark ? dc.accent : AppColors.clay700,
      secondary: dc.gold,
      onSecondary: dc.onGold,
      secondaryContainer: dc.goldSoft,
      onSecondaryContainer: dc.isDark ? dc.gold : AppColors.gold600,
      tertiary: dc.pine,
      onTertiary: dc.onPine,
      tertiaryContainer: dc.pineSoft,
      onTertiaryContainer: dc.isDark ? dc.pine : AppColors.pine600,
      error: dc.danger,
      onError: dc.isDark ? AppColors.espresso900 : AppColors.white,
      errorContainer: dc.dangerSoft,
      onErrorContainer: dc.danger,
      surface: dc.surface,
      onSurface: dc.ink,
      onSurfaceVariant: dc.inkMuted,
      surfaceContainerLowest: dc.canvas,
      surfaceContainerLow: dc.surface,
      surfaceContainer: dc.surfaceAlt,
      surfaceContainerHigh: dc.surfaceAlt,
      surfaceContainerHighest: dc.surfaceSunken,
      outline: dc.inkFaint,
      outlineVariant: dc.line,
      scrim: dc.scrim,
      inverseSurface: dc.isDark ? AppColors.cream200 : AppColors.espresso800,
      onInverseSurface: dc.isDark ? AppColors.espresso900 : AppColors.cream100,
      inversePrimary: dc.isDark ? AppColors.clay500 : AppColors.clay400,
      shadow: AppColors.black,
      surfaceTint: AppColors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dc.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dc.canvas,
      canvasColor: dc.canvas,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: dc.accent.withValues(alpha: 0.08),
      highlightColor: dc.accent.withValues(alpha: 0.04),
      dividerColor: dc.line,
      dividerTheme: DividerThemeData(color: dc.line, thickness: 1, space: 1),
      extensions: [dc],

      iconTheme: IconThemeData(color: dc.ink, size: 22),
      primaryIconTheme: IconThemeData(color: dc.onAccent, size: 22),

      appBarTheme: AppBarThemeData(
        backgroundColor: dc.canvas,
        surfaceTintColor: AppColors.transparent,
        foregroundColor: dc.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: dc.ink, size: 22),
        actionsIconTheme: IconThemeData(color: dc.ink, size: 22),
        toolbarHeight: 60,
      ),

      cardTheme: CardThemeData(
        color: dc.surface,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? dc.accentPressed
                : dc.accent,
          ),
          foregroundColor: WidgetStatePropertyAll(dc.onAccent),
          overlayColor: WidgetStatePropertyAll(
            dc.onAccent.withValues(alpha: 0.10),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(64, 54)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.xxl, vertical: Space.md),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(dc.surface),
          foregroundColor: WidgetStatePropertyAll(dc.ink),
          overlayColor: WidgetStatePropertyAll(
            dc.accent.withValues(alpha: 0.06),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(64, 54)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.xxl, vertical: Space.md),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: dc.line, width: 1.2)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(dc.accent),
          overlayColor: WidgetStatePropertyAll(
            dc.accent.withValues(alpha: 0.08),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(dc.ink),
          overlayColor: WidgetStatePropertyAll(dc.ink.withValues(alpha: 0.06)),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: dc.surfaceAlt,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: dc.inkFaint),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: AppType.sans(
          13,
          weight: 600,
          color: dc.accent,
          tracking: 0.2,
        ),
        prefixIconColor: dc.inkFaint,
        suffixIconColor: dc.inkFaint,
        border: _inputBorder(dc.line, 1.2),
        enabledBorder: _inputBorder(Colors.transparent, 1.2),
        focusedBorder: _inputBorder(dc.accent, 1.6),
        errorBorder: _inputBorder(dc.danger, 1.2),
        focusedErrorBorder: _inputBorder(dc.danger, 1.6),
        errorStyle: AppType.sans(12, color: dc.danger),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: dc.surface,
        surfaceTintColor: AppColors.transparent,
        selectedColor: dc.ink,
        checkmarkColor: dc.canvas,
        side: BorderSide(color: dc.line, width: 1.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: dc.canvas),
        elevation: 0,
        pressElevation: 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dc.surface,
        surfaceTintColor: AppColors.transparent,
        modalBackgroundColor: dc.surface,
        modalBarrierColor: dc.scrim.withValues(alpha: 0.55),
        elevation: 0,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: dc.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: Space.xxl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: dc.isDark ? AppColors.night700 : AppColors.espresso800,
        contentTextStyle: AppType.sans(
          14,
          weight: 500,
          color: AppColors.cream100,
        ),
        actionTextColor: dc.isDark ? dc.gold : AppColors.gold400,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(Space.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dc.accent,
        linearTrackColor: dc.surfaceSunken,
        circularTrackColor: dc.surfaceSunken,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: dc.accent,
        inactiveTrackColor: dc.surfaceSunken,
        thumbColor: dc.surface,
        overlayColor: dc.accent.withValues(alpha: 0.12),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 3,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? dc.surface : dc.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? dc.accent
              : dc.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? dc.accent : dc.line,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: dc.inkMuted,
        textColor: dc.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dc.isDark ? AppColors.night700 : AppColors.espresso800,
          borderRadius: BorderRadius.circular(Radii.xs),
        ),
        textStyle: AppType.sans(12, weight: 500, color: AppColors.cream100),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
