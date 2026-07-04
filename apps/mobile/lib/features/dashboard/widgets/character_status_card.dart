import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/character_status.dart';
import '../../../core/pixel/pixel_sprite.dart';
import '../../../core/pixel/pixel_widgets.dart';
import '../../../core/pixel/sprites.dart';
import '../../../core/theme/app_theme.dart';

/// Surfaces the party's current high-level state as a pixel-art banner.
///
/// Never renders raw stat numbers — only the descriptive [CharacterStatus].
class CharacterStatusCard extends StatelessWidget {
  const CharacterStatusCard({super.key, required this.status, required this.zoneName});

  final CharacterStatus status;
  final String zoneName;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return PixelPanel(
      border: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Static icon: the state itself is the signal. A single entrance
          // pop happens at panel level; no perpetual pulsing.
          PixelArt(status.sprite, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(status.label.toUpperCase(), size: 15, color: color),
                const SizedBox(height: 6),
                PixelText(
                  status.description,
                  size: 10,
                  color: AppColors.muted,
                  shadow: false,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const PixelArt(Sprites.banner, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: PixelText(zoneName.toUpperCase(),
                          size: 10, color: AppColors.text, maxLines: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}
