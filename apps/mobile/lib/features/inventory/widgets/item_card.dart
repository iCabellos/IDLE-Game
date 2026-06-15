import 'package:flutter/material.dart';

import '../../../core/models/inventory_item.dart';
import '../../../core/theme/app_theme.dart';

/// A single inventory tile. Border/glow color encodes rarity via
/// [RarityColors] — no numeric stats are shown on the card itself.
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: isLegendary ? 2 : 1.5),
        boxShadow: isLegendary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForSlot(item.slot), color: color, size: 22),
              const Spacer(),
              if (item.equipped)
                const Icon(Icons.check_circle, color: AppColors.success, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.rarity,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if (item.setName != null)
            Text(
              item.setName!,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
        ],
      ),
    );
  }

  IconData _iconForSlot(String slot) => switch (slot) {
        'Head' => Icons.face,
        'Chest' => Icons.checkroom,
        'Legs' => Icons.accessibility_new,
        'Feet' => Icons.directions_walk,
        'Hands' => Icons.back_hand,
        'Ring' => Icons.circle_outlined,
        'Amulet' => Icons.diamond_outlined,
        'MainHand' => Icons.gavel,
        'OffHand' => Icons.shield_outlined,
        'TwoHand' => Icons.fitness_center,
        _ => Icons.auto_awesome,
      };
}
