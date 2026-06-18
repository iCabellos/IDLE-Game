import 'package:go_router/go_router.dart';

import '../../features/combat/battle_detail_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/widget_preview/widget_preview_screen.dart';

/// Navigation graph. The combat panel is pinned in the shell and always on;
/// each tab swaps the content below it.
final appRouter = GoRouter(
  initialLocation: '/battle',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(currentPath: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/battle', builder: (context, state) => const BattleDetailScreen()),
        GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
        GoRoute(path: '/widget', builder: (context, state) => const WidgetPreviewScreen()),
      ],
    ),
  ],
);
