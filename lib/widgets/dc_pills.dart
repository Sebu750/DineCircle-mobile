import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/user.dart';
import '../theme/theme.dart';

/// Colour treatments available to pills and tags.
enum PillTone { neutral, accent, gold, pine, danger, glass, solid }

/// Small, rounded label used for tags, statuses and metadata.
///
/// One component covers every pill in the app so spacing and radii stay
/// consistent no matter where it appears.
class DcTag extends StatelessWidget {
  const DcTag(
    this.label, {
    super.key,
    this.icon,
    this.tone = PillTone.neutral,
    this.size = DcTagSize.medium,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final PillTone tone;
  final DcTagSize size;
  final VoidCallback? onTap;

  /// Selected tags invert to the ink colour.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final (bg, fg) = _resolveTone(dc, tone);

    final accentColor = selected ? dc.ink : bg;
    final textColor = selected ? dc.canvas : fg;

    final padding = switch (size) {
      DcTagSize.small => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      DcTagSize.medium => const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      DcTagSize.large => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 11,
      ),
    };

    final fontSize = switch (size) {
      DcTagSize.small => 11.0,
      DcTagSize.medium => 12.5,
      DcTagSize.large => 14.0,
    };

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
          color: tone == PillTone.glass || tone == PillTone.neutral
              ? (selected ? Colors.transparent : dc.line)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppType.sans(
              fontSize,
              weight: 620,
              height: 1.1,
              tracking: 0.1,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  static (Color, Color) _resolveTone(DcTheme dc, PillTone tone) {
    return switch (tone) {
      PillTone.neutral => (dc.surfaceAlt, dc.inkMuted),
      PillTone.accent => (
        dc.accentSoft,
        dc.isDark ? dc.accent : AppColors.clay700,
      ),
      PillTone.gold => (dc.goldSoft, dc.isDark ? dc.gold : AppColors.gold600),
      PillTone.pine => (dc.pineSoft, dc.isDark ? dc.pine : AppColors.pine600),
      PillTone.danger => (dc.dangerSoft, dc.danger),
      PillTone.glass => (Colors.black.withValues(alpha: 0.42), Colors.white),
      PillTone.solid => (dc.surface, dc.ink),
    };
  }
}

enum DcTagSize { small, medium, large }

/// Star rating with an optional review count.
class RatingPill extends StatelessWidget {
  const RatingPill({
    super.key,
    required this.rating,
    this.count,
    this.onImage = false,
    this.compact = false,
  });

  final double rating;
  final int? count;

  /// Switches to the light-on-photo treatment used inside image cards.
  final bool onImage;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final fg = onImage ? Colors.white : dc.ink;
    final star = onImage ? AppColors.gold400 : dc.gold;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: compact ? 13 : 15, color: star),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppType.sans(
            compact ? 12 : 13,
            weight: 700,
            height: 1.1,
            tracking: -0.1,
            color: fg,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '(${count!})',
            style: AppType.sans(
              compact ? 11 : 12,
              weight: 450,
              height: 1.1,
              color: onImage ? Colors.white70 : dc.inkFaint,
            ),
          ),
        ],
      ],
    );
  }
}

/// Price of a single seat, with an optional `per seat` suffix.
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.amount,
    this.formatted,
    this.suffix = 'per seat',
    this.onImage = false,
    this.size = 17,
  });

  final double? amount;
  final String? formatted;
  final String? suffix;
  final bool onImage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final label = formatted ?? _money(amount ?? 0);
    final fg = onImage ? Colors.white : dc.ink;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppType.serif(
            size,
            weight: 600,
            height: 1.05,
            tracking: -0.4,
            color: fg,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 5),
          Text(
            suffix!,
            style: AppType.sans(
              size * 0.68,
              weight: 480,
              height: 1.1,
              color: onImage ? Colors.white70 : dc.inkFaint,
            ),
          ),
        ],
      ],
    );
  }

  static String _money(double value) {
    final hasCents = value % 1 != 0;
    return '€${value.toStringAsFixed(hasCents ? 2 : 0)}';
  }
}

/// Progress bar showing how full a table is.
class SeatMeter extends StatelessWidget {
  const SeatMeter({
    super.key,
    required this.filled,
    required this.total,
    this.height = 6,
    this.onImage = false,
    this.showCounts = false,
  });

  final int filled;
  final int total;
  final double height;
  final bool onImage;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final ratio = total == 0 ? 0.0 : (filled / total).clamp(0.0, 1.0);
    final nearlyFull = ratio >= 0.8;

    final track = onImage
        ? Colors.white.withValues(alpha: 0.28)
        : dc.surfaceSunken;
    final fill = nearlyFull
        ? (onImage ? AppColors.clay400 : dc.accent)
        : (onImage ? Colors.white : dc.ink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: Stack(
            children: [
              Container(height: height, color: track),
              FractionallySizedBox(
                widthFactor: ratio == 0 ? 0.0001 : ratio,
                child: AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.enter,
                  height: height,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showCounts) ...[
          const SizedBox(height: Space.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$filled seated',
                style: context.text.bodySmall?.copyWith(
                  color: onImage ? Colors.white70 : dc.inkFaint,
                ),
              ),
              Text(
                '$total seats',
                style: context.text.bodySmall?.copyWith(
                  color: onImage ? Colors.white70 : dc.inkFaint,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Human-readable state of a booking or payout.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.tone});

  factory StatusPill.booking(BookingStatus status) => StatusPill(
    status.label,
    tone: switch (status) {
      BookingStatus.confirmed => PillTone.pine,
      BookingStatus.pending => PillTone.gold,
      BookingStatus.completed => PillTone.neutral,
      BookingStatus.cancelled => PillTone.danger,
    },
  );

  factory StatusPill.payout(PayoutStatus status) => StatusPill(
    status.label,
    tone: switch (status) {
      PayoutStatus.paid => PillTone.pine,
      PayoutStatus.inTransit => PillTone.gold,
      PayoutStatus.scheduled => PillTone.neutral,
    },
  );

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final (bg, fg) = DcTag._resolveTone(dc, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: AppType.sans(
          11.5,
          weight: 660,
          height: 1.1,
          tracking: 0.1,
          color: fg,
        ),
      ),
    );
  }
}

/// Trust marker attached to a person (verified, food creator, venue partner…).
class RoleBadge extends StatelessWidget {
  const RoleBadge(this.badge, {super.key, this.compact = false});

  final UserBadge badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, tone) = switch (badge) {
      UserBadge.verified => (
        'Verified',
        Icons.verified_rounded,
        PillTone.accent,
      ),
      UserBadge.influencer => (
        'Food creator',
        Icons.auto_awesome_rounded,
        PillTone.gold,
      ),
      UserBadge.restaurant => (
        'Venue partner',
        Icons.storefront_rounded,
        PillTone.pine,
      ),
      UserBadge.host => ('Host', Icons.local_dining_rounded, PillTone.neutral),
      UserBadge.risingHost => (
        'Rising host',
        Icons.trending_up_rounded,
        PillTone.pine,
      ),
    };
    return DcTag(
      label,
      icon: icon,
      tone: tone,
      size: compact ? DcTagSize.small : DcTagSize.medium,
    );
  }
}

/// Metadata chip: distance, duration, audience and similar single facts.
class MetaPill extends StatelessWidget {
  const MetaPill(
    this.label, {
    super.key,
    required this.icon,
    this.onImage = false,
  });

  final String label;
  final IconData icon;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final fg = onImage ? Colors.white.withValues(alpha: 0.92) : dc.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppType.sans(12.5, weight: 520, height: 1.1, color: fg),
        ),
      ],
    );
  }
}
