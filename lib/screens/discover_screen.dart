import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/nav.dart';
import '../data/app_scope.dart';
import '../models/social.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'search_screen.dart';

/// The home feed: greeting, search, curated rails of tables, creators and
/// venues, then the full list of bookable dinners.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final now = DateTime.now();
    final width = MediaQuery.sizeOf(context).width;

    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
    final open = app.openEvents;
    final soon = open.take(3).toList(growable: false);
    final featured = app.featuredEvents.take(4).toList(growable: false);
    final near = app.nearbyEvents.take(8).toList(growable: false);
    final creators = app.influencers;
    final partners = app.partnerVenues;
    final all = app.filteredEvents.take(5).toList(growable: false);

    return CustomScrollView(
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
                    // Expanded rather than a Spacer: the wordmark gives up
                    // room to the bell and avatar instead of overflowing.
                    Expanded(child: DcWordmark(markSize: 27, fontSize: 20)),
                    DcIconButton(
                      Icons.notifications_none_rounded,
                      variant: DcIconButtonVariant.surface,
                      size: 42,
                      iconSize: 20,
                      badge: app.unreadCount > 0,
                      onPressed: () => showActivitySheet(context),
                    ),
                    const SizedBox(width: Space.sm),
                    GestureDetector(
                      onTap: () => showActivitySheet(context),
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
                  '$greeting, ${app.me!.firstName}',
                  style: AppType.serif(
                    27,
                    weight: 560,
                    height: 1.15,
                    tracking: -0.8,
                    color: dc.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${open.length} tables open this week · '
                  '${app.partnerVenues.length} partner venues',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: Space.lg),
                DcSearchField(
                  readOnly: true,
                  hint: 'Restaurants, hosts, cuisines…',
                  onTap: () => Go.search(context),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.lg)),
        SliverToBoxAdapter(child: FilterChipRail()),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),

        // ── Featured ────────────────────────────────────────────────────────
        if (featured.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DcSectionHeader(
              eyebrow: 'Featured',
              title: 'Tables worth planning for',
              subtitle: 'Hand-picked by the DineCircle team',
              actionLabel: 'See all',
              onAction: () => Go.browse(context),
            ),
          ),
          SliverToBoxAdapter(
            child: DcRail(
              height: 372 + 26,
              gap: Space.md,
              children: [
                for (final event in featured)
                  SizedBox(
                    width: width - Space.gutter * 2 - 28,
                    child: DinnerCardHero(
                      event: event,
                      saved: app.isSaved(event.id),
                      onToggleSave: () {
                        HapticFeedback.selectionClick();
                        app.toggleSaved(event.id);
                      },
                      onTap: () => Go.dinner(context, event.id),
                    ),
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],

        // ── Happening soon ──────────────────────────────────────────────────
        if (soon.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: DcSectionHeader(
              eyebrow: 'Diary',
              title: 'Happening soon',
              subtitle: 'The next tables with seats open',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Column(
                children: [
                  for (var i = 0; i < soon.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                      child: DinnerCardList(
                        event: soon[i],
                        saved: app.isSaved(soon[i].id),
                        onToggleSave: () => app.toggleSaved(soon[i].id),
                        onTap: () => Go.dinner(context, soon[i].id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],

        // ── Near you ────────────────────────────────────────────────────────
        if (near.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DcSectionHeader(
              eyebrow: 'Around you',
              title: 'Close to home',
              subtitle: 'Sorted by how far you have to travel',
              actionLabel: 'Browse',
              onAction: () => Go.browse(context),
            ),
          ),
          SliverToBoxAdapter(
            child: DcRail(
              height: 348 + 26,
              children: [
                for (final event in near)
                  DinnerCardTall(
                    event: event,
                    saved: app.isSaved(event.id),
                    onToggleSave: () {
                      HapticFeedback.selectionClick();
                      app.toggleSaved(event.id);
                    },
                    onTap: () => Go.dinner(context, event.id),
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],

        // ── Creators ────────────────────────────────────────────────────────
        if (creators.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DcSectionHeader(
              eyebrow: 'Food creators',
              title: 'Follow the people cooking',
              subtitle: 'Public tastings and exclusive tables',
              actionLabel: 'All hosts',
              onAction: () => Go.browse(context, tab: 2),
            ),
          ),
          SliverToBoxAdapter(
            child: DcRail(
              height: 236,
              children: [
                for (final creator in creators)
                  InfluencerCard(
                    user: creator,
                    upcoming: app
                        .byHost(creator.id)
                        .where((e) => e.isUpcoming)
                        .length,
                    tablesHosted: creator.dinnersHosted,
                    onTap: () => _openFirstTable(context, creator.id),
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],

        // ── Partner venues ──────────────────────────────────────────────────
        if (partners.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DcSectionHeader(
              eyebrow: 'Restaurant partners',
              title: 'Rooms that welcome the circle',
              subtitle: 'Special menus and guest perks',
              actionLabel: 'All venues',
              onAction: () => Go.browse(context, tab: 1),
            ),
          ),
          SliverToBoxAdapter(
            child: DcRail(
              height: 272,
              children: [
                for (final venue in partners)
                  VenueCardTall(
                    venue: venue,
                    onTap: () => Go.venue(context, venue.id),
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],

        // ── All tables ──────────────────────────────────────────────────────
        if (all.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DcSectionHeader(
              eyebrow: 'Everything open',
              title: app.hasActiveFilters
                  ? 'Matching your filters'
                  : 'All tables',
              subtitle: app.hasActiveFilters
                  ? 'Tap to refine the list'
                  : 'Book now, pay in the app',
              actionLabel: app.hasActiveFilters ? 'Clear' : 'See all',
              onAction: app.hasActiveFilters
                  ? app.clearFilters
                  : () => Go.browse(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Column(
                children: [
                  for (var i = 0; i < all.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                      child: DinnerCardList(
                        event: all[i],
                        saved: app.isSaved(all[i].id),
                        onToggleSave: () => app.toggleSaved(all[i].id),
                        onTap: () => Go.dinner(context, all[i].id),
                      ),
                    ),
                  const SizedBox(height: Space.lg),
                  DcButton(
                    'Open the full list',
                    variant: DcButtonVariant.outline,
                    size: DcButtonSize.medium,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () => Go.search(context),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: Space.navClearance)),
      ],
    );
  }

  void _openFirstTable(BuildContext context, String hostId) {
    final next = context.app
        .byHost(hostId)
        .where((event) => event.isUpcoming && !event.isSoldOut);
    if (next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No tables open with this host right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Go.dinner(context, next.first.id);
  }
}

/// Quick look at what happened while the guest was away.
Future<void> showActivitySheet(BuildContext context) {
  return DcSheet.show<void>(context, builder: (_) => const _ActivitySheet());
}

class _ActivitySheet extends StatelessWidget {
  const _ActivitySheet();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final items = app.activity;

    return DcSheet(
      title: 'Activity',
      subtitle: app.unreadCount > 0
          ? '${app.unreadCount} new since your last visit'
          : 'You are all caught up',
      child: SizedBox(
        height: 420,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, _) => Divider(color: dc.line, height: 1),
          itemBuilder: (context, i) => _ActivityRow(item: items[i]),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final (icon, tone) = switch (item.kind) {
      ActivityKind.newGuest => (Icons.person_add_alt_1_rounded, dc.accent),
      ActivityKind.payment => (Icons.credit_score_rounded, dc.pine),
      ActivityKind.reminder => (Icons.alarm_rounded, dc.gold),
      ActivityKind.follower => (Icons.people_alt_rounded, dc.accent),
      ActivityKind.payout => (Icons.account_balance_wallet_rounded, dc.pine),
      ActivityKind.invite => (Icons.mail_rounded, dc.gold),
      ActivityKind.review => (Icons.star_rounded, dc.gold),
    };

    return InkWell(
      onTap: item.eventId == null
          ? null
          : () {
              Navigator.of(context).maybePop();
              Go.dinner(context, item.eventId!);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title, style: context.text.titleSmall),
                      ),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dc.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.body, style: context.text.bodySmall),
                  const SizedBox(height: Space.sm),
                  Text(
                    Fmt.until(item.createdAt).contains('Past')
                        ? Fmt.dayMonth(item.createdAt)
                        : Fmt.until(item.createdAt),
                    style: AppType.sans(11, weight: 560, color: dc.inkFaint),
                  ),
                ],
              ),
            ),
            if (item.amount != null) ...[
              const SizedBox(width: Space.md),
              Text(
                Fmt.money(item.amount!),
                style: AppType.serif(
                  15,
                  weight: 600,
                  height: 1.2,
                  color: dc.pine,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
