import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/theme.dart';
import 'dc_image.dart';

/// Warm gradients used for people without a photo.
const List<List<Color>> _monogramGradients = [
  [Color(0xFFCF6A3E), Color(0xFF9A3F1D)],
  [Color(0xFF3E6A55), Color(0xFF214534)],
  [Color(0xFFB4893C), Color(0xFF7E5C1F)],
  [Color(0xFF4A5F86), Color(0xFF2C3D5E)],
  [Color(0xFF8A4468), Color(0xFF5C2A46)],
  [Color(0xFF6B5B4A), Color(0xFF443A2E)],
];

/// A person's portrait, falling back to a tinted monogram.
class DcAvatar extends StatelessWidget {
  const DcAvatar({
    super.key,
    this.user,
    this.name,
    this.imageAsset,
    this.radius = 22,
    this.borderColor,
    this.borderWidth = 0,
    this.showPresence = false,
    this.presenceColor,
  });

  /// Renders the portrait of [user], including the monogram fallback.
  const DcAvatar.of(
    AppUser account, {
    super.key,
    this.radius = 22,
    this.borderColor,
    this.borderWidth = 0,
    this.showPresence = false,
    this.presenceColor,
  }) : user = account,
       name = null,
       imageAsset = null;

  final AppUser? user;

  /// Used when only a name is known (new guests, system rows).
  final String? name;

  final String? imageAsset;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  /// Draws a small status dot in the corner.
  final bool showPresence;
  final Color? presenceColor;

  String get _displayName => user?.name ?? name ?? 'Guest';

  String get _initials {
    final parts = _displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  List<Color> get _gradient {
    final hex = user?.accentHex;
    if (hex != null) {
      final base = Color(hex);
      final hsl = HSLColor.fromColor(base);
      return [
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor(),
      ];
    }
    final index =
        _displayName.codeUnits.fold<int>(0, (sum, c) => sum + c) %
        _monogramGradients.length;
    return _monogramGradients[index];
  }

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset ?? user?.avatarAsset;

    Widget avatar = asset != null
        ? DcImage(
            asset,
            width: radius * 2,
            height: radius * 2,
            radius: radius,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          )
        : Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradient,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: AppType.serif(
                radius * 0.82,
                weight: 560,
                height: 1,
                tracking: 0,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          );

    if (radius <= 0) return avatar;

    if (borderWidth > 0) {
      avatar = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor ?? context.dc.surface,
        ),
        child: avatar,
      );
    }

    if (!showPresence) return avatar;

    final dot = radius * 0.42;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: presenceColor ?? context.dc.success,
              border: Border.all(
                color: context.dc.surface,
                width: radius * 0.11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Overlapping avatars with an optional overflow counter — the "who is coming"
/// signal used across table cards and detail screens.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.users,
    this.radius = 16,
    this.max = 4,
    this.ringColor,
    this.ringWidth = 2,
    this.overflowLabel,
  });

  final List<AppUser> users;
  final double radius;
  final int max;
  final Color? ringColor;
  final double ringWidth;

  /// When provided, replaces the computed `+N` chip.
  final String? overflowLabel;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final visible = users.take(max).toList();
    final remaining = users.length - visible.length;
    final step = radius * 1.42;
    final shown = visible.length + (remaining > 0 ? 1 : 0);

    if (shown == 0) {
      return SizedBox(height: radius * 2 + ringWidth * 2);
    }

    return SizedBox(
      height: radius * 2 + ringWidth * 2,
      width: step * (shown - 1) + radius * 2 + ringWidth * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              top: 0,
              child: DcAvatar.of(
                visible[i],
                radius: radius,
                borderColor: ringColor ?? dc.canvas,
                borderWidth: ringWidth,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visible.length * step,
              top: 0,
              child: Container(
                width: (radius + ringWidth) * 2,
                height: (radius + ringWidth) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor ?? dc.canvas,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dc.surfaceAlt,
                    border: Border.all(color: dc.line, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    overflowLabel ?? '+$remaining',
                    style: AppType.sans(
                      radius * 0.62,
                      weight: 700,
                      tracking: -0.2,
                      height: 1,
                      color: dc.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The table's host, shown as an avatar plus role and rating.
class HostLine extends StatelessWidget {
  const HostLine({
    super.key,
    required this.user,
    this.role,
    this.radius = 20,
    this.trailing,
    this.onTap,
    this.compact = false,
  });

  final AppUser user;
  final String? role;
  final double radius;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? Space.sm : Space.md),
        child: Row(
          children: [
            DcAvatar.of(user, radius: radius),
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
                          style: context.text.titleMedium,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: Space.xs + 2),
                        Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: dc.accent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role ?? '${user.primaryRole} · @${user.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
