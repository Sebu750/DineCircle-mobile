import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../models/social.dart';

/// The activity / notifications feed. Shows every notification the signed-in
/// user has received, newest first, with a "mark all read" action.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.app.refreshActivity();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final items = app.activity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (app.unreadCount > 0)
            TextButton.icon(
              onPressed: () => app.markActivityRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Read all'),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => app.refreshActivity(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (_, i) => _ActivityTile(item: items[i]),
              ),
            ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  IconData _iconFor(ActivityKind kind) {
    return switch (kind) {
      ActivityKind.newGuest => Icons.person_add_rounded,
      ActivityKind.payment => Icons.payments_rounded,
      ActivityKind.reminder => Icons.event_note_rounded,
      ActivityKind.follower => Icons.favorite_rounded,
      ActivityKind.payout => Icons.account_balance_wallet_rounded,
      ActivityKind.invite => Icons.mail_rounded,
      ActivityKind.review => Icons.rate_review_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.isUnread
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Icon(_iconFor(item.kind), color: accent, size: 20),
      ),
      title: Text(
        item.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.body.isNotEmpty)
            Text(
              item.body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            _timeAgo(item.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      trailing: item.isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
