import 'dart:math';

import '../inventory/inventory_model.dart';

/// ---------------------------------------------------------------------------
/// Item Power schema (v2).
///
///  - Characters have an ARCHETYPE (knight=defense, mage=magic,
///    assassin=crit DAMAGE, ...) giving base stats per level.
///  - ARMOR is always-on base power (never in the reel).
///  - WEAPONS + ACCESSORIES populate a 1x3 reel; combos multiply the result
///    (x1 / x2 / x3 / x10). Accessory/relic `luck` biases the reel.
///  - SPEED drives an HSR-style action-value turn order.
///
/// See docs/item-power-architecture.md.
/// ---------------------------------------------------------------------------

enum StatType {
  // flat / primary
  physAtk, magAtk, defense, maxHp, speed, luck,
  // percent / modifier (fractions)
  critRate, critDmg, physPen, magPen, physRes, magRes, lifesteal, guard,
  dmgPctPhys, dmgPctMag, speedPct, extraHit, actionAdvance, execute,
  effectHit, effectRes, heal, reflect,
}

const Set<StatType> _percentStats = {
  StatType.critRate, StatType.critDmg, StatType.physPen, StatType.magPen,
  StatType.physRes, StatType.magRes, StatType.lifesteal, StatType.guard,
  StatType.dmgPctPhys, StatType.dmgPctMag, StatType.speedPct, StatType.extraHit,
  StatType.actionAdvance, StatType.execute, StatType.effectHit,
  StatType.effectRes, StatType.heal, StatType.reflect,
};

extension StatTypeX on StatType {
  bool get isPercent => _percentStats.contains(this);

  String get label => switch (this) {
        StatType.physAtk => 'Physical Attack',
        StatType.magAtk => 'Magic Attack',
        StatType.defense => 'Defense',
        StatType.maxHp => 'Max HP',
        StatType.speed => 'Speed',
        StatType.luck => 'Luck',
        StatType.critRate => 'Crit Rate',
        StatType.critDmg => 'Crit Damage',
        StatType.physPen => 'Physical Pen',
        StatType.magPen => 'Magic Pen',
        StatType.physRes => 'Physical Resist',
        StatType.magRes => 'Magic Resist',
        StatType.lifesteal => 'Lifesteal',
        StatType.guard => 'Guard',
        StatType.dmgPctPhys => 'Physical Dmg',
        StatType.dmgPctMag => 'Magic Dmg',
        StatType.speedPct => 'Speed',
        StatType.extraHit => 'Extra Hit',
        StatType.actionAdvance => 'Action Advance',
        StatType.execute => 'Execute',
        StatType.effectHit => 'Effect Hit',
        StatType.effectRes => 'Effect Resist',
        StatType.heal => 'Healing',
        StatType.reflect => 'Reflect',
      };

  String describe(double v) => isPercent
      ? '+${(v * 100).toStringAsFixed(1)}% $label'
      : '+${v.round()} $label';
}

// --- character archetypes --------------------------------------------------

enum CharacterArchetype { defense, magic, physical, support, critDamage, fury }

extension CharacterArchetypeX on CharacterArchetype {
  StatType get focus => switch (this) {
        CharacterArchetype.defense => StatType.defense,
        CharacterArchetype.magic => StatType.magAtk,
        CharacterArchetype.physical => StatType.physAtk,
        CharacterArchetype.support => StatType.heal,
        CharacterArchetype.critDamage => StatType.critDmg,
        CharacterArchetype.fury => StatType.physAtk,
      };
}

/// Base stat profile at level 1, per archetype.
const Map<CharacterArchetype, Map<StatType, double>> kArchetypeBase = {
  CharacterArchetype.defense: {
    StatType.physAtk: 4, StatType.defense: 10, StatType.maxHp: 60,
    StatType.speed: 95, StatType.guard: 0.05,
  },
  CharacterArchetype.magic: {
    StatType.magAtk: 9, StatType.defense: 4, StatType.maxHp: 40,
    StatType.speed: 100, StatType.magPen: 0.05,
  },
  CharacterArchetype.physical: {
    StatType.physAtk: 9, StatType.defense: 5, StatType.maxHp: 45,
    StatType.speed: 110, StatType.critRate: 0.05,
  },
  CharacterArchetype.support: {
    StatType.magAtk: 5, StatType.defense: 5, StatType.maxHp: 50,
    StatType.speed: 100, StatType.heal: 0.10, StatType.effectRes: 0.05,
  },
  CharacterArchetype.critDamage: {
    StatType.physAtk: 7, StatType.defense: 4, StatType.maxHp: 42,
    StatType.speed: 105, StatType.critDmg: 0.30, StatType.critRate: 0.05,
  },
  CharacterArchetype.fury: {
    StatType.physAtk: 10, StatType.defense: 4, StatType.maxHp: 48,
    StatType.speed: 108, StatType.lifesteal: 0.05,
  },
};

