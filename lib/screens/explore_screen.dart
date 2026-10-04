import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nav.dart';
import '../data/app_scope.dart';
import '../models/user.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'search_screen.dart';

/// Browse surface: every table, venue and host in the circle.
///
/// Lives both as a tab and as a pushed screen — [standalone] swaps the header
/// for a back affordance and drops the floating-bar clearance.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.initialTab = 0,
    this.standalone = false,
  });

  final int initialTab;
  final bool standalone;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late int _tab = widget.initialTab.clamp(0, 2);
  String _cuisine = 'All';

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final bottomInset = widget.standalone
        ? Space.xxl + MediaQuery.viewPaddingOf(context).bottom
        : Space.navClearance;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.md,
              Space.gutter,
              0,
            ),
            child: Row(
              children: [
                if (widget.standalone) ...[
                  DcIconButton(
                    Icons.arrow_back_rounded,
                    size: 44,
                    iconSize: 20,
                    variant: DcIconButtonVariant.surface,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: Space.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore',
                        style: AppType.serif(
                          28,
                          weight: 560,
                          height: 1.1,
                          tracking: -0.9,
                          color: dc.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Every table, venue and host in the circle',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: DcSearchField(
              readOnly: true,
              onTap: () => Go.search(context),
            ),
          ),
          const SizedBox(height: Space.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: DcSegmented<int>(
              value: _tab,
              onChanged: (value) => setState(() => _tab = value),
              segments: const [
                DcSegment(0, 'Tables', icon: Icons.restaurant_rounded),
                DcSegment(1, 'Venues', icon: Icons.storefront_rounded),
                DcSegment(2, 'Hosts', icon: Icons.people_alt_rounded),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Expanded(child: _body(context, bottomInset)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, double bottomInset) {
    return switch (_tab) {
      0 => Column(
        children: [
          FilterChipRail(onChanged: () => setState(() {})),
          const SizedBox(height: Space.sm),
          Expanded(
            child: TableResults(
              bottomInset: bottomInset,
              emptyTitle: 'Nothing matches those filters',
            ),
          ),
        ],
      ),
      1 => _VenuesTab(
        cuisine: _cuisine,
        onCuisine: (value) => setState(() => _cuisine = value),
        bottomInset: bottomInset,
      ),
      _ => _HostsTab(bottomInset: bottomInset),
    };
  }
}

class _VenuesTab extends StatelessWidget {
  const _VenuesTab({
    required this.cuisine,
    required this.onCuisine,
    required this.bottomInset,
  });

  final String cuisine;
  final ValueChanged<String> onCuisine;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final venues = [...app.allVenues]
      ..sort((a, b) {
        if (a.isPartner != b.isPartner) return a.isPartner ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });
    final visible = cuisine == 'All'
        ? venues
        : venues
              .where(
                (v) => v.cuisine.toLowerCase().contains(cuisine.toLowerCase()),
              )
              .toList();

    return Column(
      children: [
        DcChipRow(
          options: app.cuisines,
          selected: cuisine == 'All' ? null : cuisine,
          allLabel: 'All kitchens',
          onSelected: (value) {
            HapticFeedback.selectionClick();
            onCuisine(value ?? 'All');
          },
        ),
        const SizedBox(height: Space.sm),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xs,
              Space.gutter,
              bottomInset,
            ),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.md),
            itemBuilder: (context, i) {
              final venue = visible[i];
              return VenueRow(
                venue: venue,
                trailingText: venue.isPartner ? 'Partner' : null,
                onTap: () => Go.venue(context, venue.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HostsTab extends StatelessWidget {
  const _HostsTab({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final creators = app.influencers;
    final hosts = app.otherHosts
        .where((u) => app.byHost(u.id).any((e) => e.isUpcoming))
        .toList(growable: false);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, bottomInset),
      children: [
        if (creators.isNotEmpty) ...[
          const DcSectionHeader(
            eyebrow: 'Food creators',
            title: 'Hosting tastings & tables',
            padding: EdgeInsets.only(bottom: Space.md),
          ),
          for (var i = 0; i < creators.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
              child: HostRow(
                user: creators[i],
                onTap: () => _openHost(context, creators[i]),
              ),
            ),
          const SizedBox(height: Space.xxl),
        ],
        if (hosts.isNotEmpty) ...[
          const DcSectionHeader(
            eyebrow: 'Open tables',
            title: 'Hosts with seats right now',
            padding: EdgeInsets.only(bottom: Space.md),
          ),
          for (var i = 0; i < hosts.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
              child: HostRow(
                user: hosts[i],
                onTap: () => _openHost(context, hosts[i]),
              ),
            ),
        ],
      ],
    );
  }

  /// Opens the host's next table — the reason you tapped them.
  void _openHost(BuildContext context, AppUser user) {
    final next = context.app
        .byHost(user.id)
        .where((event) => event.isUpcoming && !event.isSoldOut);
    if (next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} has no tables open right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Go.dinner(context, next.first.id);
  }
}
