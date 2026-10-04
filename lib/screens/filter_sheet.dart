import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../data/app_state.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Presents the shared refine sheet and returns once it is dismissed.
Future<void> showFilterSheet(BuildContext context) {
  return DcSheet.show<void>(context, builder: (_) => const FilterSheet());
}

const _sorts = <(FeedSort, String, IconData)>[
  (FeedSort.soonest, 'Soonest', Icons.schedule_rounded),
  (FeedSort.priceLow, 'Price ↑', Icons.south_rounded),
  (FeedSort.priceHigh, 'Price ↓', Icons.north_rounded),
  (FeedSort.bestRated, 'Top rated', Icons.star_rounded),
];

/// Sort, availability and cuisine — the controls that shape the feed.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final count = app.filteredEvents.length;

    return DcSheet(
      title: 'Refine your table',
      subtitle: 'Narrow the circle down to the evening you are after.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SORT BY', style: AppType.overline(color: dc.inkFaint)),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final (value, label, icon) in _sorts)
                  DcTag(
                    label,
                    icon: icon,
                    size: DcTagSize.medium,
                    selected: app.sort == value,
                    onTap: () => app.setSort(value),
                  ),
              ],
            ),
            const SizedBox(height: Space.xxl),
            Text('AVAILABILITY', style: AppType.overline(color: dc.inkFaint)),
            const SizedBox(height: Space.md),
            DcSurface(
              radius: Radii.lg,
              shadows: dc.shadowSm,
              child: Column(
                children: [
                  DcSwitchRow(
                    title: 'Tables with seats left',
                    subtitle: 'Hide dinners that are already full',
                    value: app.onlyAvailable,
                    onChanged: app.setOnlyAvailable,
                  ),
                  Divider(color: dc.line, height: 1),
                  DcSwitchRow(
                    title: 'Partner venues only',
                    subtitle: 'Restaurants offering a DineCircle perk',
                    value: app.onlyPartners,
                    onChanged: app.setOnlyPartners,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),
            Text('CUISINE', style: AppType.overline(color: dc.inkFaint)),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                DcTag(
                  'Anything',
                  size: DcTagSize.medium,
                  selected: app.cuisineFilter == 'All',
                  onTap: () => app.setCuisineFilter('All'),
                ),
                for (final cuisine in app.cuisines)
                  DcTag(
                    cuisine,
                    size: DcTagSize.medium,
                    selected: app.cuisineFilter == cuisine,
                    onTap: () => app.setCuisineFilter(cuisine),
                  ),
              ],
            ),
            const SizedBox(height: Space.xxl),
            Row(
              children: [
                Expanded(
                  child: DcButton(
                    'Reset',
                    variant: DcButtonVariant.outline,
                    size: DcButtonSize.medium,
                    onPressed: () {
                      app.clearFilters();
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  flex: 2,
                  child: DcButton(
                    count == 1 ? 'Show 1 table' : 'Show $count tables',
                    size: DcButtonSize.medium,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
