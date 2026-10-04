import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Bundled photography with a graceful fade-in and a branded fallback.
///
/// Wrapping [Image.asset] keeps every surface in the app resilient: if an asset
/// is ever missing the placeholder still matches the design language instead of
/// showing a broken-image glyph.
class DcImage extends StatelessWidget {
  const DcImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.radius,
    this.scrim,
    this.alignment = Alignment.center,
    this.darken = 0,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// When set, the image is clipped to a rounded rectangle.
  final double? radius;

  /// Optional gradient laid over the photo for text legibility.
  final Gradient? scrim;

  final AlignmentGeometry alignment;

  /// 0 – 1 black veil, used to push background photos further back.
  final double darken;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: Motion.slow,
          curve: Motion.enter,
          child: child,
        );
      },
      errorBuilder: (context, error, stack) =>
          _Placeholder(width: width, height: height),
    );

    if (darken > 0) {
      image = Stack(
        fit: StackFit.passthrough,
        children: [
          image,
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: darken)),
          ),
        ],
      );
    }

    if (scrim != null) {
      image = Stack(
        fit: StackFit.passthrough,
        children: [
          image,
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: scrim)),
          ),
        ],
      );
    }

    if (radius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: image,
      );
    }
    return image;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [dc.surfaceSunken, dc.surfaceAlt],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 26,
          color: dc.inkFaint.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// A soft, blurred colour wash used behind headers and empty states.
class DcAurora extends StatelessWidget {
  const DcAurora({super.key, this.colors, this.opacity = 1, this.child});

  final List<Color>? colors;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final palette =
        colors ??
        (dc.isDark
            ? [
                dc.accent.withValues(alpha: 0.28),
                dc.gold.withValues(alpha: 0.14),
                dc.canvas,
              ]
            : [
                dc.accent.withValues(alpha: 0.18),
                dc.gold.withValues(alpha: 0.12),
                dc.canvas,
              ]);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette
              .map((c) => c.withValues(alpha: c.a * opacity))
              .toList(),
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}
