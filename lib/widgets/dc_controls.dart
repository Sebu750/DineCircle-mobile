import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'dc_pills.dart';

/// Standard text input with the DineCircle label treatment.
class DcTextField extends StatelessWidget {
  const DcTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.obscure = false,
    this.textInputAction,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppType.overline(color: dc.inkFaint),
          ),
          const SizedBox(height: Space.sm),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: obscure ? 1 : maxLines,
          obscureText: obscure,
          onChanged: onChanged,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: textInputAction,
          validator: validator,
          style: AppType.sans(15, weight: 500, height: 1.35, color: dc.ink),
          cursorColor: dc.accent,
          cursorWidth: 1.8,
          cursorRadius: const Radius.circular(2),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 19, color: dc.inkFaint),
            suffixIcon: suffix,
            helperText: helper,
            helperStyle: AppType.sans(12, color: dc.inkFaint),
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped search input used at the top of Discover and Search.
class DcSearchField extends StatelessWidget {
  const DcSearchField({
    super.key,
    this.controller,
    this.hint = 'Restaurants, hosts, cuisines…',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.trailing,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Material(
      color: dc.surface,
      borderRadius: BorderRadius.circular(Radii.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: dc.line, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 19, color: dc.inkFaint),
              const SizedBox(width: Space.md),
              Expanded(
                child: readOnly
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hint,
                          style: AppType.sans(14.5, color: dc.inkFaint),
                        ),
                      )
                    : TextField(
                        controller: controller,
                        autofocus: autofocus,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        style: AppType.sans(14.5, weight: 500, color: dc.ink),
                        cursorColor: dc.accent,
                        cursorWidth: 1.6,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: hint,
                          hintStyle: AppType.sans(14.5, color: dc.inkFaint),
                        ),
                      ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Numeric stepper used for seat counts and table size.
class DcStepper extends StatelessWidget {
  const DcStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.suffix,
    this.label = 'Seats',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final canDecrease = value > min;
    final canIncrease = value < max;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppType.overline(color: dc.inkFaint),
              ),
              const SizedBox(height: 3),
              Text(
                suffix ?? '$value ${value == 1 ? 'seat' : 'seats'}',
                style: context.text.titleMedium,
              ),
            ],
          ),
        ),
        _StepButton(
          icon: Icons.remove_rounded,
          enabled: canDecrease,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged((value - 1).clamp(min, max));
          },
        ),
        SizedBox(
          width: 46,
          child: Center(
            child: Text(
              '$value',
              style: AppType.serif(
                22,
                weight: 620,
                height: 1,
                tracking: -0.4,
                color: dc.ink,
              ),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          enabled: canIncrease,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged((value + 1).clamp(min, max));
          },
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Material(
      color: enabled ? dc.surfaceAlt : dc.surfaceAlt.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 19,
            color: enabled ? dc.ink : dc.inkFaint.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// One option inside a [DcSegmented] control.
class DcSegment<T> {
  const DcSegment(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Pill segmented control with a sliding indicator.
class DcSegmented<T> extends StatelessWidget {
  const DcSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 46,
  });

  final List<DcSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final index = segments.indexWhere((s) => s.value == value);

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dc.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - 8;
          final itemWidth = available / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.enter,
                left: index <= 0 ? 0 : itemWidth * index,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dc.surface,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    boxShadow: dc.shadowSm,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (segment.value == value) return;
                          HapticFeedback.selectionClick();
                          onChanged(segment.value);
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (segment.icon != null) ...[
                                Icon(
                                  segment.icon,
                                  size: 15,
                                  color: segment.value == value
                                      ? dc.ink
                                      : dc.inkFaint,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                segment.label,
                                style: AppType.sans(
                                  13.5,
                                  weight: segment.value == value ? 680 : 550,
                                  height: 1.1,
                                  color: segment.value == value
                                      ? dc.ink
                                      : dc.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontally scrolling selectable chips.
class DcChipRow extends StatelessWidget {
  const DcChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding,
    this.showAllOption = true,
    this.allLabel = 'All',
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final EdgeInsetsGeometry? padding;

  /// Adds a leading `All` chip that clears the selection.
  final bool showAllOption;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return DcRailLike(
      padding: padding,
      children: [
        if (showAllOption)
          DcTag(
            allLabel,
            selected: selected == null,
            size: DcTagSize.medium,
            onTap: () => onSelected(null),
          ),
        for (final option in options)
          DcTag(
            option,
            selected: selected == option,
            size: DcTagSize.medium,
            onTap: () => onSelected(option),
          ),
      ],
    );
  }
}

/// Minimal horizontal scroller reused by chip rows and quick filters.
class DcRailLike extends StatelessWidget {
  const DcRailLike({
    super.key,
    required this.children,
    this.padding,
    this.gap = Space.sm,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: Space.gutter),
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: (context, index) => Center(child: children[index]),
      ),
    );
  }
}

/// Tappable row that opens a picker or sub-screen.
class DcSelectRow extends StatelessWidget {
  const DcSelectRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
    this.surface = true,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool surface;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dc.accentSoft,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(
              icon,
              size: 19,
              color: dc.isDark ? dc.accent : AppColors.clay700,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.text.titleSmall),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded, size: 20, color: dc.inkFaint),
        ],
      ),
    );

    if (!surface) {
      return InkWell(onTap: onTap, child: content);
    }

    return Material(
      color: dc.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: dc.line, width: 1),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Labelled switch row.
class DcSwitchRow extends StatelessWidget {
  const DcSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Space.md,
          horizontal: Space.lg,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: dc.inkMuted),
              const SizedBox(width: Space.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
