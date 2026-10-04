import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/nav.dart';
import '../data/app_scope.dart';
import '../data/app_state.dart';
import '../models/social.dart';
import '../models/user.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// The signed-in guest's own profile: summary, host console, settings and
/// reviews.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final me = app.me!;
    final isDark = dc.isDark;

    return Scaffold(
      backgroundColor: dc.canvas,
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
                          Icons.settings_outlined,
                          variant: DcIconButtonVariant.surface,
                          size: 42,
                          iconSize: 20,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings — coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xl),
                    Text(
                      'Profile',
                      style: AppType.serif(
                        28,
                        weight: 560,
                        height: 1.12,
                        tracking: -0.9,
                        color: dc.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),

            // ── Profile summary ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: ProfileSummaryCard(
                  user: me,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit profile — coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),

            // ── Host console ───────────────────────────────────────────────
            if (me.dinnersHosted > 0) ...[
              SliverToBoxAdapter(
                child: DcSectionHeader(
                  eyebrow: 'Hosting',
                  title: '${me.dinnersHosted} tables',
                  actionLabel: 'View earnings',
                  onAction: () => Go.tables(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: _HostConsole(app: app),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],

            // ── Settings ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: DcSectionHeader(eyebrow: 'Preferences', title: 'Settings'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: DcSurface(
                  radius: Radii.xl,
                  shadows: dc.shadowSm,
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    children: [
                      DcSwitchRow(
                        title: 'Dark mode',
                        subtitle: isDark ? 'Candle-lit' : 'Warm daylight',
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        value: isDark,
                        onChanged: (_) => app.toggleTheme(),
                      ),
                      Divider(color: dc.line, height: 1),
                      DcKeyValue(
                        label: 'Member since',
                        value: '${me.joinedYear}',
                        icon: Icons.calendar_month_rounded,
                        divider: true,
                      ),
                      DcKeyValue(
                        label: 'City',
                        value: me.city,
                        icon: Icons.place_outlined,
                        divider: true,
                      ),
                      DcKeyValue(
                        label: 'Tables joined',
                        value: '${me.dinnersJoined}',
                        icon: Icons.restaurant_rounded,
                        divider: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),

            // ── Reviews ────────────────────────────────────────────────────
            if (app.reviews.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: DcSectionHeader(
                  eyebrow: 'Reviews',
                  title: '${app.reviews.length} received',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final review = app.reviews[i];
                    final author = app.user(review.authorId);
                    return Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                      child: _ReviewTile(review: review, author: author),
                    );
                  }, childCount: app.reviews.length.clamp(0, 5)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],

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
// Host console
// ─────────────────────────────────────────────────────────────────────────────

class _HostConsole extends StatelessWidget {
  const _HostConsole({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final totalEarned = app.totalEarned;
    final inTransit = app.inTransit;
    final scheduled = app.scheduledEarnings;

    return DcSurface(
      radius: Radii.xl,
      shadows: dc.shadowSm,
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
              Text(
                Fmt.money(totalEarned + inTransit + scheduled),
                style: AppType.serif(
                  22,
                  weight: 620,
                  height: 1,
                  tracking: -0.6,
                  color: dc.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: DcStat(
                  value: Fmt.money(totalEarned),
                  label: 'PAID',
                  tone: dc.pine,
                ),
              ),
              Expanded(
                child: DcStat(
                  value: Fmt.money(inTransit),
                  label: 'IN TRANSIT',
                  tone: dc.gold,
                ),
              ),
              Expanded(
                child: DcStat(value: Fmt.money(scheduled), label: 'SCHEDULED'),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Divider(color: dc.line, height: 1),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: DcKeyValue(
                  label: 'Seats sold',
                  value: '${app.seatsSold}',
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: DcKeyValue(
                  label: 'Avg fill',
                  value: '${(app.averageFillRate * 100).round()}%',
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: DcKeyValue(
                  label: 'Avg price',
                  value: Fmt.money(app.averageSeatPrice),
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
// Review tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.author});

  final Review review;
  final AppUser author;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return DcSurface(
      radius: Radii.lg,
      shadows: dc.shadowSm,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcAvatar.of(author, radius: 18),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author.name, style: context.text.titleSmall),
                    Text(
                      review.eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              RatingPill(rating: review.rating),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            review.text,
            style: AppType.sans(
              13.5,
              weight: 430,
              height: 1.5,
              color: dc.inkMuted,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            Fmt.dayMonth(review.createdAt),
            style: AppType.sans(11, weight: 500, color: dc.inkFaint),
          ),
        ],
      ),
    );
  }
}