CharacterArchetype archetypeForRoster(RosterId id) => switch (id) {
      RosterId.knight => CharacterArchetype.defense,
      RosterId.mage => CharacterArchetype.magic,
      RosterId.ranger => CharacterArchetype.physical,
      RosterId.cleric => CharacterArchetype.support,
      RosterId.rogue => CharacterArchetype.critDamage,
      RosterId.berserker => CharacterArchetype.fury,
      RosterId.warden => CharacterArchetype.defense,
      RosterId.summoner => CharacterArchetype.magic,
    };

Map<StatType, double> archetypeBaseStats(CharacterArchetype a, int level) {
  final scale = 1 + 0.08 * (level - 1);
  return {for (final e in kArchetypeBase[a]!.entries) e.key: e.value * scale};
}

// --- item roles & scaling --------------------------------------------------

/// Armor is always-on base power; weapons + accessories feed the reel.
enum ItemRole { basePower, reel }

ItemRole roleForShape(ItemShape s) => switch (s) {
      ItemShape.helm ||
      ItemShape.chest ||
      ItemShape.greaves ||
      ItemShape.boots ||
      ItemShape.gloves =>
        ItemRole.basePower,
      _ => ItemRole.reel,
    };

const Map<StatType, double> kPerkBase = {
  StatType.physAtk: 2.5, StatType.magAtk: 2.5, StatType.defense: 2.5,
  StatType.maxHp: 12, StatType.speed: 3, StatType.luck: 3,
  StatType.critRate: 0.012, StatType.critDmg: 0.05, StatType.physPen: 0.015,
  StatType.magPen: 0.015, StatType.physRes: 0.012, StatType.magRes: 0.012,
  StatType.lifesteal: 0.01, StatType.guard: 0.02, StatType.dmgPctPhys: 0.02,
  StatType.dmgPctMag: 0.02, StatType.speedPct: 0.02, StatType.extraHit: 0.015,
  StatType.actionAdvance: 0.02, StatType.execute: 0.03, StatType.effectHit: 0.02,
  StatType.effectRes: 0.02, StatType.heal: 0.02, StatType.reflect: 0.02,
};

/// Exponential rarity power curve, indexed by Rarity.index (21 tiers).
const List<double> kRarityPower = [
  0.30, 0.50, 0.70, 0.90, 1.10, 1.30, 1.60, 2.00, 2.50, 3.00, 4.00,
  5.50, 7.00, 9.00, 12.0, 16.0, 22.0, 30.0, 42.0, 60.0, 100.0,
];

double rarityPower(Rarity r) => kRarityPower[r.index];

double levelScale(int level) => 1 + 0.10 * (level - 1);

class ArchetypeSpec {
  const ArchetypeSpec({required this.baseStats, required this.track});
  final Map<StatType, double> baseStats;
  final List<StatType> track;
}

