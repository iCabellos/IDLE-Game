import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Bottom navigation shell wrapping the authenticated app sections.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.currentPath});

  final Widget child;
  final String currentPath;

  static const _tabs = [
    (path: '/dashboard', icon: Icons.home_rounded, label: 'Home'),
    (path: '/inventory', icon: Icons.backpack_rounded, label: 'Inventory'),
    (path: '/widget', icon: Icons.widgets_rounded, label: 'Widget'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexWhere((t) => t.path == currentPath).clamp(0, _tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navy,
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
