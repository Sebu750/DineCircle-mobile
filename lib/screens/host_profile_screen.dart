import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../data/app_scope.dart';
import '../models/user.dart';
import '../widgets/dc_avatar.dart';
import '../widgets/dc_buttons.dart';
import '../widgets/dc_load_gate.dart';

/// A host's public profile — bio, stats, follow button, upcoming tables and
/// the latest reviews their tables received.
class HostProfileScreen extends StatefulWidget {
  const HostProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _profile = await context.app.fetchUserProfile(widget.userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _profile != null
            ? Text((_profile!['user'] as Map)['name'] as String)
            : const Text('Profile'),
      ),
      body: DcLoadGate(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _profile == null
            ? const SizedBox.shrink()
            : _buildBody(app, theme),
      ),
    );
  }

  Widget _buildBody(dynamic app, ThemeData theme) {
    final user = AppUser.fromJson(_profile!['user'] as Map<String, dynamic>);
    final viewerFollows = _profile!['viewerFollows'] as bool? ?? false;
    final hosted = (_profile!['hostedUpcoming'] as List<dynamic>? ?? []);
    final reviews = (_profile!['reviews'] as List<dynamic>? ?? []);
    final isMe = app.me?.id == user.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                DcAvatar(
                  name: user.name,
                  imageAsset: user.avatarAsset,
                  radius: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (user.bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.bio,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Stat(label: 'Followers', value: user.followers),
                          const SizedBox(width: 16),
                          _Stat(label: 'Following', value: user.following),
                          const SizedBox(width: 16),
                          _Stat(label: 'Tables', value: user.dinnersHosted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Follow button
          if (!isMe)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: DcButton(
                viewerFollows ? 'Following' : 'Follow',
                variant: viewerFollows
                    ? DcButtonVariant.outline
                    : DcButtonVariant.primary,
                onPressed: _followBusy ? null : _toggleFollow,
                expand: false,
              ),
            ),

          const Divider(height: 1),

          // Upcoming tables
          if (hosted.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Upcoming tables',
                style: theme.textTheme.titleMedium,
              ),
            ),
            ...hosted.map((raw) {
              final e = raw as Map<String, dynamic>;
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    e['imageAsset'] as String? ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, ___) =>
                        const SizedBox(width: 48, height: 48),
                  ),
                ),
                title: Text(e['title'] as String? ?? ''),
                subtitle: Text(
                  '${e['seatsLeft'] ?? 0} seats left · €${(e['pricePerSeat'] as num?)?.toInt() ?? 0}/seat',
                ),
                onTap: () => Go.dinner(context, e['id'] as String),
              );
            }),
          ],

          // Reviews
          if (reviews.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Reviews', style: theme.textTheme.titleMedium),
            ),
            ...reviews.map((raw) {
              final r = raw as Map<String, dynamic>;
              final author = r['author'] as Map<String, dynamic>?;
              return ListTile(
                leading: DcAvatar(
                  name: author?['name'] as String? ?? '?',
                  imageAsset: author?['avatarAsset'] as String?,
                  radius: 18,
                ),
                title: Text(author?['name'] as String? ?? 'Guest'),
                subtitle: Text(
                  '★ ${(r['rating'] as num?)?.toDouble() ?? 0}.0 · ${r['eventTitle'] ?? ''}\n${r['text'] ?? ''}',
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    setState(() => _followBusy = true);
    try {
      await context.app.toggleFollow(widget.userId);
      await _load();
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
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
