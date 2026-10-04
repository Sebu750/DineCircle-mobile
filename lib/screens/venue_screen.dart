import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/nav.dart';
import '../data/app_scope.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Partner venue profile: the room, the hours, the perk and every table
/// currently open there.
class VenueScreen extends StatelessWidget {
  const VenueScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final venue = app.venue(venueId);
    final tables = app.atVenue(venueId);

    return Scaffold(
      backgroundColor: dc.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
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
              DcIconButton(
                Icons.ios_share_rounded,
                variant: DcIconButtonVariant.glass,
                size: 40,
                iconSize: 18,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${venue.name} link copied'),
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
                  DcImage(
                    venue.heroAsset,
                    scrim: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0, 0.35, 1],
                    ),
                  ),
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
                            if (venue.isPartner) ...[
                              const DcTag(
                                'Partner venue',
                                icon: Icons.storefront_rounded,
                                tone: PillTone.glass,
                                size: DcTagSize.small,
                              ),
                              const SizedBox(width: Space.sm),
                            ],
                            RatingPill(
                              rating: venue.rating,
                              count: venue.reviewCount,
                              onImage: true,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.md),
                        Text(
                          venue.name,
                          style: AppType.serif(
                            28,
                            weight: 560,
                            height: 1.14,
                            tracking: -0.9,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${venue.cuisine} · ${venue.neighborhood}',
                          style: AppType.sans(
                            13,
                            weight: 520,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  Wrap(
                    spacing: Space.xl,
                    runSpacing: Space.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MetaPill(
                        venue.priceLevelLabel,
                        icon: Icons.payments_rounded,
                      ),
                      MetaPill(
                        Fmt.distance(venue.distanceMeters),
                        icon: Icons.near_me_rounded,
                      ),
                      MetaPill(
                        venue.openingHours,
                        icon: Icons.schedule_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  Text(
                    venue.description,
                    style: AppType.sans(
                      14.5,
                      weight: 430,
                      height: 1.62,
                      color: dc.inkMuted,
                    ),
                  ),
                  if (venue.tags.isNotEmpty) ...[
                    const SizedBox(height: Space.lg),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final tag in venue.tags)
                          DcTag(tag, size: DcTagSize.small),
                      ],
                    ),
                  ],
                  const SizedBox(height: Space.xl),
                  DcSurface(
                    radius: Radii.lg,
                    shadows: dc.shadowSm,
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      children: [
                        DcKeyValue(
                          label: 'Address',
                          value: venue.address,
                          icon: Icons.place_outlined,
                        ),
                        DcKeyValue(
                          label: 'Seats open to hosts',
                          value: '${venue.seatsAvailable} this month',
                          icon: Icons.chair_alt_outlined,
                          divider: true,
                        ),
                        DcKeyValue(
                          label: 'Guest benefit',
                          value: venue.partnerPerk ?? 'Standard bookings',
                          icon: Icons.redeem_outlined,
                          divider: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  DcSectionHeader(
                    eyebrow: tables.isEmpty
                        ? 'Nothing scheduled'
                        : '${tables.length} ${tables.length == 1 ? 'table' : 'tables'} open',
                    title: 'Tables at ${venue.name}',
                    subtitle: 'Hosted by members of the circle',
                  ),
                  if (tables.isEmpty)
                    DcSurface(
                      radius: Radii.lg,
                      color: dc.surfaceAlt,
                      showBorder: false,
                      child: const DcEmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'No tables yet',
                        message:
                            'Be the first to host an evening in this room.',
                        compact: true,
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < tables.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              top: i == 0 ? 0 : Space.md,
                            ),
                            child: DinnerCardList(
                              event: tables[i],
                              saved: app.isSaved(tables[i].id),
                              onToggleSave: () => app.toggleSaved(tables[i].id),
                              onTap: () => Go.dinner(context, tables[i].id),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
