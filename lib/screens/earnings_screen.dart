import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../models/booking.dart';
import '../widgets/dc_load_gate.dart';

/// The host earnings dashboard — replaces the old "coming soon" stub.
///
/// Shows headline numbers (earned, in-transit, scheduled), a 6-month trend
/// bar chart and the full payout history.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final meId = context.app.me?.id ?? '';
    context.app.refreshPayouts(meId).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: DcLoadGate(
        loading: _loading,
        onRetry: () {
          final meId = app.me?.id ?? '';
          app.refreshPayouts(meId).then((_) {
            if (mounted) setState(() => _loading = false);
          });
        },
        child: RefreshIndicator(
          onRefresh: () async {
            final meId = app.me?.id ?? '';
            await app.refreshPayouts(meId);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Earned',
                      value: app.totalEarned,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'In transit',
                      value: app.inTransit,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Scheduled',
                      value: app.scheduledEarnings,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),

              // Headline stats
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _InlineStat(
                      label: 'Lifetime gross',
                      value: '€${app.lifetimeGross.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 24),
                    _InlineStat(label: 'Seats sold', value: '${app.seatsSold}'),
                    const SizedBox(width: 24),
                    _InlineStat(
                      label: 'Avg seat',
                      value: '€${app.averageSeatPrice.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Trend chart
              if (app.trend.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Last 6 months',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: 140, child: _TrendBars(points: app.trend)),
                const Divider(height: 32),
              ],

              // Payout history
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Payouts', style: theme.textTheme.titleMedium),
              ),
              if (app.payouts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Center(
                    child: Text(
                      'No payouts yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...app.payouts.map((p) => _PayoutTile(payout: p)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '€${value.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout});
  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(payout.eventTitle),
      subtitle: Text(
        '${payout.date.day}/${payout.date.month}/${payout.date.year} · ${payout.seatsSold} seats',
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '€${payout.net.toStringAsFixed(0)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            payout.status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple bar chart for the 6-month trend data.
class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.points});
  final List<dynamic> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxRevenue = points.fold<double>(0, (m, p) {
      final rev = (p.revenue as double?) ?? 0;
      return rev > m ? rev : m;
    });
    final scale = maxRevenue > 0 ? 1.0 / maxRevenue : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((p) {
        final rev = (p.revenue as double?) ?? 0;
        final label = p.label as String? ?? '';
        final height = (rev * scale * 100).clamp(4.0, 100.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '€${rev.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 2),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
