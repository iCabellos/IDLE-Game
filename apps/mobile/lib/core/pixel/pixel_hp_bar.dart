import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Always-on health bar. Shows a *fraction* only — never numeric HP (UX
/// rule). Color shifts with the remaining fraction so danger reads at a
/// glance: green, then amber, then red. Drawn with a hard pixel frame.
class PixelHpBar extends StatelessWidget {
  const PixelHpBar({
    super.key,
    required this.fraction,
    this.width = 44,
    this.height = 7,
  });

  final double fraction;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    final color = f > 0.55
        ? AppColors.success
        : f > 0.25
            ? AppColors.amber
            : AppColors.danger;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.7), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f == 0 ? 0.0001 : f,
          child: Container(color: color),
        ),
      ),
    );
  }
}
