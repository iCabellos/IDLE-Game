import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';

/// Bottom navigation shell wrapping the authenticated app sections.
/// Styled as a retro game HUD bar with sprite icons.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.currentPath});

  final Widget child;
  final String currentPath;

  static const _tabs = [
    (path: '/dashboard', sprite: Sprites.castle, label: 'HALL'),
    (path: '/inventory', sprite: Sprites.satchel, label: 'BAG'),
    (path: '/widget', sprite: Sprites.crystal, label: 'CHARM'),
  ];

  @override
  Widget build(BuildContext context) {
    final index =
        _tabs.indexWhere((t) => t.path == currentPath).clamp(0, _tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navy,
          border: Border(
            top: BorderSide(color: Color(0xFF0B1220), width: 3),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final (i, tab) in _tabs.indexed)
                  Expanded(
                    child: _ShellTab(
                      sprite: tab.sprite,
                      label: tab.label,
                      selected: i == index,
                      onTap: () => context.go(tab.path),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTab extends StatelessWidget {
  const _ShellTab({
    required this.sprite,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PixelSprite sprite;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: selected
            ? const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.accent, width: 3),
                ),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelArt(sprite, size: selected ? 30 : 26),
            const SizedBox(height: 2),
            PixelText(
              label,
              size: 9,
              color: selected ? AppColors.accent : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
