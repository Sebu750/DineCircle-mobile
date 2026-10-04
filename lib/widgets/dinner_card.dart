import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/app_scope.dart';
import '../models/dinner_event.dart';
import '../theme/theme.dart';
import 'dc_avatar.dart';
import 'dc_buttons.dart';
import 'dc_image.dart';
import 'dc_pills.dart';
import 'dc_surfaces.dart';

/// Compact calendar marker used on every table card.
class DateBadge extends StatelessWidget {
  const DateBadge({
    super.key,
    required this.date,
    this.onImage = false,
    this.compact = false,
  });

  final DateTime date;
  final bool onImage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final width = compact ? 40.0 : 46.0;
    final height = compact ? 44.0 : 50.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: onImage ? Colors.black.withValues(alpha: 0.38) : dc.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: onImage
            ? Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Fmt.monthTag(date),
            style: AppType.overline(
              size: compact ? 8.5 : 9.5,
              tracking: 0.9,
              color: onImage ? Colors.white70 : dc.accent,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            Fmt.dayNumber(date),
            style: AppType.serif(
              compact ? 16 : 18,
              weight: 620,
              height: 1,
              tracking: -0.3,
              color: onImage ? Colors.white : dc.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A save toggle that animates between outline and filled states.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.saved,
    required this.onTap,
    this.onImage = true,
    this.size = 36,
  });

  final bool saved;
  final VoidCallback onTap;
  final bool onImage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return DcIconButton(
      saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      onPressed: onTap,
      variant: onImage
          ? DcIconButtonVariant.glass
          : DcIconButtonVariant.surface,
      size: size,
      iconSize: size * 0.47,
      color: saved ? (onImage ? AppColors.gold400 : dc.gold) : null,
    );
  }
}

/// Shared pieces of every table card — the urgency line above the seat meter.
class _DemandLine extends StatelessWidget {
  const _DemandLine({required this.event, this.onImage = false});

