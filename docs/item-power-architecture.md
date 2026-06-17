# Item Power Architecture — IDLE RPG

How characters and items grant power, how rarity stacks passives, how the
**1×3 slot reel** turns equipped weapons/accessories into combo multipliers, and
how speed drives an HSR-style turn order.

Reference implementation (code schema): `apps/mobile/lib/core/game/item_power.dart`.

---

## 1. Two sources of power

| Source | What it does | Enters the reel? |
|---|---|---|
| **Character archetype** | Innate orientation + base stats per level (knight = defense, mage = magic, assassin = crit *damage*, …) | — |
| **Armor** (helm, chest, legs, feet, gloves) | **Always-on** boost to the character's base stats (defense, HP, speed…) | ❌ No |
| **Slot items** (main weapon, secondary weapon, amulet, earring 1/2, ring 1/2) | Populate the 1×3 reel; their stats are what the reel *multiplies* each turn | ✅ Yes |

Armor is **base power**, applied permanently. Weapons + accessories are **reel
power**, gated and amplified by the slot roll.

---

## 2. Character archetypes

Each hero has an archetype that sets a base stat profile (× level) and a **focus
stat** the class amplifies.

| Archetype | Hero | Focus | Base profile (lean) |
|---|---|---|---|
| `defense` | Knight | Defense | high `defense`, `maxHp`, `guard` |
| `magic` | Mage | Magic Attack | high `magAtk`, `magPen` |
| `physical` | Ranger | Physical Attack | high `physAtk`, some `critRate` |
| `support` | Cleric | Healing | `heal`, `effectRes`, `maxHp` |
| `critDamage` | Rogue (Assassin) | **Crit Damage** (not crit rate) | moderate `physAtk`, high `critDmg` |
| `fury` | Berserker | Attack + Lifesteal | high `physAtk`, `lifesteal`, `speed` |

> The assassin scales **crit damage**, so its power spikes on the turns it *does*
> crit, rather than critting more often.

Base stat per level: `stat = base[stat] × (1 + 0.08 × (level − 1))`. Armor and
the focus amplification stack on top.

---

## 3. Stat model

All power resolves into one `Map<StatType, double>`.

**Flat:** `physAtk`, `magAtk`, `defense`, `maxHp`, `speed`, `luck`.
**Percent (fractions):** `critRate`, `critDmg`, `physPen`/`magPen`,
`physRes`/`magRes`, `lifesteal`, `guard`, `dmgPctPhys`/`dmgPctMag`, `speedPct`,
`extraHit`, `actionAdvance`, `execute`, `effectHit`/`effectRes`, `heal`,
`reflect`.

`luck` is the new one: it biases the slot reel toward better combos (§6).
Caps (crit ≤ 0.75, crit-dmg total ≤ ×5, resist ≤ 0.90) apply once after
aggregating the whole loadout.

---

## 4. Item power computation (unchanged core)

```
power(item) = baseStats × P(rarity) × L(level)          // base stat
            + Σ perk(tier_k)  for tier_k = 2 .. rarity   // one cumulative passive per tier
```

`P(rarity)` is exponential — Broken `0.30` → Common `0.70` → Rare `1.10` →
Legendary `4.0` → Transcendent `16` → 1-of-1 `100`. `L(level) = 1 + 0.10×(level−1)`.

**Sword example:** base `physAtk 6.5`. Broken Lv1 = `6.5 × 0.30 = 1.95 ≈ 2`. ✅
Common adds the first track perk `critRate` (`1.2% × 0.70 ≈ +0.84%`). ✅

### Perk tracks
Each archetype-shape has a cycling perk track; tier 1 = base only, tiers 2..R each
add the next perk at magnitude `perkBase(stat) × P(tier)`.

**Reel items**
| Shape | Slot role | Base stat | Perk track |
|---|---|---|---|
| Sword | main weapon | `physAtk 6.5` | crit → physPen → critDmg → %dmg → lifesteal → extraHit → execute |
| Bow | main weapon | `physAtk 5`, `critRate 3%` | crit → critDmg → physPen → extraHit → %dmg |
| Staff | main weapon | `magAtk 6.5` | magPen → %magDmg → crit → critDmg → magPen |
| Shield | secondary weapon | `defense 5`, `guard 4%` | guard → reflect → defense → resists |
| Amulet | amulet (colgante) | `magAtk 3`, **`luck 4`** | luck → magPen → heal → effectHit |
| Ring | ring 1/2 (anillo) | `critRate 4%`, `critDmg 8%`, **`luck 3`** | luck → critDmg → critRate → %dmg |
| Earring | earring 1/2 (pendiente) | `magAtk 2`, **`luck 4`** | luck → effectHit → magPen → %magDmg |
| Relic | accessory | mixed, **`luck 6`** | luck → %dmg → speedPct → critDmg → actionAdvance |

