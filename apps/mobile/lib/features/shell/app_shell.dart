import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/game/combat_service.dart';
import '../../core/theme/app_theme.dart';
import '../combat/combat_panel.dart';

/// App shell. The landscape combat panel is pinned at the top and stays alive
/// across every tab (the live fight is always on); the bottom area swaps per
/// tab. The combat poller is started once for the whole app lifetime.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, required this.currentPath});

  final Widget child;
  final String currentPath;

  static const _tabs = [
    (path: '/battle', icon: Icons.sports_kabaddi_rounded, label: 'Battle'),
    (path: '/inventory', icon: Icons.backpack_rounded, label: 'Inventory'),
    (path: '/widget', icon: Icons.widgets_rounded, label: 'Widget'),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    CombatService.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    final index = AppShell._tabs.indexWhere((t) => t.path == widget.currentPath).clamp(0, AppShell._tabs.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 6), child: CombatPanel()),
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navy,
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(AppShell._tabs[i].path),
        destinations: [
          for (final tab in AppShell._tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
