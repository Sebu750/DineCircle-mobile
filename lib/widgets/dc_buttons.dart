import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Visual weight of a [DcButton].
enum DcButtonVariant {
  /// Solid clay — the single most important action on a screen.
  primary,

  /// Tinted clay — secondary emphasis without competing with the CTA.
  tonal,

  /// Bordered on surface — neutral, abundant actions.
  outline,

  /// Text only, for tertiary navigation.
  ghost,

  /// Reserved for irreversible or destructive actions.
  danger,
}

enum DcButtonSize { small, medium, large }

/// The app's single button component.
///
/// Wraps the Material button so focus, hover and semantics come for free, while
/// enforcing DineCircle's heights, radii and label styling.
class DcButton extends StatelessWidget {
  const DcButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = DcButtonVariant.primary,
    this.size = DcButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DcButtonVariant variant;
  final DcButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Fills the available width.
  final bool expand;

  final bool isLoading;
  final bool enabled;

  double get _height => switch (size) {
    DcButtonSize.small => 42,
    DcButtonSize.medium => 50,
    DcButtonSize.large => 56,
  };

  double get _fontSize => switch (size) {
    DcButtonSize.small => 13.5,
    DcButtonSize.medium => 14.5,
    DcButtonSize.large => 15.5,
  };

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final active = enabled && !isLoading;
    final handler = active ? onPressed : null;

    final (bg, fg, border) = switch (variant) {
      DcButtonVariant.primary => (dc.accent, dc.onAccent, null),
      DcButtonVariant.tonal => (
        dc.accentSoft,
        dc.isDark ? dc.accent : AppColors.clay700,
        null,
      ),
      DcButtonVariant.outline => (
        dc.surface,
        dc.ink,
        BorderSide(color: dc.line, width: 1.2),
      ),
      DcButtonVariant.ghost => (Colors.transparent, dc.ink, null),
      DcButtonVariant.danger => (dc.dangerSoft, dc.danger, null),
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.pill),
      side: border ?? BorderSide.none,
    );

    final child = isLoading
        ? SizedBox(
            height: _fontSize + 4,
            width: _fontSize + 4,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _fontSize + 5, color: fg),
                const SizedBox(width: Space.sm + 2),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.sans(
                    _fontSize,
                    weight: 680,
                    height: 1.15,
                    tracking: 0.05,
                    color: fg,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: Space.sm),
                Icon(trailingIcon, size: _fontSize + 3, color: fg),
              ],
            ],
          );

    return Opacity(
      opacity: active ? 1 : 0.5,
      child: SizedBox(
        height: _height,
        width: expand ? double.infinity : null,
        child: Material(
          color: bg,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          animationDuration: Motion.fast,
          child: InkWell(
            onTap: handler,
            splashColor: fg.withValues(alpha: 0.10),
            highlightColor: fg.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size == DcButtonSize.small ? Space.lg : Space.xxl,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Treatment for circular icon buttons floating over photography.
enum DcIconButtonVariant { glass, surface, plain, solid }

class DcIconButton extends StatelessWidget {
  const DcIconButton(
    this.icon, {
    super.key,
    this.onPressed,
    this.variant = DcIconButtonVariant.glass,
    this.size = 42,
    this.iconSize = 20,
    this.tooltip,
    this.color,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final DcIconButtonVariant variant;
  final double size;
  final double iconSize;
  final String? tooltip;
  final Color? color;

  /// Optional notification dot.
  final bool? badge;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final (bg, fg) = switch (variant) {
      DcIconButtonVariant.glass => (
        Colors.black.withValues(alpha: 0.38),
        Colors.white,
      ),
      DcIconButtonVariant.surface => (dc.surface, dc.ink),
      DcIconButtonVariant.plain => (Colors.transparent, dc.ink),
      DcIconButtonVariant.solid => (dc.accent, dc.onAccent),
    };

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: variant == DcIconButtonVariant.glass
            ? Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1)
            : (variant == DcIconButtonVariant.surface
                  ? Border.all(color: dc.line, width: 1)
                  : null),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: fg.withValues(alpha: 0.12),
          child: Center(
            child: Icon(icon, size: iconSize, color: color ?? fg),
          ),
        ),
      ),
    );

    if (badge == true) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: dc.accent,
                shape: BoxShape.circle,
                border: Border.all(color: dc.canvas, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Scales a child down slightly while pressed — the tactile cue used on cards.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: widget.onTap == null ? null : () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed && widget.onTap != null ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.enter,
        child: widget.child,
      ),
    );
  }
}
