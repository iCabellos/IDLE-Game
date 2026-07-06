import 'package:flutter/material.dart';

import '../../../core/models/inventory_item.dart';
import '../../../core/pixel/pixel_sprite.dart';
import '../../../core/pixel/pixel_widgets.dart';
import '../../../core/pixel/sprites.dart';
import '../../../core/theme/app_theme.dart';

/// Item inspection sheet shared by the Loot Bag and the Team screen:
/// sprite, rarity, set and descriptive trait lines — never numeric stats
/// (UX rule).
void showItemDetailSheet(BuildContext context, InventoryItem item) {
  final color = RarityColors.forRarity(item.rarityTier);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(12),
      child: PixelPanel(
        border: color,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: PixelArt(SpriteLibrary.forSlot(item.slot), size: 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PixelText(item.name.toUpperCase(), size: 12, maxLines: 2),
                      const SizedBox(height: 4),
                      PixelText(
                        '${item.rarity.toUpperCase()} · ${item.slot.toUpperCase()}',
                        size: 9,
                        color: color,
                        shadow: false,
                      ),
                      if (item.setName != null)
                        PixelText(
                          item.setName!.toUpperCase(),
                          size: 8,
                          color: AppColors.muted,
                          shadow: false,
                        ),
                    ],
                  ),
                ),
                if (item.equipped)
                  const PixelBadge(label: 'EQUIPPED', color: AppColors.success),
              ],
            ),
            if (item.traits.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final trait in item.traits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: PixelText('+ ${trait.toUpperCase()}',
                      size: 9, color: AppColors.accent, shadow: false),
                ),
            ],
            const SizedBox(height: 14),
            PixelButton(
              label: 'Close',
              height: 38,
              color: AppColors.surface,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
