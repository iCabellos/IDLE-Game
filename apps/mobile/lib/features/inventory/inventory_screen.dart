import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/inventory_item.dart';
import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/item_card.dart';

/// The party's loot bag, backed by `/items/inventory`.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _slotFilter = 'All';

  /// Item inspection sheet: sprite, rarity, set and descriptive trait
  /// lines — never numeric stats (UX rule).
  void _showItemDetail(BuildContext context, InventoryItem item) {
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

  @override
  Widget build(BuildContext context) {
    final slots = <String>['All', ...{for (final i in mockInventory) i.slot}];
    final items = _slotFilter == 'All'
        ? mockInventory
        : mockInventory.where((i) => i.slot == _slotFilter).toList();

    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    PixelArt(Sprites.satchel, size: 34),
                    SizedBox(width: 10),
                    PixelText('LOOT BAG', size: 18),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final selected = slot == _slotFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _slotFilter = slot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue : AppColors.surface,
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : const Color(0xFF0B1220),
                            width: 2,
                          ),
                        ),
                        child: PixelText(
                          slot.toUpperCase(),
                          size: 10,
                          color: selected ? AppColors.text : AppColors.muted,
                          shadow: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => _showItemDetail(context, item),
                      child: ItemCard(item: item),
                    )
                        .animate()
                        .fadeIn(delay: (40 * index).ms, duration: 300.ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
