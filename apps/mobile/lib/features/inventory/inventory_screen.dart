import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/inventory_item.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/item_card.dart';

/// Grid view of the player's inventory, backed by `/items/inventory`.
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
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final slot = slots[index];
                final selected = slot == _slotFilter;
                return ChoiceChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: (_) => setState(() => _slotFilter = slot),
                  selectedColor: AppColors.blue,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.text : AppColors.muted,
                    fontSize: 12,
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
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(item: items[index])
                    .animate()
                    .fadeIn(delay: (40 * index).ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
