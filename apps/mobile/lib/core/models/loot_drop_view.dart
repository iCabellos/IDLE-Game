/// Client-side view of a generated ARPG drop, mirroring the backend's
/// `LootDropDto` (`/combat/state` → RecentLoot): Diablo-style name, rarity,
/// archetype and descriptive affix text — never rolled numbers.
class LootDropView {
  const LootDropView({
    required this.name,
    required this.rarity,
    required this.rarityTier,
    required this.archetype,
    required this.slot,
    this.affixes = const [],
  });

  final String name;
  final String rarity;
  final int rarityTier;
  final String archetype;
  final String slot;
  final List<String> affixes;
}

/// Mock drop feed shaped exactly like LootGenerator output (F4 loot rework).
const mockLootFeed = <LootDropView>[
  LootDropView(
    name: 'Crushing Maul of Ruin',
    rarity: 'Legendary',
    rarityTier: 11,
    archetype: 'Breaker',
    slot: 'TwoHand',
    affixes: ['Devastating weakness breaks', 'Harder weakness breaks', 'Acts sooner'],
  ),
  LootDropView(
    name: 'Gilded Signet of Fortune',
    rarity: 'Ancient',
    rarityTier: 9,
    archetype: 'Fortunate',
    slot: 'Ring',
    affixes: ['Much rarer finds', 'Rarer finds', 'More finds'],
  ),
  LootDropView(
    name: 'Savage Blade of Slaughter',
    rarity: 'Mythic',
    rarityTier: 8,
    archetype: 'Executioner',
    slot: 'MainHand',
    affixes: ['More attack', 'Much more attack'],
  ),
  LootDropView(
    name: 'Storm Casque of the Tempest',
    rarity: 'Epic',
    rarityTier: 7,
    archetype: 'Stormcaller',
    slot: 'Head',
    affixes: ['More spellpower', 'Much more spellpower'],
  ),
  LootDropView(
    name: 'Colossus Cuirass',
    rarity: 'Common',
    rarityTier: 3,
    archetype: 'Juggernaut',
    slot: 'Chest',
  ),
];
