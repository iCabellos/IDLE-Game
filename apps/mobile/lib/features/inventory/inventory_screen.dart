import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/inventory_item.dart';
import 'widgets/item_card.dart';
import 'widgets/item_detail_sheet.dart';

/// The party's loot bag, backed by `/items/inventory`.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _slotFilter = 'All';

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
                      onTap: () => showItemDetailSheet(context, item),
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
