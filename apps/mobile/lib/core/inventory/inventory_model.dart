import 'dart:async';
import 'dart:ui';

/// ---------------------------------------------------------------------------
/// Inventory model. Gear is bound to a CHARACTER, not the account.
/// Delivered asynchronously by [InventoryRepository].
/// ---------------------------------------------------------------------------

/// The 21 canonical rarity tiers (mirrors IdleRPG.Domain.Enums.ItemRarity).
enum Rarity {
  broken, worn, common, uncommon, rare, superior, epic, mythic, ancient, relic,
  legendary, ascended, divine, celestial, primordial, transcendent,
  unique, seasonal, founder, eventLimited, oneOfOne,
}

extension RarityX on Rarity {
  int get tier => index + 1;

  String get label => switch (this) {
        Rarity.broken => 'Broken',
        Rarity.worn => 'Worn',
        Rarity.common => 'Common',
        Rarity.uncommon => 'Uncommon',
        Rarity.rare => 'Rare',
        Rarity.superior => 'Superior',
        Rarity.epic => 'Epic',
        Rarity.mythic => 'Mythic',
        Rarity.ancient => 'Ancient',
        Rarity.relic => 'Relic',
        Rarity.legendary => 'Legendary',
        Rarity.ascended => 'Ascended',
        Rarity.divine => 'Divine',
        Rarity.celestial => 'Celestial',
        Rarity.primordial => 'Primordial',
        Rarity.transcendent => 'Transcendent',
        Rarity.unique => 'Unique',
        Rarity.seasonal => 'Seasonal',
        Rarity.founder => 'Founder',
        Rarity.eventLimited => 'Event',
        Rarity.oneOfOne => '1-of-1',
      };

  Color get color => switch (this) {
        Rarity.broken => const Color(0xFF6B7280),
        Rarity.worn => const Color(0xFF9CA3AF),
        Rarity.common => const Color(0xFFE5E7EB),
        Rarity.uncommon => const Color(0xFF34D399),
        Rarity.rare => const Color(0xFF60A5FA),
        Rarity.superior => const Color(0xFF818CF8),
        Rarity.epic => const Color(0xFFA78BFA),
        Rarity.mythic => const Color(0xFFF472B6),
        Rarity.ancient => const Color(0xFFFBBF24),
        Rarity.relic => const Color(0xFFF97316),
        Rarity.legendary => const Color(0xFFFFD700),
        Rarity.ascended => const Color(0xFFE879F9),
        Rarity.divine => const Color(0xFFFFE9A8),
        Rarity.celestial => const Color(0xFF67E8F9),
        Rarity.primordial => const Color(0xFF2DD4BF),
        Rarity.transcendent => const Color(0xFFC084FC),
        Rarity.unique => const Color(0xFFFF6B6B),
        Rarity.seasonal => const Color(0xFF22D3A6),
        Rarity.founder => const Color(0xFFF59E0B),
        Rarity.eventLimited => const Color(0xFF38BDF8),
        Rarity.oneOfOne => const Color(0xFFFF2D95),
      };

  /// Honkai-style 1..5 star rating derived from the tier.
  int get stars {
    final t = tier;
    if (t <= 2) return 1;
    if (t <= 4) return 2;
    if (t <= 7) return 3;
    if (t <= 11) return 4;
    return 5;
  }

  /// Tiers above Transcendent have FIXED stats and are not tradeable.
  bool get isElite => index >= Rarity.unique.index;
}

/// The 12 equipment slots (mirrors IdleRPG.Domain.Enums.ItemSlot).
enum GearSlot {
  head, chest, legs, feet, hands, ring, amulet,
  mainHand, offHand, twoHand, relic1, relic2,
}

extension GearSlotX on GearSlot {
  String get label => switch (this) {
        GearSlot.head => 'Head',
        GearSlot.chest => 'Chest',
        GearSlot.legs => 'Legs',
        GearSlot.feet => 'Feet',
        GearSlot.hands => 'Hands',
        GearSlot.ring => 'Ring',
        GearSlot.amulet => 'Amulet',
        GearSlot.mainHand => 'Main Hand',
        GearSlot.offHand => 'Off Hand',
        GearSlot.twoHand => 'Two-Hand',
        GearSlot.relic1 => 'Relic I',
        GearSlot.relic2 => 'Relic II',
      };

  ItemShape get defaultShape => switch (this) {
        GearSlot.head => ItemShape.helm,
        GearSlot.chest => ItemShape.chest,
        GearSlot.legs => ItemShape.greaves,
        GearSlot.feet => ItemShape.boots,
        GearSlot.hands => ItemShape.gloves,
        GearSlot.ring => ItemShape.ring,
        GearSlot.amulet => ItemShape.amulet,
        GearSlot.mainHand => ItemShape.sword,
        GearSlot.offHand => ItemShape.shield,
        GearSlot.twoHand => ItemShape.staff,
        GearSlot.relic1 => ItemShape.relic,
        GearSlot.relic2 => ItemShape.relic,
      };
}