**Base-power items (armor — always on, never in the reel)**
| Shape | Slot | Base stat | Perk track |
|---|---|---|---|
| Helm | head | `defense 4`, `maxHp 12` | effectRes → maxHp → resists |
| Chest | chest | `defense 6`, `maxHp 22` | maxHp → guard → defense → heal |
| Greaves | legs | `defense 5`, `maxHp 16` | defense → physRes → maxHp |
| Boots | feet | `defense 3`, `speed 6` | speedPct → speed → actionAdvance |
| Gloves | hands | `physAtk 2`, `defense 2` | crit → %physDmg → physAtk |

Note **accessories/relics carry `luck`** in their base stat and at the front of
their perk tracks — that is the "relic passives boost slot luck" rule.

---

## 5. The 1×3 slot reel

The combat reel is **one row of three**. Each spin, each of the 3 positions draws
one of the character's equipped **slot items** (up to 7: main weapon, secondary
weapon, amulet, earring 1, earring 2, ring 1, ring 2). Items have a **category**:

`weapon` = {main, secondary} · `amulet` = {colgante} · `earring` = {earring 1, 2}
· `ring` = {ring 1, 2}.

### Combo multipliers (the "prizes")

Evaluated highest-first:

| Combo | Example | Multiplier |
|---|---|---|
| **3 identical** | ring1 · ring1 · ring1 | **×10** |
| **2 of the same category** (different items) | main weapon · secondary weapon | **×3** |
| **2 identical** | amulet · amulet · ring1 | **×2** |
| **1 of each** (no pair) | main · ring1 · earring1 | **×1** |

The turn's output = (sum of the stats of the items shown in the reel) × this
multiplier, fed into the active channel and the character's base power. So two
weapons landing together (`×3`) is the "arma 1 + arma 2 de ayuda" synergy, and a
triple is the `×10` jackpot.

---

## 6. Luck → reel probabilities

`luck` (from amulets, earrings, rings, relics) makes good combos more frequent.
The reel is generated position-by-position:

```
pos 1: uniform over equipped slot items
pos 2..3:
   with copyChance(luck)  -> copy an already-shown item   (drives identical pairs/triples)
   else with catChance(luck) -> pick a *different* item of a shown category (drives ×3 synergy)
   else -> uniform
```

```
copyChance(luck) = clamp(0.06 + luck × 0.0010, 0, 0.40)
catChance(luck)  = clamp(0.10 + luck × 0.0015, 0, 0.55)
```

At `luck 0` good combos are rare; stacking luck on accessories visibly raises the
rate of ×2/×3/×10 spins. (Values are tunable placeholders.)

---

## 7. Turn order & speed (HSR-style)

Action-value timeline, not round-robin:

```
cost(speed) = 10000 / speed     // lower acts sooner; base speed ≈ 100
```

A hero at `speed 200` acts twice before a `speed 100` enemy. `speedPct` multiplies
speed; `actionAdvance` refunds a % of the gauge for burst extra turns. Boots and
relics are the main speed sources, making them build-defining.

---

## 8. Aggregation & integration plan

1. **Character base** = `archetypeBase(archetype, level)` + Σ `resolvePower(armor)`.
2. **Reel power** = the slot items' resolved stats, gated/multiplied by the spin.
3. **Per turn:** roll the 1×3 reel (luck-weighted) → multiplier × shown-item stats,
   combined with the character base and the active channel, then `applyCaps`.
4. **Speed** feeds the action-value scheduler.
5. **UI:** combat shows a 1×3 reel of the equipped item icons; the inventory item
   detail lists the resolved passives so rarity reads from real perks.

This sits beneath the existing combat/inventory as the shared power model; the
visual layer changes only where noted (3×3 → 1×3 reel).
