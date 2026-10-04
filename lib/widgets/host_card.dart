import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/app_scope.dart';
import '../models/user.dart';
import '../theme/theme.dart';
import 'dc_avatar.dart';
import 'dc_buttons.dart';
import 'dc_pills.dart';
import 'dc_surfaces.dart';

/// Portrait card for the food creators rail.
class InfluencerCard extends StatelessWidget {
  const InfluencerCard({
    super.key,
    required this.user,
    required this.onTap,
    this.tablesHosted = 0,
    this.upcoming = 0,
    this.width = 176,
  });

  final AppUser user;
  final VoidCallback onTap;
  final int tablesHosted;

  /// Number of bookable tables this creator has open right now.
  final int upcoming;

  final double width;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return SizedBox(
      width: width,
      child: PressableScale(
        onTap: onTap,
        child: DcSurface(
          radius: Radii.xl,
          shadows: dc.shadowSm,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: dc.accentGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dc.surface,
                      ),
                      child: DcAvatar.of(user, radius: 33),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: dc.goldSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: dc.surface, width: 2.5),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: dc.gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.sans(
                        14.5,
                        weight: 700,
                        height: 1.15,
                        color: dc.ink,
                      ),
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 14, color: dc.accent),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '@${user.handle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.sans(
                  11.5,
                  weight: 500,
                  height: 1.1,
                  color: dc.inkFaint,
                ),
              ),
              const SizedBox(height: Space.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dc.surfaceAlt,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  '${Fmt.compact(user.followers)} followers',
                  style: AppType.sans(
                    11,
                    weight: 660,
                    height: 1.1,
                    color: dc.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm + 2),
              Text(
                upcoming > 0 ? '$upcoming tables open' : '$tablesHosted hosted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.sans(
                  11.5,
                  weight: 540,
                  height: 1.1,
                  color: dc.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dense row for the host list, with a follow control wired to the store.
class HostRow extends StatelessWidget {
  const HostRow({
    super.key,
    required this.user,
    required this.onTap,
    this.showFollow = true,
    this.trailing,
  });

  final AppUser user;
  final VoidCallback onTap;
  final bool showFollow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final following = app.isFollowing(user.id);

    return DcSurface(
      radius: Radii.lg,
      shadows: dc.shadowSm,
      onTap: onTap,
      clip: true,
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          DcAvatar.of(user, radius: 26, showPresence: user.dinnersHosted > 0),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded, size: 13, color: dc.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: Space.sm),
                // Wrap, not Row: three-digit host counts push the second
                // pill onto its own line instead of past the card edge.
                Wrap(
                  spacing: Space.md,
                  runSpacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MetaPill(
                      '${user.dinnersHosted} hosted',
                      icon: Icons.local_dining_rounded,
                    ),
                    MetaPill(
                      Fmt.compact(user.followers),
                      icon: Icons.people_alt_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (showFollow)
            SizedBox(
              width: 92,
              child: DcButton(
                following ? 'Following' : 'Follow',
                onPressed: () => app.toggleFollow(user.id),
                variant: following
                    ? DcButtonVariant.outline
                    : DcButtonVariant.primary,
                size: DcButtonSize.small,
              ),
            ),
        ],
      ),
    );
  }
}

/// The signed-in guest's own summary card, reused on the profile screen.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({super.key, required this.user, this.onTap});

  final AppUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return DcSurface(
      radius: Radii.xl,
      shadows: dc.shadowMd,
      padding: const EdgeInsets.all(Space.lg),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              DcAvatar.of(user, radius: 34, showPresence: true),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.headlineSmall,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: dc.accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${user.handle} · ${user.city}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.badges.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final badge in user.badges)
                    RoleBadge(badge, compact: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          Divider(color: dc.line, height: 1),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: DcStat(
                  value: Fmt.compact(user.followers),
                  label: 'FOLLOWERS',
                  align: CrossAxisAlignment.center,
                ),
              ),
              Container(width: 1, height: 34, color: dc.line),
              Expanded(
                child: DcStat(
                  value: '${user.dinnersJoined}',
                  label: 'TABLES JOINED',
                  align: CrossAxisAlignment.center,
                ),
              ),
              Container(width: 1, height: 34, color: dc.line),
              Expanded(
                child: DcStat(
                  value: '${user.dinnersHosted}',
                  label: 'HOSTED',
                  align: CrossAxisAlignment.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
