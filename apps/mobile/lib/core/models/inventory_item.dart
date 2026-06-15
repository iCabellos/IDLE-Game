/// Lightweight client-side model mirroring the `/items/inventory` response
/// shape from the API (see IdleRPG.Application.UseCases.Items.GetInventory).
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.rarityTier,
    this.equipped = false,
    this.setName,
  });

  final String id;
  final String name;
  final String slot;
  final String rarity;
  final int rarityTier;
  final bool equipped;
  final String? setName;
}

/// A handful of items mirroring `ItemSeed.BuildItems()` — early-game gear
/// plus the four-piece Ironclad set.
const mockInventory = <InventoryItem>[
  InventoryItem(
    id: 'ironclad-helm',
    name: 'Ironclad Helm',
    slot: 'Head',
    rarity: 'Superior',
    rarityTier: 6,
    equipped: true,
    setName: 'Ironclad Set',
  ),
  InventoryItem(
    id: 'ironclad-cuirass',
    name: 'Ironclad Cuirass',
    slot: 'Chest',
    rarity: 'Superior',
    rarityTier: 6,
    equipped: true,
    setName: 'Ironclad Set',
  ),
  InventoryItem(
    id: 'ironclad-greaves',
    name: 'Ironclad Greaves',
    slot: 'Legs',
    rarity: 'Superior',
    rarityTier: 6,
    equipped: true,
    setName: 'Ironclad Set',
  ),
  InventoryItem(
    id: 'ironclad-sabatons',
    name: 'Ironclad Sabatons',
    slot: 'Feet',
    rarity: 'Superior',
    rarityTier: 6,
    setName: 'Ironclad Set',
  ),
  InventoryItem(
    id: 'rare-sword-1',
    name: 'Rare Sword 1',
    slot: 'MainHand',
    rarity: 'Rare',
    rarityTier: 5,
    equipped: true,
  ),
  InventoryItem(
    id: 'uncommon-shield-2',
    name: 'Uncommon Shield 2',
    slot: 'OffHand',
    rarity: 'Uncommon',
    rarityTier: 4,
  ),
  InventoryItem(
    id: 'common-ring-1',
    name: 'Common Ring 1',
    slot: 'Ring',
    rarity: 'Common',
    rarityTier: 3,
    equipped: true,
  ),
  InventoryItem(
    id: 'worn-amulet-2',
    name: 'Worn Amulet 2',
    slot: 'Amulet',
    rarity: 'Worn',
    rarityTier: 2,
  ),
  InventoryItem(
    id: 'broken-gauntlets-1',
    name: 'Broken Gauntlets 1',
    slot: 'Hands',
    rarity: 'Broken',
    rarityTier: 1,
  ),
  InventoryItem(
    id: 'legendary-relic',
    name: 'Ember of the First Flame',
    slot: 'Relic1',
    rarity: 'Legendary',
    rarityTier: 11,
  ),
];
