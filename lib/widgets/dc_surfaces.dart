import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'dc_buttons.dart';

/// The base container: warm surface, generous radius, hairline border.
///
/// Every panel in DineCircle is a [DcSurface] so elevation and outlines never
/// drift between screens.
class DcSurface extends StatelessWidget {
  const DcSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = Radii.lg,
    this.color,
    this.borderColor,
    this.showBorder = true,
    this.shadows,
    this.onTap,
    this.clip = false,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool showBorder;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool clip;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final radiusValue = BorderRadius.circular(radius);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? dc.surface) : null,
        gradient: gradient,
        borderRadius: radiusValue,
        border: showBorder
            ? Border.all(color: borderColor ?? dc.line, width: 1)
            : null,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radiusValue,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: dc.accent.withValues(alpha: 0.06),
          highlightColor: dc.accent.withValues(alpha: 0.03),
          child: content,
        ),
      );
    } else if (clip) {
      content = ClipRRect(borderRadius: radiusValue, child: content);
    }

    if (margin != null) return Padding(padding: margin!, child: content);
    return content;
  }
}

/// Section heading with an eyebrow, a serif title and an optional action.
class DcSectionHeader extends StatelessWidget {
  const DcSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      Space.gutter,
      0,
      Space.gutter,
      Space.md,
    ),
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppType.overline(color: dc.accent),
                  ),
                  const SizedBox(height: Space.sm),
                ],
                Text(title, style: context.text.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xs + 2),
                  Text(subtitle!, style: context.text.bodyMedium),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(left: Space.md, bottom: 2),
              child: _SectionAction(label: actionLabel!, onTap: onAction!),
            ),
        ],
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppType.sans(
                13,
                weight: 650,
                tracking: 0.05,
                color: dc.accent,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward_rounded, size: 15, color: dc.accent),
          ],
        ),
      ),
    );
  }
}

/// A horizontally scrolling list with consistent gutters.
class DcRail extends StatelessWidget {
  const DcRail({
    super.key,
    required this.children,
    this.height,
    this.gap = Space.md,
    this.padding,
    this.controller,
  });

  final List<Widget> children;
  final double? height;
  final double gap;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: Space.gutter),
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        // Top-align so a rail taller than its cards leaves room for shadows
        // instead of stretching the cards to fill the viewport.
        itemBuilder: (context, index) =>
            Align(alignment: Alignment.topLeft, child: children[index]),
      ),
    );
  }
}

/// Bottom action bar with a translucent, blurred backdrop.
class DcBottomBar extends StatelessWidget {
  const DcBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      Space.gutter,
      Space.md,
      Space.gutter,
      Space.md,
    ),
    this.blur = true,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool blur;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(top: BorderSide(color: dc.line, width: 1))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (!blur) {
      return ColoredBox(color: dc.surface, child: content);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(color: dc.glass),
          child: content,
        ),
      ),
    );
  }
}

/// Standard bottom-sheet container with a grab handle and an optional title.
class DcSheet extends StatelessWidget {
  const DcSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showHandle = true,
    this.padding = const EdgeInsets.fromLTRB(
      Space.gutter,
      0,
      Space.gutter,
      Space.gutter,
    ),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  /// Presents this sheet, handling the handle, radius and safe area.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: context.dc.surface,
      barrierColor: context.dc.scrim.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle)
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: Space.md, bottom: Space.lg),
                decoration: BoxDecoration(
                  color: dc.line,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title!, style: context.text.headlineMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: Space.xs + 2),
                    Text(subtitle!, style: context.text.bodyMedium),
                  ],
                ],
              ),
            ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom + Space.sm,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration-free empty state with a tinted icon medallion.
class DcEmptyState extends StatelessWidget {
  const DcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Space.xxxl,
        vertical: compact ? Space.xxl : Space.giant,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 56 : 72,
            height: compact ? 56 : 72,
            decoration: BoxDecoration(
              color: dc.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: compact ? 24 : 30, color: dc.accent),
          ),
          SizedBox(height: compact ? Space.lg : Space.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.xl),
            DcButton(
              actionLabel!,
              onPressed: onAction,
              size: DcButtonSize.medium,
              expand: false,
              variant: DcButtonVariant.outline,
            ),
          ],
        ],
      ),
    );
  }
}

/// A single figure with a caption — used across profile and earnings screens.
class DcStat extends StatelessWidget {
  const DcStat({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone,
    this.align = CrossAxisAlignment.start,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? tone;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: tone ?? dc.inkFaint),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.serif(
                  23,
                  weight: 580,
                  height: 1.1,
                  tracking: -0.5,
                  color: tone ?? dc.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs + 1),
        Text(
          label,
          style: AppType.sans(
            11.5,
            weight: 560,
            tracking: 0.35,
            color: dc.inkFaint,
          ),
        ),
      ],
    );
  }
}

/// Label on the left, value on the right, with an optional divider above.
class DcKeyValue extends StatelessWidget {
  const DcKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.divider = false,
    this.valueColor,
    this.emphasis = false,
    this.icon,
  });

  final String label;
  final String value;
  final bool divider;
  final Color? valueColor;
  final bool emphasis;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      children: [
        if (divider) Divider(color: dc.line, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: dc.inkFaint),
                const SizedBox(width: Space.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: emphasis
                      ? context.text.titleMedium
                      : context.text.bodyMedium,
                ),
              ),
              const SizedBox(width: Space.md),
              // Long values (addresses, opening hours) wrap under the label
              // instead of running past the card edge.
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: emphasis
                      ? AppType.serif(
                          19,
                          weight: 600,
                          height: 1.2,
                          tracking: -0.3,
                          color: valueColor ?? dc.ink,
                        )
                      : AppType.sans(
                          14,
                          weight: 600,
                          height: 1.3,
                          color: valueColor ?? dc.ink,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated shimmer placeholder for loading states.
class DcShimmer extends StatefulWidget {
  const DcShimmer({
    super.key,
    this.width,
    this.height = 14,
    this.radius = Radii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<DcShimmer> createState() => _DcShimmerState();
}

class _DcShimmerState extends State<DcShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: [
                dc.skeleton,
                Color.lerp(dc.skeleton, dc.surface, 0.65)!,
                dc.skeleton,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