const Map<ItemShape, ArchetypeSpec> kItemSpecs = {
  // reel: weapons
  ItemShape.sword: ArchetypeSpec(baseStats: {StatType.physAtk: 6.5}, track: [
    StatType.critRate, StatType.physPen, StatType.critDmg,
    StatType.dmgPctPhys, StatType.lifesteal, StatType.extraHit, StatType.execute,
  ]),
  ItemShape.bow: ArchetypeSpec(
      baseStats: {StatType.physAtk: 5.0, StatType.critRate: 0.03},
      track: [
        StatType.critRate, StatType.critDmg, StatType.physPen,
        StatType.extraHit, StatType.dmgPctPhys,
      ]),
  ItemShape.staff: ArchetypeSpec(baseStats: {StatType.magAtk: 6.5}, track: [
    StatType.magPen, StatType.dmgPctMag, StatType.critRate,
    StatType.critDmg, StatType.magPen,
  ]),
  ItemShape.shield: ArchetypeSpec(
      baseStats: {StatType.defense: 5, StatType.guard: 0.04},
      track: [
        StatType.guard, StatType.reflect, StatType.defense,
        StatType.magRes, StatType.physRes,
      ]),
  // reel: accessories (carry luck)
  ItemShape.amulet: ArchetypeSpec(
      baseStats: {StatType.magAtk: 3, StatType.maxHp: 10, StatType.luck: 4},
      track: [StatType.luck, StatType.magPen, StatType.heal, StatType.effectHit]),
  ItemShape.ring: ArchetypeSpec(
      baseStats: {StatType.critRate: 0.04, StatType.critDmg: 0.08, StatType.luck: 3},
      track: [StatType.luck, StatType.critDmg, StatType.critRate, StatType.dmgPctPhys]),
  ItemShape.relic: ArchetypeSpec(
      baseStats: {
        StatType.physAtk: 3, StatType.magAtk: 3, StatType.speed: 3, StatType.luck: 6,
      },
      track: [
        StatType.luck, StatType.dmgPctPhys, StatType.dmgPctMag,
        StatType.speedPct, StatType.critDmg, StatType.actionAdvance,
      ]),
  // base power: armor (never in the reel)
  ItemShape.helm: ArchetypeSpec(
      baseStats: {StatType.defense: 4, StatType.maxHp: 12},
      track: [StatType.effectRes, StatType.maxHp, StatType.physRes, StatType.magRes]),
  ItemShape.chest: ArchetypeSpec(
      baseStats: {StatType.defense: 6, StatType.maxHp: 22},
      track: [StatType.maxHp, StatType.guard, StatType.defense, StatType.heal]),
  ItemShape.greaves: ArchetypeSpec(
      baseStats: {StatType.defense: 5, StatType.maxHp: 16},
      track: [StatType.defense, StatType.physRes, StatType.maxHp, StatType.magRes]),
  ItemShape.boots: ArchetypeSpec(
      baseStats: {StatType.defense: 3, StatType.speed: 6},
      track: [StatType.speedPct, StatType.speed, StatType.actionAdvance, StatType.extraHit]),
  ItemShape.gloves: ArchetypeSpec(
      baseStats: {StatType.physAtk: 2, StatType.defense: 2},
      track: [StatType.critRate, StatType.dmgPctPhys, StatType.physAtk, StatType.extraHit]),
};

class PassiveLine {
  const PassiveLine({required this.tier, required this.stat, required this.value});
  final int tier;
  final StatType stat;
  final double value;
  String get text => stat.describe(value);
}

class ResolvedPower {
  const ResolvedPower({required this.stats, required this.passives});
  final Map<StatType, double> stats;
  final List<PassiveLine> passives;
}

/// Resolve one item: base stat (scaled) + one cumulative perk per rarity tier.
ResolvedPower resolvePower(ItemShape shape, Rarity rarity, int level) {
  final spec = kItemSpecs[shape]!;
  final p = rarityPower(rarity);
  final lvl = levelScale(level);
  final stats = <StatType, double>{};

  spec.baseStats.forEach((stat, base) {
    stats[stat] = (stats[stat] ?? 0) + base * p * lvl;
  });

  final passives = <PassiveLine>[];
  for (var t = 2; t <= rarity.tier; t++) {
    final stat = spec.track[(t - 2) % spec.track.length];
    final value = (kPerkBase[stat] ?? 0) * kRarityPower[t - 1];
    stats[stat] = (stats[stat] ?? 0) + value;
    passives.add(PassiveLine(tier: t, stat: stat, value: value));
  }

  return ResolvedPower(stats: stats, passives: passives);
}

Map<StatType, double> aggregate(Iterable<Map<StatType, double>> sources) {
  final total = <StatType, double>{};
  for (final s in sources) {
    s.forEach((k, v) => total[k] = (total[k] ?? 0) + v);
  }
  return applyCaps(total);
}

Map<StatType, double> applyCaps(Map<StatType, double> s) {
  void cap(StatType t, double maxV) {
    if (s[t] != null) s[t] = min(s[t]!, maxV);
  }

  cap(StatType.critRate, 0.75);
  cap(StatType.critDmg, 3.5); // base mult 1.5 + 3.5 = 5.0
  cap(StatType.physRes, 0.90);
  cap(StatType.magRes, 0.90);
  cap(StatType.guard, 0.90);
  cap(StatType.lifesteal, 1.0);
  return s;
}