/// Visual shape of an item icon.
enum ItemShape {
  helm, chest, greaves, boots, gloves, ring, amulet, sword, shield, bow, staff, relic,
}

/// The heroes that exist in the game.
enum RosterId { knight, mage, ranger, cleric, rogue, berserker, warden, summoner }

class GearItem {
  const GearItem({
    required this.name,
    required this.shape,
    required this.rarity,
    required this.slot,
  });

  final String name;
  final ItemShape shape;
  final Rarity rarity;
  final GearSlot slot;
}

class HeroLoadout {
  const HeroLoadout({
    required this.id,
    required this.name,
    required this.role,
    required this.level,
    required this.gear,
  });

  final RosterId id;
  final String name;
  final String role;
  final int level;
  final Map<GearSlot, GearItem?> gear;
}

class RosterEntry {
  const RosterEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.unlocked,
  });

  final RosterId id;
  final String name;
  final String role;
  final bool unlocked;
}

class InventoryData {
  const InventoryData({
    required this.roster,
    required this.loadouts,
    required this.activeTeam,
    required this.stash,
  });

  final List<RosterEntry> roster;
  final Map<RosterId, HeroLoadout> loadouts;
  final List<RosterId> activeTeam;
  final List<GearItem> stash;
}

class InventoryRepository {
  Future<InventoryData> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return InventoryData(
      roster: _roster,
      loadouts: _loadouts,
      activeTeam: const [RosterId.knight, RosterId.mage, RosterId.ranger],
      stash: _stash,
    );
  }
}

// --- data ------------------------------------------------------------------

GearItem _g(String name, ItemShape shape, Rarity r, GearSlot slot) =>
    GearItem(name: name, shape: shape, rarity: r, slot: slot);

HeroLoadout _loadout(
  RosterId id,
  String name,
  String role,
  int level,
  Map<GearSlot, GearItem?> partial,
) {
  final gear = {for (final s in GearSlot.values) s: partial[s]};
  return HeroLoadout(id: id, name: name, role: role, level: level, gear: gear);
}

