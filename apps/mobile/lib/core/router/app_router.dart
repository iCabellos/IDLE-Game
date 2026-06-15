import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/widget_preview/widget_preview_screen.dart';

/// Top-level navigation graph. Full auth-gating and deep-link handling
/// land alongside the BLoC wiring in Phase F7.
final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(currentPath: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
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