// --- the 1x3 slot reel -----------------------------------------------------

/// The (up to) 7 reel positions a character can equip.
enum SlotItemKind {
  mainWeapon, secondaryWeapon, amulet, earring1, earring2, ring1, ring2,
}

enum SlotCategory { weapon, amulet, earring, ring }

SlotCategory categoryOf(SlotItemKind k) => switch (k) {
      SlotItemKind.mainWeapon || SlotItemKind.secondaryWeapon => SlotCategory.weapon,
      SlotItemKind.amulet => SlotCategory.amulet,
      SlotItemKind.earring1 || SlotItemKind.earring2 => SlotCategory.earring,
      SlotItemKind.ring1 || SlotItemKind.ring2 => SlotCategory.ring,
    };

enum ReelCombo { oneEach, pair, category, triple }

extension ReelComboX on ReelCombo {
  double get multiplier => switch (this) {
        ReelCombo.oneEach => 1,
        ReelCombo.pair => 2,
        ReelCombo.category => 3,
        ReelCombo.triple => 10,
      };

  String get label => switch (this) {
        ReelCombo.oneEach => 'MIXED',
        ReelCombo.pair => 'PAIR x2',
        ReelCombo.category => 'SYNERGY x3',
        ReelCombo.triple => 'JACKPOT x10',
      };
}

class ReelOutcome {
  const ReelOutcome({required this.draw, required this.combo});
  final List<SlotItemKind> draw;
  final ReelCombo combo;
  double get multiplier => combo.multiplier;
}

/// Classify a 3-item draw into its best combo (triple > category > pair > mixed).
ReelOutcome evaluateReel(List<SlotItemKind> draw) {
  final kindCounts = <SlotItemKind, int>{};
  for (final k in draw) {
    kindCounts[k] = (kindCounts[k] ?? 0) + 1;
  }
  final maxKind = kindCounts.values.fold(0, max);

  if (maxKind >= 3) return ReelOutcome(draw: draw, combo: ReelCombo.triple);

  final catKinds = <SlotCategory, Set<SlotItemKind>>{};
  for (final k in draw) {
    catKinds.putIfAbsent(categoryOf(k), () => {}).add(k);
  }
  final hasCategory = catKinds.values.any((set) => set.length >= 2);
  if (hasCategory) return ReelOutcome(draw: draw, combo: ReelCombo.category);

  if (maxKind >= 2) return ReelOutcome(draw: draw, combo: ReelCombo.pair);
  return ReelOutcome(draw: draw, combo: ReelCombo.oneEach);
}

double copyChance(double luck) => (0.06 + luck * 0.0010).clamp(0.0, 0.40);
double catChance(double luck) => (0.10 + luck * 0.0015).clamp(0.0, 0.55);

/// Spin the 1x3 reel. Luck biases positions 2-3 toward matches / synergies.
ReelOutcome rollReel(List<SlotItemKind> equipped, double luck, Random rng) {
  if (equipped.isEmpty) {
    return const ReelOutcome(draw: [], combo: ReelCombo.oneEach);
  }
  final copy = copyChance(luck);
  final cat = catChance(luck);
  final draw = <SlotItemKind>[equipped[rng.nextInt(equipped.length)]];

  for (var i = 1; i < 3; i++) {
    final r = rng.nextDouble();
    SlotItemKind pick;
    if (r < copy) {
      pick = draw[rng.nextInt(draw.length)]; // extend an identical
    } else if (r < copy + cat) {
      final shownCats = draw.map(categoryOf).toSet();
      final candidates = equipped
          .where((k) => shownCats.contains(categoryOf(k)) && !draw.contains(k))
          .toList();
      pick = candidates.isEmpty
          ? equipped[rng.nextInt(equipped.length)]
          : candidates[rng.nextInt(candidates.length)];
    } else {
      pick = equipped[rng.nextInt(equipped.length)];
    }
    draw.add(pick);
  }
  return evaluateReel(draw);
}

// --- HSR-style speed / action value ----------------------------------------

const double kBaseActionValue = 10000;

double actionCost(double speed) => kBaseActionValue / max(1.0, speed);

int turnsBefore(double selfSpeed, double otherSpeed) =>
    (selfSpeed / max(1.0, otherSpeed)).floor();
