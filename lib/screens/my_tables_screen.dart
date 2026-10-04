import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/nav.dart';
import '../data/app_scope.dart';
import '../models/booking.dart';
import '../models/dinner_event.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// The guest's home base: upcoming tickets, the host console, earnings and
/// past tables. Everything that moves a seat — in either direction — lives
/// here.
class MyTablesScreen extends StatelessWidget {
  const MyTablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final upcoming = app.myUpcomingBookings;
    final past = app.myPastBookings;
    final hosted = app.myHostedUpcoming;
    final totalEarned = app.totalEarned;
    final inTransit = app.inTransit;
    final scheduled = app.scheduledEarnings;

    return Scaffold(
      backgroundColor: dc.canvas,
      extendBody: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.md,
                  Space.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: DcWordmark(markSize: 27, fontSize: 20)),
                        DcIconButton(
                          Icons.notifications_none_rounded,
                          variant: DcIconButtonVariant.surface,
                          size: 42,
                          iconSize: 20,
                          badge: app.unreadCount > 0,
                          onPressed: () {
                            app.markActivityRead();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All caught up'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: Space.sm),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile — coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: DcAvatar.of(
                            app.me!,
                            radius: 19,
                            borderWidth: 2,
                            borderColor: dc.line,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xl),
                    Text(
                      'My tables',
                      style: AppType.serif(
                        28,
                        weight: 560,
                        height: 1.12,
                        tracking: -0.9,
                        color: dc.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${upcoming.length} upcoming · ${hosted.length} hosting',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),

            // ── Earnings overview ──────────────────────────────────────────────
            if (totalEarned > 0 || inTransit > 0 || scheduled > 0) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: _EarningsPanel(
                    totalEarned: totalEarned,
                    inTransit: inTransit,
                    scheduled: scheduled,
                    trend: app.trend,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],

            // ── Upcoming tickets ───────────────────────────────────────────────
            if (upcoming.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: DcSectionHeader(
                  eyebrow: 'Upcoming',
                  title: '${upcoming.length} tables',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                      child: _BookingTile(booking: upcoming[i]),
                    ),
                    childCount: upcoming.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],

            // ── Host console ───────────────────────────────────────────────────
            if (hosted.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: DcSectionHeader(
                  eyebrow: 'Hosting',
                  title: '${hosted.length} tables',
                  actionLabel: 'New table',
                  onAction: () => Go.create(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                      child: _HostedTile(event: hosted[i]),
                    ),
                    childCount: hosted.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],

            // ── Past bookings ──────────────────────────────────────────────────
            if (past.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: DcSectionHeader(
                  eyebrow: 'Past',
                  title: '${past.length} tables',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                      child: _BookingTile(booking: past[i], past: true),
                    ),
                    childCount: past.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],

            // ── Empty state ────────────────────────────────────────────────────
            if (upcoming.isEmpty && hosted.isEmpty && past.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: DcEmptyState(
                  icon: Icons.restaurant_rounded,
                  title: 'No tables yet',
                  message: 'Your upcoming reservations and hosted dinners will show up here.',
                  actionLabel: 'Find a table',
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: Space.navClearance),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earnings panel
// ─────────────────────────────────────────────────────────────────────────────

class _EarningsPanel extends StatelessWidget {
  const _EarningsPanel({
    required this.totalEarned,
    required this.inTransit,
    required this.scheduled,
    required this.trend,
  });

  final double totalEarned;
  final double inTransit;
  final double scheduled;
  final List<EarningsPoint> trend;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;

    return DcSurface(
      radius: Radii.xxl,
      shadows: dc.shadowMd,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, size: 18, color: dc.accent),
              const SizedBox(width: Space.sm),
              Text('EARNINGS', style: AppType.overline(color: dc.accent)),
              const Spacer(),
              DcIconButton(
                Icons.arrow_forward_rounded,
                variant: DcIconButtonVariant.surface,
                size: 34,
                iconSize: 16,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full earnings dashboard — coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(
            Fmt.money(totalEarned + inTransit + scheduled),
            style: AppType.serif(
              34,
              weight: 620,
              height: 1,
              tracking: -1.2,
              color: dc.ink,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'lifetime net',
            style: AppType.sans(12, weight: 500, color: dc.inkFaint),
          ),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: DcStat(
                  value: Fmt.money(totalEarned),
                  label: 'Paid out',
                  icon: Icons.check_circle_rounded,
                  tone: dc.pine,
                ),
              ),
              Expanded(
                child: DcStat(
                  value: Fmt.money(inTransit),
                  label: 'In transit',
                  icon: Icons.local_shipping_outlined,
                  tone: dc.gold,
                ),
              ),
              Expanded(
                child: DcStat(
                  value: Fmt.money(scheduled),
                  label: 'Scheduled',
                  icon: Icons.schedule_rounded,
                  tone: dc.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (trend.isNotEmpty) ...[
            DcKeyValue(
              label: 'Next payout',
              value: Fmt.dayMonth(app.nextPayoutDate),
              icon: Icons.calendar_month_rounded,
            ),
            const SizedBox(height: Space.lg),
            TrendBars(points: trend),
          ],
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: DcKeyValue(
                  label: 'Seats sold',
                  value: '${app.seatsSold}',
                  divider: true,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: DcKeyValue(
                  label: 'Avg fill rate',
                  value: '${(app.averageFillRate * 100).round()}%',
                  divider: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking tile
// ─────────────────────────────────────────────────────────────────────────────

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, this.past = false});

  final Booking booking;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    if (!app.hasEvent(booking.eventId)) return const SizedBox.shrink();
    final event = app.event(booking.eventId);
    final venue = app.restaurantFor(event);

    return DcSurface(
      radius: Radii.xl,
      shadows: dc.shadowSm,
      onTap: () => Go.dinner(context, event.id),
      clip: true,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DcImage(event.imageAsset, radius: 0),
                Positioned(
                  left: Space.sm,
                  top: Space.sm,
                  child: DateBadge(date: event.start, onImage: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.md),
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
                          style: context.text.titleSmall,
                        ),
                      ),
                      StatusPill.booking(booking.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${venue.name} · ${event.timeRangeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 13,
                        color: dc.inkFaint,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          booking.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.sans(
                            11.5,
                            weight: 640,
                            tracking: 0.4,
                            color: dc.inkMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Icon(Icons.person_rounded, size: 13, color: dc.inkFaint),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.seats} ${booking.seats == 1 ? 'seat' : 'seats'}',
                        style: context.text.bodySmall,
                      ),
                      const Spacer(),
                      if (booking.checkedIn)
                        StatusPill('Checked in', tone: PillTone.pine)
                      else if (!past &&
                          booking.status == BookingStatus.confirmed)
                        Flexible(
                          child: Text(
                            Fmt.until(event.start),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.sans(
                              11.5,
                              weight: 620,
                              color: dc.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Icon(Icons.chevron_right_rounded, size: 18, color: dc.inkFaint),
          const SizedBox(width: Space.sm),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hosted tile
// ─────────────────────────────────────────────────────────────────────────────

class _HostedTile extends StatefulWidget {
  const _HostedTile({required this.event});

  final DinnerEvent event;

  @override
  State<_HostedTile> createState() => _HostedTileState();
}

class _HostedTileState extends State<_HostedTile> {
  List<Booking> _guests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.app.guestsFor(widget.event.id);
      if (mounted) setState(() => _guests = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final event = widget.event;
    final venue = app.restaurantFor(event);
    final guests = _guests;
    final gross = event.seatsTaken * event.pricePerSeat;
    final net = gross * 0.92;

    return DcSurface(
      radius: Radii.xl,
      shadows: dc.shadowSm,
      onTap: () => Go.dinner(context, event.id),
      clip: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero strip with the event image and date badge.
          SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DcImage(event.imageAsset, radius: 0),
                Positioned(
                  left: Space.lg,
                  top: Space.lg,
                  child: DateBadge(date: event.start, onImage: true),
                ),
                Positioned(
                  right: Space.lg,
                  top: Space.lg,
                  child: DcTag(
                    event.type.label,
                    icon: event.type.icon,
                    tone: PillTone.glass,
                    size: DcTagSize.small,
                  ),
                ),
                Positioned(
                  left: Space.lg,
                  right: Space.lg,
                  bottom: Space.md,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.serif(
                            18,
                            weight: 580,
                            height: 1.1,
                            tracking: -0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${venue.name} · ${event.timeRangeLabel}',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: Space.md),
                SeatMeter(
                  filled: event.seatsTaken,
                  total: event.seatsTotal,
                  showCounts: true,
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(
                      child: DcKeyValue(
                        label: 'Gross',
                        value: Fmt.money(gross),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: DcKeyValue(
                        label: 'You keep',
                        value: Fmt.money(net),
                        valueColor: dc.pine,
                        emphasis: true,
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: DcKeyValue(
                        label: 'Guests',
                        value: '${guests.length}',
                      ),
                    ),
                  ],
                ),
                if (guests.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  Divider(color: dc.line, height: 1),
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final g in guests.take(5))
                        DcAvatar.of(app.user(g.guestId), radius: 14),
                      if (guests.length > 5)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: dc.surfaceSunken,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '+${guests.length - 5}',
                              style: AppType.sans(
                                10,
                                weight: 640,
                                color: dc.inkMuted,
                              ),
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
