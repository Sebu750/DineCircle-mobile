import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'dc_buttons.dart';

/// A bottom navigation destination.
class DcDestination {
  const DcDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Floating, blurred navigation bar with a raised create action in the centre.
///
/// Five slots: the middle one is deliberately left empty so the create button
/// can sit proud of the bar without stealing a label.
class DcNavBar extends StatelessWidget {
  const DcNavBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onCreate,
  });

  static const destinations = <DcDestination>[
    DcDestination(
      label: 'Discover',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    DcDestination(
      label: 'Explore',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    DcDestination(
      label: '',
      icon: Icons.add_rounded,
      activeIcon: Icons.add_rounded,
    ),
    DcDestination(
      label: 'Tables',
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
    ),
    DcDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  /// Index of the slot reserved for the create button.
  static const createIndex = 2;

  /// Total height the bar occupies, including the raised button.
  static const totalHeight = 88.0;

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Padding(
      padding: EdgeInsets.only(
        left: Space.lg,
        right: Space.lg,
        bottom: Space.md + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: SizedBox(
        height: totalHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const buttonSize = 58.0;
            final barHeight = totalHeight - 18;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: barHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.xl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: dc.glass,
                          borderRadius: BorderRadius.circular(Radii.xl),
                          border: Border.all(
                            color: dc.isDark
                                ? dc.line
                                : dc.line.withValues(alpha: 0.9),
                            width: 1,
                          ),
                          boxShadow: dc.shadowFloating,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: i == createIndex
                                    ? const SizedBox.shrink()
                                    : _NavItem(
                                        destination: destinations[i],
                                        selected: index == i,
                                        onTap: () {
                                          if (index == i) return;
                                          HapticFeedback.selectionClick();
                                          onSelect(i);
                                        },
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth / 2 - buttonSize / 2,
                  bottom: barHeight - buttonSize / 2 - 4,
                  child: _CreateButton(size: buttonSize, onTap: onCreate),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DcDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final activeColor = dc.isDark ? dc.accent : AppColors.clay600;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Motion.base,
            curve: Motion.enter,
            height: 30,
            width: 48,
            decoration: BoxDecoration(
              color: selected ? dc.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(
              selected ? destination.activeIcon : destination.icon,
              size: 21,
              color: selected ? activeColor : dc.inkFaint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            destination.label,
            style: AppType.sans(
              10.5,
              weight: selected ? 720 : 560,
              height: 1,
              tracking: 0.1,
              color: selected ? dc.ink : dc.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return PressableScale(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: dc.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: dc.accent.withValues(alpha: 0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: dc.isDark ? Colors.black54 : const Color(0x1A2B211A),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            splashColor: dc.onAccent.withValues(alpha: 0.16),
            child: Icon(Icons.add_rounded, size: 27, color: dc.onAccent),
          ),
        ),
      ),
    );
  }
}

/// Screen header used by every sub-screen: a back affordance, an optional
/// title and trailing actions.
class DcAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DcAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.transparent = false,
    this.onBack,
    this.bottom,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  /// Removes the background so the header can sit over imagery.
  final bool transparent;

  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(60 + (subtitle != null ? 18 : 0) + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return AppBar(
      backgroundColor: transparent ? Colors.transparent : dc.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: 60 + (subtitle != null ? 18 : 0),
      systemOverlayStyle: dc.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leadingWidth: showBack ? 64 : 0,
      leading: showBack
          ? Center(
              child: DcIconButton(
                Icons.arrow_back_rounded,
                size: 40,
                iconSize: 20,
                variant: transparent ? DcIconButtonVariant.glass : DcIconButtonVariant.surface,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              ),
            )
          : null,
      title: title == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: transparent
                      ? AppType.serif(19, weight: 560, height: 1.2, tracking: -0.3, color: Colors.white)
                      : context.text.titleLarge,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.sans(
                      12,
                      weight: 500,
                      height: 1.3,
                      color: transparent ? Colors.white70 : dc.inkFaint,
                    ),
                  ),
              ],
            ),
      actions: [...actions, const SizedBox(width: Space.md)],
      bottom: bottom,
    );
  }
}
