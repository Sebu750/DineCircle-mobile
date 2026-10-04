import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/restaurant.dart';
import '../theme/theme.dart';
import 'dc_buttons.dart';
import 'dc_image.dart';
import 'dc_pills.dart';
import 'dc_surfaces.dart';

/// Partner venue card used in the Discover rail.
class VenueCardTall extends StatelessWidget {
  const VenueCardTall({
    super.key,
    required this.venue,
    required this.onTap,
    this.width = 248,
  });

  final Restaurant venue;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return SizedBox(
      width: width,
      child: PressableScale(
        onTap: onTap,
        child: DcSurface(
          radius: Radii.xl,
          shadows: dc.shadowSm,
          clip: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: DcImage(venue.heroAsset, scrim: dc.cardScrim),
                  ),
                  if (venue.isPartner)
                    Positioned(
                      left: Space.md,
                      top: Space.md,
                      child: DcTag(
                        'Partner',
                        icon: Icons.storefront_rounded,
                        tone: PillTone.glass,
                        size: DcTagSize.small,
                      ),
                    ),
                  Positioned(
                    left: Space.md,
                    bottom: Space.md,
                    child: RatingPill(
                      rating: venue.rating,
                      count: venue.reviewCount,
                      onImage: true,
                      compact: true,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  Space.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      venue.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.serif(
                        17.5,
                        weight: 560,
                        height: 1.18,
                        tracking: -0.35,
                        color: dc.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${venue.cuisine} · ${venue.priceLevelLabel} · ${Fmt.distance(venue.distanceMeters)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                    if (venue.partnerPerk != null) ...[
                      const SizedBox(height: Space.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: Space.sm,
                        ),
                        decoration: BoxDecoration(
                          color: dc.accentSoft,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.redeem_rounded,
                              size: 14,
                              color: dc.isDark ? dc.accent : AppColors.clay700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                venue.partnerPerk!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.sans(
                                  11,
                                  weight: 600,
                                  height: 1.3,
                                  color: dc.isDark
                                      ? dc.accent
                                      : AppColors.clay700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide venue row for the venues list and restaurant search results.
class VenueRow extends StatelessWidget {
  const VenueRow({
    super.key,
    required this.venue,
    required this.onTap,
    this.trailingText,
  });

  final Restaurant venue;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return PressableScale(
      onTap: onTap,
      child: DcSurface(
        radius: Radii.lg,
        shadows: dc.shadowSm,
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: DcImage(venue.heroAsset, radius: Radii.md),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                      ),
                      if (venue.isPartner) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.storefront_rounded,
                          size: 14,
                          color: dc.pine,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${venue.cuisine} · ${venue.neighborhood}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: Space.sm),
                  // Wrap so long opening hours or wide fonts push pills onto
                  // a second line rather than out of the card.
                  Wrap(
                    spacing: Space.md,
                    runSpacing: Space.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RatingPill(rating: venue.rating, compact: true),
                      MetaPill(
                        venue.priceLevelLabel,
                        icon: Icons.payments_rounded,
                      ),
                      MetaPill(
                        Fmt.distance(venue.distanceMeters),
                        icon: Icons.near_me_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(left: Space.sm),
                child: Text(
                  trailingText!,
                  style: AppType.sans(12, weight: 620, color: dc.accent),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, size: 20, color: dc.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Slim strip listing the benefits a partner venue offers DineCircle guests.
class VenuePerkStrip extends StatelessWidget {
  const VenuePerkStrip({super.key, required this.venue});

  final Restaurant venue;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final items = [
      (
        Icons.storefront_rounded,
        'Partner venue',
        'Tables hosted here earn priority placement',
      ),
      if (venue.partnerPerk != null)
        (Icons.redeem_rounded, 'Guest benefit', venue.partnerPerk!),
      (Icons.schedule_rounded, 'Opening hours', venue.openingHours),
      (
        Icons.event_seat_rounded,
        'Seats this month',
        '${venue.seatsAvailable} seats available to hosts',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: dc.surfaceAlt,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Icon(items[i].$1, size: 17, color: dc.inkMuted),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        items[i].$2.toUpperCase(),
                        style: AppType.overline(size: 10, color: dc.inkFaint),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        style: AppType.sans(
                          13.5,
                          weight: 540,
                          height: 1.4,
                          color: dc.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
