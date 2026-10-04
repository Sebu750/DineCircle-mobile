import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'discover_screen.dart';
import 'explore_screen.dart';
import 'my_tables_screen.dart';
import 'profile_screen.dart';

/// The signed-in shell.
///
/// Every destination stays alive in an [IndexedStack] so scroll offsets,
/// filters and search text survive tab switches; [DcNavBar] floats above the
/// canvas and paints its blur over whatever is behind it.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _tabs = <Widget>[
    DiscoverScreen(),
    ExploreScreen(),
    // The raised create button owns this slot, so it never becomes visible.
    SizedBox.shrink(),
    MyTablesScreen(),
    ProfileScreen(),
  ];

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _create() => Go.create(context);

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Scaffold(
      backgroundColor: dc.canvas,
      extendBody: true,
      // The bar is allowed to overlap the canvas, so the body only steps aside
      // for the status bar and the system gesture zone.
      body: SafeArea(
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: DcNavBar(
        index: _index,
        onSelect: _select,
        onCreate: _create,
      ),
    );
  }
}
