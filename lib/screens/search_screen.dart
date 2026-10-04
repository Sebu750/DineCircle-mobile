import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nav.dart';
import '../data/app_scope.dart';
import '../data/app_state.dart';
import '../models/dinner_event.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'filter_sheet.dart';

/// Full search surface: query, experience filters and live results.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final query = context.app.query;
    if (query.isNotEmpty) _controller.text = query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;

    return Scaffold(
      backgroundColor: context.dc.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.sm,
                Space.gutter,
                0,
              ),
              child: Row(
                children: [
                  DcIconButton(
                    Icons.arrow_back_rounded,
                    size: 44,
                    iconSize: 20,
                    variant: DcIconButtonVariant.surface,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: DcSearchField(
                      controller: _controller,
                      autofocus: true,
                      hint: 'Tables, hosts, cuisines…',
                      onChanged: app.setQuery,
                      trailing: _controller.text.isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                _controller.clear();
                                app.setQuery('');
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: Space.sm),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: context.dc.inkFaint,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            FilterChipRail(onChanged: () => setState(() {})),
            const SizedBox(height: Space.sm),
            const Expanded(
              child: TableResults(
                emptyTitle: 'No table matches that',
                emptyMessage:
                    'Try a different cuisine, or loosen the filters to see '
                    'more of the city.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The filter rail shared by search and browse: refine first, then the
/// experience types.
class FilterChipRail extends StatelessWidget {
  const FilterChipRail({super.key, this.onChanged});

  /// Called after a chip mutates the store, so hosts can rebuild local state.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final app = context.app;

    return DcRailLike(
      children: [
        DcTag(
          app.hasActiveFilters ? 'Filters · on' : 'Filters',
          icon: Icons.tune_rounded,
          size: DcTagSize.medium,
          selected: app.hasActiveFilters,
          onTap: () async {
            HapticFeedback.selectionClick();
            await showFilterSheet(context);
            onChanged?.call();
          },
        ),
        for (final type in ExperienceType.values)
          DcTag(
            type.label,
            icon: type.icon,
            size: DcTagSize.medium,
            selected: app.typeFilter == type,
            onTap: () {
              HapticFeedback.selectionClick();
              app.setTypeFilter(app.typeFilter == type ? null : type);
              onChanged?.call();
            },
          ),
      ],
    );
  }
}

/// Live results list, driven entirely by the store's active filters.
class TableResults extends StatelessWidget {
  const TableResults({
    super.key,
    this.emptyTitle = 'No tables yet',
    this.emptyMessage,
    this.bottomInset,
    this.showHost = true,
  });

  final String emptyTitle;
  final String? emptyMessage;

  /// Extra bottom padding, e.g. clearance for the floating navigation bar.
  final double? bottomInset;

  final bool showHost;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final events = app.filteredEvents;
    final inset =
        bottomInset ?? Space.xxl + MediaQuery.viewPaddingOf(context).bottom;

    if (events.isEmpty) {
      return SingleChildScrollView(
        child: DcEmptyState(
          icon: Icons.search_off_rounded,
          title: emptyTitle,
          message: emptyMessage,
          actionLabel: app.hasActiveFilters ? 'Clear filters' : null,
          onAction: app.hasActiveFilters ? app.clearFilters : null,
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, inset),
      itemCount: events.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: Space.md),
      itemBuilder: (context, index) {
        if (index == 0) return _Summary(count: events.length, sort: app.sort);
        final event = events[index - 1];
        return DinnerCardList(
          event: event,
          showHost: showHost,
          saved: app.isSaved(event.id),
          onToggleSave: () {
            HapticFeedback.selectionClick();
            app.toggleSaved(event.id);
          },
          onTap: () => Go.dinner(context, event.id),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.sort});

  final int count;
  final FeedSort sort;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final label = switch (sort) {
      FeedSort.soonest => 'soonest first',
      FeedSort.priceLow => 'lowest price',
      FeedSort.priceHigh => 'highest price',
      FeedSort.bestRated => 'top rated',
    };

    return Padding(
      padding: const EdgeInsets.only(top: Space.xs, bottom: Space.xs),
      child: Row(
        children: [
          Text(
            count == 1 ? '1 table' : '$count tables',
            style: AppType.sans(13, weight: 680, color: dc.ink),
          ),
          const SizedBox(width: Space.sm),
          Text(
            '· $label',
            style: AppType.sans(12.5, weight: 500, color: dc.inkFaint),
          ),
        ],
      ),
    );
  }
}
