import 'package:go_router/go_router.dart';

import '../../features/combat/combat_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/widget_preview/widget_preview_screen.dart';

/// Navigation graph. The app lands DIRECTLY in the live battle — no login
/// gate, no landing page. The fight is the home screen.
final appRouter = GoRouter(
  initialLocation: '/battle',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(currentPath: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/battle',
          builder: (context, state) => const CombatScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/widget',
          builder: (context, state) => const WidgetPreviewScreen(),
        ),
      ],
    ),
  ],
);
