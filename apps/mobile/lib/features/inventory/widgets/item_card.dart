import 'package:flutter/material.dart';

import '../../../core/models/inventory_item.dart';
import '../../../core/pixel/pixel_sprite.dart';
import '../../../core/pixel/pixel_widgets.dart';
import '../../../core/pixel/sprites.dart';
import '../../../core/theme/app_theme.dart';

/// A single inventory slot, game style: dark inset cell, hand-drawn item
/// sprite, rarity-colored pixel frame. No numeric stats are ever shown.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final color = RarityColors.forRarity(item.rarityTier);
    final isLegendary = item.rarityTier >= 11;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0xFF0B1220), width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: isLegendary ? 0.55 : 0.0), blurRadius: 14),
          const BoxShadow(offset: Offset(3, 3), color: Color(0xFF0B1220)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item art in an inset "slot" cell.
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                border: Border.all(color: color, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: PixelArt(SpriteLibrary.forSlot(item.slot), size: 52),
                  ),
                  if (item.equipped)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        color: AppColors.success,
                        child: const PixelText('E', size: 8, shadow: false),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(item.name.toUpperCase(), size: 8, maxLines: 2),
                const SizedBox(height: 3),
                PixelText(item.rarity.toUpperCase(), size: 8, color: color, shadow: false),
                if (item.setName != null)
                  PixelText(
                    item.setName!.toUpperCase(),
                    size: 7,
                    color: AppColors.muted,
                    shadow: false,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