final Map<RosterId, HeroLoadout> _loadouts = {
  RosterId.knight: _loadout(RosterId.knight, 'Sir Cinder', 'Tank', 2, {
    GearSlot.mainHand: _g('Emberbrand', ItemShape.sword, Rarity.epic, GearSlot.mainHand),
    GearSlot.offHand: _g('Oak Bulwark', ItemShape.shield, Rarity.rare, GearSlot.offHand),
    GearSlot.head: _g('Iron Visor', ItemShape.helm, Rarity.rare, GearSlot.head),
    GearSlot.chest: _g('Bulwark Plate', ItemShape.chest, Rarity.superior, GearSlot.chest),
    GearSlot.legs: _g('Steel Greaves', ItemShape.greaves, Rarity.uncommon, GearSlot.legs),
    GearSlot.feet: _g('Steel Sabatons', ItemShape.boots, Rarity.common, GearSlot.feet),
    GearSlot.hands: _g('Iron Gauntlets', ItemShape.gloves, Rarity.uncommon, GearSlot.hands),
    GearSlot.ring: _g('Oath Band', ItemShape.ring, Rarity.rare, GearSlot.ring),
    GearSlot.relic1: _g('Ember Core', ItemShape.relic, Rarity.mythic, GearSlot.relic1),
  }),
  RosterId.mage: _loadout(RosterId.mage, 'Lyra Vex', 'Mage', 2, {
    GearSlot.twoHand: _g('Starcaller', ItemShape.staff, Rarity.legendary, GearSlot.twoHand),
    GearSlot.head: _g('Silk Hood', ItemShape.helm, Rarity.uncommon, GearSlot.head),
    GearSlot.chest: _g('Arcane Robe', ItemShape.chest, Rarity.mythic, GearSlot.chest),
    GearSlot.legs: _g('Woven Skirts', ItemShape.greaves, Rarity.common, GearSlot.legs),
    GearSlot.feet: _g('Soft Boots', ItemShape.boots, Rarity.worn, GearSlot.feet),
    GearSlot.hands: _g('Rune Gloves', ItemShape.gloves, Rarity.rare, GearSlot.hands),
    GearSlot.ring: _g('Sage Loop', ItemShape.ring, Rarity.ancient, GearSlot.ring),
    GearSlot.amulet: _g('Mind Sigil', ItemShape.amulet, Rarity.ancient, GearSlot.amulet),
    GearSlot.relic1: _g('Astral Shard', ItemShape.relic, Rarity.epic, GearSlot.relic1),
    GearSlot.relic2: _g('Echo Stone', ItemShape.relic, Rarity.rare, GearSlot.relic2),
  }),
  RosterId.ranger: _loadout(RosterId.ranger, 'Fenn Wilde', 'Ranger', 2, {
    GearSlot.twoHand: _g('Whisperwind', ItemShape.bow, Rarity.relic, GearSlot.twoHand),
    GearSlot.head: _g('Leaf Cowl', ItemShape.helm, Rarity.rare, GearSlot.head),
    GearSlot.chest: _g('Ranger Vest', ItemShape.chest, Rarity.uncommon, GearSlot.chest),
    GearSlot.legs: _g('Trail Leggings', ItemShape.greaves, Rarity.common, GearSlot.legs),
    GearSlot.feet: _g('Soft Striders', ItemShape.boots, Rarity.uncommon, GearSlot.feet),
    GearSlot.hands: _g('Quick Grips', ItemShape.gloves, Rarity.common, GearSlot.hands),
    GearSlot.ring: _g('Hawk Eye', ItemShape.ring, Rarity.epic, GearSlot.ring),
    GearSlot.amulet: _g('Hunter Charm', ItemShape.amulet, Rarity.rare, GearSlot.amulet),
  }),
  RosterId.cleric: _loadout(RosterId.cleric, 'Mother Vale', 'Healer', 2, {
    GearSlot.mainHand: _g('Dawn Scepter', ItemShape.sword, Rarity.rare, GearSlot.mainHand),
    GearSlot.offHand: _g('Faith Ward', ItemShape.shield, Rarity.uncommon, GearSlot.offHand),
    GearSlot.head: _g('Holy Mitre', ItemShape.helm, Rarity.superior, GearSlot.head),
    GearSlot.chest: _g('Blessed Robe', ItemShape.chest, Rarity.rare, GearSlot.chest),
    GearSlot.feet: _g('Pilgrim Boots', ItemShape.boots, Rarity.common, GearSlot.feet),
    GearSlot.hands: _g('Mercy Gloves', ItemShape.gloves, Rarity.uncommon, GearSlot.hands),
    GearSlot.amulet: _g('Halo Pendant', ItemShape.amulet, Rarity.epic, GearSlot.amulet),
    GearSlot.relic1: _g('Light Mote', ItemShape.relic, Rarity.ancient, GearSlot.relic1),
  }),
  RosterId.rogue: _loadout(RosterId.rogue, 'Nyx', 'Assassin', 2, {
    GearSlot.mainHand: _g('Nightfang', ItemShape.sword, Rarity.epic, GearSlot.mainHand),
    GearSlot.offHand: _g('Shadowedge', ItemShape.sword, Rarity.rare, GearSlot.offHand),
    GearSlot.head: _g('Silent Mask', ItemShape.helm, Rarity.uncommon, GearSlot.head),
    GearSlot.chest: _g('Smoke Leathers', ItemShape.chest, Rarity.rare, GearSlot.chest),
    GearSlot.legs: _g('Creep Greaves', ItemShape.greaves, Rarity.uncommon, GearSlot.legs),
    GearSlot.feet: _g('Fleet Boots', ItemShape.boots, Rarity.rare, GearSlot.feet),
    GearSlot.ring: _g('Venom Band', ItemShape.ring, Rarity.superior, GearSlot.ring),
  }),
};

/// One item of EVERY rarity (21), spread across all 12 slots.
final List<GearItem> _stash = [
  for (var i = 0; i < Rarity.values.length; i++)
    () {
      final r = Rarity.values[i];
      final slot = GearSlot.values[i % GearSlot.values.length];
      final shape = slot.defaultShape;
      return _g('${r.label} ${_shapeNoun[shape]!}', shape, r, slot);
    }(),
];

const Map<ItemShape, String> _shapeNoun = {
  ItemShape.helm: 'Helm',
  ItemShape.chest: 'Plate',
  ItemShape.greaves: 'Greaves',
  ItemShape.boots: 'Boots',
  ItemShape.gloves: 'Gauntlets',
  ItemShape.ring: 'Band',
  ItemShape.amulet: 'Pendant',
  ItemShape.sword: 'Blade',
  ItemShape.shield: 'Aegis',
  ItemShape.bow: 'Longbow',
  ItemShape.staff: 'Staff',
  ItemShape.relic: 'Relic',
};

const List<RosterEntry> _roster = [
  RosterEntry(id: RosterId.knight, name: 'Sir Cinder', role: 'Tank', unlocked: true),
  RosterEntry(id: RosterId.mage, name: 'Lyra Vex', role: 'Mage', unlocked: true),
  RosterEntry(id: RosterId.ranger, name: 'Fenn Wilde', role: 'Ranger', unlocked: true),
  RosterEntry(id: RosterId.cleric, name: 'Mother Vale', role: 'Healer', unlocked: true),
  RosterEntry(id: RosterId.rogue, name: 'Nyx', role: 'Assassin', unlocked: true),
  RosterEntry(id: RosterId.berserker, name: 'Grimm', role: 'Berserker', unlocked: false),
  RosterEntry(id: RosterId.warden, name: 'Warden', role: '???', unlocked: false),
  RosterEntry(id: RosterId.summoner, name: 'Summoner', role: '???', unlocked: false),
];
