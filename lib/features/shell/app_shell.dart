import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/terrace_theme.dart';
import '../ads/house_ad.dart';

/// Root shell hosting the four primary destinations via a StatefulShellRoute.
/// Community and Following are reachable from Profile (kept off the bottom bar so it stays uncluttered).
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _destinations = <_Dest>[
    _Dest('Play', LucideIcons.gamepad2),
    _Dest('Scores', LucideIcons.activity),
    _Dest('News', LucideIcons.newspaper),
    _Dest('Profile', LucideIcons.user),
  ];

  @override
  void initState() {
    super.initState();
    // House interstitial (pop-up) ad — at most once per session, free users only.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowInterstitial(context, ref);
    });
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns to its root.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: t.border)),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.icon, color: t.brand),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _Dest {
  final String label;
  final IconData icon;
  const _Dest(this.label, this.icon);
}
