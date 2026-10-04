import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../data/app_scope.dart';
import '../models/booking.dart';
import '../models/dinner_event.dart';
import '../models/restaurant.dart';
import '../models/social.dart';
import '../models/user.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'join_sheet.dart';

/// Everything a guest needs before they reserve: the story, the menu, the host,
/// the venue and the guest list.
class DinnerDetailScreen extends StatelessWidget {
  const DinnerDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final event = app.event(eventId);
    final venue = app.restaurantFor(event);
    final host = app.hostOf(event);
    final booking = app.bookingFor(eventId);
    final guests = event.attendeeIds.map(app.user).toList();
    final reviews = app.reviewsForEvent(eventId);

    return Scaffold(
      backgroundColor: dc.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _Hero(event: event, venue: venue),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.xl,
                Space.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleBlock(event: event),
                  const SizedBox(height: Space.xl),
                  _FactCard(event: event, venue: venue),
                  const SizedBox(height: Space.xxl),
                  _AboutBlock(event: event),
                  const SizedBox(height: Space.xxl),
                  _MenuBlock(event: event),
                  const SizedBox(height: Space.xxl),
                  _HostBlock(event: event, host: host),
                  const SizedBox(height: Space.xxl),
                  _GuestsBlock(event: event, guests: guests, booking: booking),
                  const SizedBox(height: Space.xxl),
                  _VenueBlock(venue: venue),
                  if (reviews.isNotEmpty) ...[
                    const SizedBox(height: Space.xxl),
                    _ReviewsBlock(reviews: reviews),
                  ],
                  const SizedBox(height: Space.xxl),
                  _FinePrint(event: event),
                  const SizedBox(height: 132),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ReserveBar(event: event, booking: booking),
    );
  }
}