  final DinnerEvent event;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final urgent = event.seatsLeft <= 3;
    final tone = urgent
        ? (onImage ? AppColors.gold400 : dc.gold)
        : (onImage ? Colors.white : dc.inkMuted);
    return Row(
      children: [
        Icon(
          urgent
              ? Icons.local_fire_department_rounded
              : Icons.event_seat_rounded,
          size: 13,
          color: tone,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            event.seatsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.sans(
              12,
              weight: urgent ? 680 : 540,
              height: 1.1,
              color: tone,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tall editorial card used inside the Discover rails.
class DinnerCardTall extends StatelessWidget {
  const DinnerCardTall({
    super.key,
    required this.event,
    required this.onTap,
    this.width = 268,
    this.height = 348,
    this.saved = false,
    this.onToggleSave,
  });

  final DinnerEvent event;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool saved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final venue = app.restaurantFor(event);
    final host = app.hostOf(event);

    return SizedBox(
      width: width,
      height: height,
      child: PressableScale(
        onTap: onTap,
        child: DcSurface(
          radius: Radii.xl,
          showBorder: false,
          shadows: dc.shadowMd,
          clip: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DcImage(
                event.imageAsset,
                scrim: dc.heroScrim,
                alignment: Alignment.center,
              ),
              Positioned(
                left: Space.md,
                top: Space.md,
                right: Space.md,
                child: Row(
                  children: [
                    DcTag(
                      event.type.label,
                      icon: event.type.icon,
                      tone: PillTone.glass,
                      size: DcTagSize.small,
                    ),
                    const Spacer(),
                    if (onToggleSave != null)
                      SaveButton(saved: saved, onTap: onToggleSave!, size: 34),
                  ],
                ),
              ),
              Positioned(
                left: Space.lg,
                right: Space.lg,
                bottom: Space.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${Fmt.until(event.start).toUpperCase()} · ${Fmt.clockCompact(event.start).toUpperCase()}',
                          style: AppType.overline(
                            size: 10,
                            color: AppColors.gold400,
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          '· ${Fmt.money(event.pricePerSeat)}',
                          style: AppType.overline(
                            size: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.serif(
                        20,
                        weight: 560,
                        height: 1.16,
                        tracking: -0.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        DcAvatar.of(
                          host,
                          radius: 11,
                          borderColor: Colors.transparent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            host.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.sans(
                              12,
                              weight: 600,
                              height: 1.1,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        Text(
                          venue.neighborhood,
                          style: AppType.sans(
                            11.5,
                            weight: 520,
                            height: 1.1,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    SeatMeter(
                      filled: event.seatsTaken,
                      total: event.seatsTotal,
                      onImage: true,
                      height: 5,
                    ),
                    const SizedBox(height: Space.sm),
                    _DemandLine(event: event, onImage: true),
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

/// Full-bleed card for the single hero table at the top of Discover.
class DinnerCardHero extends StatelessWidget {
  const DinnerCardHero({
    super.key,
    required this.event,
    required this.onTap,
    this.saved = false,
    this.onToggleSave,
    this.height = 372,
  });

  final DinnerEvent event;
  final VoidCallback onTap;
  final bool saved;
  final VoidCallback? onToggleSave;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final venue = app.restaurantFor(event);
    final host = app.hostOf(event);

    return SizedBox(
      height: height,
      child: PressableScale(
        onTap: onTap,
        child: DcSurface(
          radius: Radii.xxl,
          showBorder: false,
          shadows: dc.shadowLg,
          clip: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DcImage(event.imageAsset, scrim: dc.heroScrim),
              Positioned(
                left: Space.lg,
                top: Space.lg,
                right: Space.lg,
                child: Row(
                  children: [
                    DcTag(
                      'Featured',
                      icon: Icons.auto_awesome_rounded,
                      tone: PillTone.glass,
                      size: DcTagSize.small,
                    ),
                    const Spacer(),
                    if (onToggleSave != null)
                      SaveButton(saved: saved, onTap: onToggleSave!, size: 38),
                  ],
                ),
              ),
              Positioned(
                left: Space.xl,
                right: Space.xl,
                bottom: Space.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        DateBadge(date: event.start, onImage: true),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Fmt.until(event.start),
                                style: AppType.sans(
                                  13,
                                  weight: 680,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${event.timeRangeLabel} · ${Fmt.duration(event.durationMinutes)}',
                                style: AppType.sans(
                                  12,
                                  weight: 520,
                                  height: 1.1,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PriceTag(
                          amount: event.pricePerSeat,
                          onImage: true,
                          size: 19,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.serif(
                        27,
                        weight: 560,
                        height: 1.12,
                        tracking: -0.6,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      event.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.sans(
                        13,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    Row(
                      children: [
                        DcAvatar.of(
                          host,
                          radius: 14,
                          borderColor: Colors.transparent,
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(
                            '${host.name} · ${venue.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.sans(
                              12.5,
                              weight: 600,
                              height: 1.1,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        MetaPill(
                          Fmt.distance(venue.distanceMeters),
                          icon: Icons.near_me_rounded,
                          onImage: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    SeatMeter(
                      filled: event.seatsTaken,
                      total: event.seatsTotal,
                      onImage: true,
                    ),
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

/// Dense horizontal card used in feeds, search results and profile lists.
class DinnerCardList extends StatelessWidget {
  const DinnerCardList({
    super.key,
    required this.event,
    required this.onTap,
    this.showHost = true,
    this.saved = false,
    this.onToggleSave,
    this.trailing,
  });

  final DinnerEvent event;
  final VoidCallback onTap;
  final bool showHost;
  final bool saved;
  final VoidCallback? onToggleSave;

  /// Replaces the default price block, e.g. with a booking status.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final venue = app.restaurantFor(event);
    final host = app.hostOf(event);

    return PressableScale(
      onTap: onTap,
      child: DcSurface(
        radius: Radii.lg,
        shadows: dc.shadowSm,
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              height: 108,
              child: DcImage(
                event.imageAsset,
                radius: Radii.md,
                scrim: dc.cardScrim,
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      DateBadge(date: event.start, compact: true),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${venue.name} · ${Fmt.distance(venue.distanceMeters)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm + 2),
                  Row(
                    children: [
                      MetaPill(
                        Fmt.clockCompact(event.start),
                        icon: Icons.schedule_rounded,
                      ),
                      const SizedBox(width: Space.md),
                      MetaPill(
                        '${event.seatsLeft} open',
                        icon: Icons.chair_alt_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm + 2),
                  Row(
                    children: [
                      if (showHost) ...[
                        DcAvatar.of(
                          host,
                          radius: 10,
                          borderColor: Colors.transparent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            host.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (trailing != null)
                        trailing!
                      else ...[
                        PriceTag(
                          amount: event.pricePerSeat,
                          suffix: null,
                          size: 16,
                        ),
                        if (onToggleSave != null) ...[
                          const SizedBox(width: Space.sm),
                          SaveButton(
                            saved: saved,
                            onTap: onToggleSave!,
                            onImage: false,
                            size: 32,
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal row used inside "My tables" and host consoles.
class DinnerTicketRow extends StatelessWidget {
  const DinnerTicketRow({
    super.key,
    required this.event,
    required this.onTap,
    this.status,
    this.subtitle,
  });

  final DinnerEvent event;
  final VoidCallback onTap;
  final Widget? status;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final venue = app.restaurantFor(event);

    return DcSurface(
      radius: Radii.lg,
      shadows: dc.shadowSm,
      onTap: onTap,
      clip: true,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 96,
            child: DcImage(event.imageAsset, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                      ),
                      ?status,
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle ?? venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: dc.inkFaint,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${Fmt.dayMonth(event.start)} · ${Fmt.clockCompact(event.start)}',
                        style: AppType.sans(
                          12,
                          weight: 560,
                          height: 1.1,
                          color: dc.inkMuted,
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Icon(
                        Icons.event_seat_rounded,
                        size: 12,
                        color: dc.inkFaint,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${event.seatsTaken}/${event.seatsTotal}',
                        style: AppType.sans(
                          12,
                          weight: 560,
                          height: 1.1,
                          color: dc.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