// ── Hero ───────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({required this.event, required this.venue});

  final DinnerEvent event;
  final Restaurant venue;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 372,
      backgroundColor: dc.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leadingWidth: 64,
      leading: Center(
        child: DcIconButton(
          Icons.arrow_back_rounded,
          variant: DcIconButtonVariant.glass,
          size: 40,
          iconSize: 20,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      actions: [
        _SaveAction(eventId: event.id),
        const SizedBox(width: Space.sm),
        DcIconButton(
          Icons.ios_share_rounded,
          variant: DcIconButtonVariant.glass,
          size: 40,
          iconSize: 18,
          onPressed: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invite link for "${event.title}" copied'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: Space.md),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            DcImage(event.imageAsset, scrim: dc.heroScrim),
            Positioned(
              left: Space.gutter,
              right: Space.gutter,
              bottom: Space.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      DcTag(
                        event.type.label,
                        icon: event.type.icon,
                        tone: PillTone.glass,
                        size: DcTagSize.small,
                      ),
                      const SizedBox(width: Space.sm),
                      DcTag(
                        event.menuStyle.label,
                        icon: Icons.restaurant_menu_rounded,
                        tone: PillTone.glass,
                        size: DcTagSize.small,
                      ),
                      const Spacer(),
                      RatingPill(
                        rating: venue.rating,
                        count: venue.reviewCount,
                        onImage: true,
                        compact: true,
                      ),
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

class _SaveAction extends StatelessWidget {
  const _SaveAction({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return SaveButton(
      saved: app.isSaved(eventId),
      size: 40,
      onTap: () {
        HapticFeedback.selectionClick();
        app.toggleSaved(eventId);
      },
    );
  }
}

// ── Title ──────────────────────────────────────────────────────────────────
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.event});

  final DinnerEvent event;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${Fmt.until(event.start).toUpperCase()} · ${Fmt.clockCompact(event.start).toUpperCase()}',
              style: AppType.overline(color: dc.accent),
            ),
            if (event.isFeatured) ...[
              const SizedBox(width: Space.sm),
              const DcTag(
                'Featured',
                icon: Icons.auto_awesome_rounded,
                tone: PillTone.gold,
                size: DcTagSize.small,
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.sm),
        Text(
          event.title,
          style: AppType.serif(
            28,
            weight: 560,
            height: 1.14,
            tracking: -0.9,
            color: dc.ink,
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          event.tagline,
          style: AppType.sans(
            14.5,
            weight: 440,
            height: 1.55,
            color: dc.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ── Facts ──────────────────────────────────────────────────────────────────
class _FactCard extends StatelessWidget {
  const _FactCard({required this.event, required this.venue});

  final DinnerEvent event;
  final Restaurant venue;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return DcSurface(
      radius: Radii.xl,
      shadows: dc.shadowSm,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          _FactRow(
            icon: Icons.event_rounded,
            title: Fmt.fullDate(event.start),
            value:
                '${event.timeRangeLabel} · ${Fmt.duration(event.durationMinutes)}',
          ),
          const SizedBox(height: Space.lg),
          _FactRow(
            icon: Icons.place_rounded,
            title: venue.name,
            value:
                '${venue.neighborhood} · ${Fmt.distance(venue.distanceMeters)} away',
          ),
          const SizedBox(height: Space.lg),
          _FactRow(
            icon: Icons.people_alt_rounded,
            title: '${event.seatsTotal} seats · ${event.audience.label}',
            value: event.audience.hint,
          ),
          const SizedBox(height: Space.lg),
          Divider(color: dc.line, height: 1),
          const SizedBox(height: Space.lg),
          SeatMeter(
            filled: event.seatsTaken,
            total: event.seatsTotal,
            showCounts: true,
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: dc.accentSoft,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Icon(
            icon,
            size: 18,
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
              const SizedBox(height: 2),
              Text(value, style: context.text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ── About ──────────────────────────────────────────────────────────────────
class _AboutBlock extends StatelessWidget {
  const _AboutBlock({required this.event});

  final DinnerEvent event;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcSectionHeader(
          eyebrow: 'The evening',
          title: 'What happens at this table',
        ),
        Text(
          event.description,
          style: AppType.sans(
            14.5,
            weight: 430,
            height: 1.62,
            color: dc.inkMuted,
          ),
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final item in event.included)
              DcTag(
                item,
                icon: Icons.check_rounded,
                tone: PillTone.pine,
                size: DcTagSize.small,
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final tag in event.tags) DcTag('#$tag', size: DcTagSize.small),
          ],
        ),
      ],
    );
  }
}

// ── Menu ───────────────────────────────────────────────────────────────────
class _MenuBlock extends StatelessWidget {
  const _MenuBlock({required this.event});

  final DinnerEvent event;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    if (event.menu.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcSectionHeader(
          eyebrow: '${event.courseCount} courses',
          title: 'The menu',
          subtitle: event.menuStyle.label,
        ),
        DcSurface(
          radius: Radii.xl,
          shadows: dc.shadowSm,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.sm,
          ),
          child: Column(
            children: [
              for (var i = 0; i < event.menu.length; i++) ...[
                if (i > 0) Divider(color: dc.line, height: 1),
                _Course(index: i + 1, item: event.menu[i], dc: dc),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Course extends StatelessWidget {
  const _Course({required this.index, required this.item, required this.dc});

  final int index;
  final MenuItem item;
  final DcTheme dc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppType.serif(
                15,
                weight: 560,
                height: 1.2,
                tracking: -0.2,
                color: dc.inkFaint,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: AppType.serif(
                          17,
                          weight: 540,
                          height: 1.2,
                          tracking: -0.35,
                          color: dc.ink,
                        ),
                      ),
                    ),
                    if (item.isSignature) ...[
                      const SizedBox(width: Space.sm),
                      const DcTag(
                        'Signature',
                        icon: Icons.auto_awesome_rounded,
                        tone: PillTone.gold,
                        size: DcTagSize.small,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description, style: context.text.bodySmall),
                if (item.pairing != null) ...[
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      Icon(Icons.local_bar_rounded, size: 13, color: dc.pine),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.pairing!,
                          style: AppType.sans(
                            12,
                            weight: 560,
                            height: 1.3,
                            color: dc.pine,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Host ───────────────────────────────────────────────────────────────────
class _HostBlock extends StatelessWidget {
  const _HostBlock({required this.event, required this.host});

  final DinnerEvent event;
  final AppUser host;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcSectionHeader(eyebrow: 'Your host', title: 'Who is cooking up'),
        DcSurface(
          radius: Radii.xl,
          shadows: dc.shadowSm,
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HostLine(user: host, role: host.primaryRole),
              const SizedBox(height: Space.md),
              if (host.badges.isNotEmpty) ...[
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final badge in host.badges)
                      RoleBadge(badge, compact: true),
                  ],
                ),
                const SizedBox(height: Space.lg),
              ],
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: dc.surfaceAlt,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 18,
                      color: dc.inkFaint,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        event.hostNote,
                        style: AppType.sans(
                          13.5,
                          weight: 440,
                          height: 1.55,
                          color: dc.inkMuted,
                        ),
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

// ── Guests ─────────────────────────────────────────────────────────────────
class _GuestsBlock extends StatelessWidget {
  const _GuestsBlock({
    required this.event,
    required this.guests,
    required this.booking,
  });

  final DinnerEvent event;
  final List<AppUser> guests;
  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final vibe = switch (event.audience) {
      Audience.public =>
        'An open table — expect a mix of familiar faces and new ones.',
      Audience.followers =>
        'Mostly people who follow ${event.hostId == app.me?.id ? 'you' : 'the host'}.',
      Audience.friends => 'A close circle of friends of the host.',
      Audience.inviteOnly => 'Invite only — every guest is approved by hand.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcSectionHeader(
          eyebrow: 'The table',
          title: 'Who is coming',
          actionLabel: null,
        ),
        DcSurface(
          radius: Radii.xl,
          shadows: dc.shadowSm,
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (guests.isNotEmpty)
                    AvatarStack(
                      users: guests,
                      radius: 17,
                      max: 5,
                      ringColor: dc.surface,
                    ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${event.seatsTaken} of ${event.seatsTotal} seats taken',
                          style: context.text.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(vibe, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (booking != null) ...[
                const SizedBox(height: Space.lg),
                Divider(color: dc.line, height: 1),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_rounded, size: 16, color: dc.accent),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        'You are in. Say hello to the table before you arrive.',
                        style: AppType.sans(
                          12.5,
                          weight: 520,
                          height: 1.4,
                          color: dc.inkMuted,
                        ),
                      ),
                    ),
                    DcButton(
                      'Open chat',
                      size: DcButtonSize.small,
                      expand: false,
                      variant: DcButtonVariant.tonal,
                      onPressed: () => _showChatPlaceholder(context),
                    ),
                  ],
                ),
              ],
              if (guests.length > 4) ...[
                const SizedBox(height: Space.lg),
                Divider(color: dc.line, height: 1),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.md,
                  runSpacing: Space.sm,
                  children: [
                    for (final guest in guests)
                      if (guest.id != app.me?.id)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DcAvatar.of(guest, radius: 9),
                            const SizedBox(width: 5),
                            Text(
                              guest.firstName,
                              style: AppType.sans(
                                12,
                                weight: 560,
                                color: dc.inkMuted,
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showChatPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The table chat opens in the next step')),
    );
  }
}

// ── Venue ──────────────────────────────────────────────────────────────────
class _VenueBlock extends StatelessWidget {
  const _VenueBlock({required this.venue});

  final Restaurant venue;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcSectionHeader(
          eyebrow: 'The venue',
          title: 'Where you will sit',
        ),
        DcSurface(
          radius: Radii.xl,
          shadows: dc.shadowSm,
          clip: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 148,
                width: double.infinity,
                child: DcImage(venue.heroAsset, scrim: dc.cardScrim),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            venue.name,
                            style: AppType.serif(
                              19,
                              weight: 550,
                              height: 1.18,
                              tracking: -0.4,
                              color: dc.ink,
                            ),
                          ),
                        ),
                        if (venue.isPartner) ...[
                          const SizedBox(width: Space.sm),
                          Icon(
                            Icons.storefront_rounded,
                            size: 15,
                            color: dc.pine,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${venue.cuisine} · ${venue.address}',
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: Space.md),
                    Row(
                      children: [
                        MetaPill(
                          venue.priceLevelLabel,
                          icon: Icons.payments_rounded,
                        ),
                        const SizedBox(width: Space.lg),
                        MetaPill(
                          venue.openingHours,
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                    if (venue.isPartner) ...[
                      const SizedBox(height: Space.lg),
                      Divider(color: dc.line, height: 1),
                      const SizedBox(height: Space.lg),
                      VenuePerkStrip(venue: venue),
                    ],
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

// ── Reviews ────────────────────────────────────────────────────────────────
class _ReviewsBlock extends StatelessWidget {
  const _ReviewsBlock({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcSectionHeader(
          eyebrow: 'After the fact',
          title: 'Guest reviews',
          subtitle:
              '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'} for this host',
        ),
        Column(
          children: [
            for (var i = 0; i < reviews.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                child: _ReviewTile(review: reviews[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final author = context.app.user(review.authorId);

    return DcSurface(
      radius: Radii.lg,
      shadows: dc.shadowSm,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcAvatar.of(author, radius: 15),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(author.name, style: context.text.titleSmall),
                    const SizedBox(height: 2),
                    Text(review.eventTitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              RatingPill(rating: review.rating, compact: true),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            review.text,
            style: AppType.sans(
              13.5,
              weight: 430,
              height: 1.55,
              color: dc.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fine print ─────────────────────────────────────────────────────────────
class _FinePrint extends StatelessWidget {
  const _FinePrint({required this.event});

  final DinnerEvent event;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return DcSurface(
      radius: Radii.lg,
      color: dc.surfaceAlt,
      showBorder: false,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          DcKeyValue(label: 'Spoken language', value: event.language),
          DcKeyValue(
            label: 'Dress code',
            value: event.dressCode,
            divider: true,
          ),
          DcKeyValue(
            label: 'Cancellation',
            value: event.cancellation,
            divider: true,
          ),
        ],
      ),
    );
  }
}

// ── Reserve bar ────────────────────────────────────────────────────────────
class _ReserveBar extends StatelessWidget {
  const _ReserveBar({required this.event, required this.booking});

  final DinnerEvent event;
  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final seatsLeft = app.seatsLeftFor(event.id);
    final soldOut = seatsLeft <= 0;
    final booked = booking != null;

    final String label;
    if (booked) {
      label =
          'You have ${booking!.seats} ${booking!.seats == 1 ? 'seat' : 'seats'}';
    } else if (soldOut) {
      label = 'Sold out';
    } else {
      label = 'Reserve a seat';
    }

    return DcBottomBar(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PriceTag(
                amount: event.pricePerSeat,
                suffix: 'per seat',
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(event.seatsLabel, style: context.text.bodySmall),
            ],
          ),
          const Spacer(),
          DcButton(
            label,
            expand: false,
            variant: booked ? DcButtonVariant.tonal : DcButtonVariant.primary,
            icon: booked ? Icons.confirmation_number_rounded : null,
            onPressed: soldOut && !booked
                ? null
                : () => JoinSheet.show(context, eventId: event.id),
          ),
        ],
      ),
    );
  }
}

/// A bookable dining experience created by a host at a partner venue.
