using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.Loot;

/// <summary>
/// ARPG loot pipeline (F4 rework), Diablo / Path of Exile style:
///
///   1. Drop roll   — enemy drop chance × team DropRate.
///   2. Rarity roll — canonical <see cref="ItemRarityData"/> weights; team
///                    Luck tilts the roll toward Rare and above.
///   3. Archetype   — smart loot: 70% of drops pick an archetype favored by
///                    a class on the active team, 30% roll uniformly.
///   4. Slot roll   — weapons and armor common, jewelry rarer, relics rare.
///   5. Affixes     — count scales with the rarity band (aligned with
///                    ItemRules.PassiveSlots + 1; whites below Uncommon roll
///                    none), max 3 prefixes / 3 suffixes, no repeats.
///   6. Naming      — "{Prefix} {Base} {Suffix}" ("Savage Signet of
///                    Slaughter"); affixless items read as archetype bases
///                    ("Colossus Cuirass").
///
/// Fully deterministic for a given <see cref="Random"/>.
/// </summary>
public static class LootGenerator
{
    public const int MaxPrefixes = 3;
    public const int MaxSuffixes = 3;

    private static readonly (string Slot, double Weight)[] SlotWeights =
    {
        ("MainHand", 0.14), ("Head", 0.12), ("Chest", 0.12),
        ("Legs", 0.10), ("Feet", 0.10), ("Hands", 0.10), ("OffHand", 0.10),
        ("Ring", 0.08), ("Amulet", 0.06), ("TwoHand", 0.06), ("Relic1", 0.02),
    };

    private static readonly IReadOnlyDictionary<string, string> SlotBaseNames =
        new Dictionary<string, string>
        {
            ["Head"] = "Casque",
            ["Chest"] = "Cuirass",
            ["Legs"] = "Greaves",
            ["Feet"] = "Striders",
            ["Hands"] = "Grips",
            ["MainHand"] = "Blade",
            ["OffHand"] = "Aegis",
            ["TwoHand"] = "Maul",
            ["Ring"] = "Signet",
            ["Amulet"] = "Talisman",
            ["Relic1"] = "Idol",
            ["Relic2"] = "Idol",
        };

    /// <summary>Rolls the whole pipeline for one slain enemy; null = no drop.</summary>
    public static LootDrop? TryGenerate(
        Random rng, EnemySpec enemy, IReadOnlyList<HeroSpec> team)
    {
        var dropRate = team.Count == 0
            ? 1f
            : team.Average(h => MathF.Max(h.Stats.DropRate, 0f));

        if (rng.NextDouble() >= enemy.DropChance * dropRate)
        {
            return null;
        }

        var luck = team.Count == 0
            ? 1.0
            : Math.Max(team.Average(h => (double)h.Stats.Luck), 0.1);

        var rarity = RollRarity(rng, luck);
        var archetype = RollArchetype(rng, team);
        var slot = RollSlot(rng);

        return Generate(rng, rarity, archetype, slot, enemy.Level);
    }

    /// <summary>Generates a drop with everything but the RNG already decided.</summary>
    public static LootDrop Generate(
        Random rng, ItemRarity rarity, ItemArchetype archetype, string slot, int itemLevel)
    {
        var info = ArchetypeCatalog.For(archetype);
        var count = AffixCountFor(rarity);

        var prefixPool = info.Prefixes.ToList();
        var suffixPool = info.Suffixes.ToList();
        var picked = new List<AffixDefinition>();

        // Alternate prefix/suffix picks (random start) without replacement,
        // honoring the 3/3 caps like PoE.
        var pickPrefix = rng.Next(2) == 0;
        while (picked.Count < count)
        {
            var prefixes = picked.Count(a => a.IsPrefix);
            var suffixes = picked.Count - prefixes;

            var canPrefix = prefixPool.Count > 0 && prefixes < MaxPrefixes;
            var canSuffix = suffixPool.Count > 0 && suffixes < MaxSuffixes;
            if (!canPrefix && !canSuffix)
            {
                break;
            }

            var takePrefix = canPrefix && (pickPrefix || !canSuffix);
            var pool = takePrefix ? prefixPool : suffixPool;
            var affix = pool[rng.Next(pool.Count)];
            pool.Remove(affix);
            picked.Add(affix);
            pickPrefix = !takePrefix;
        }

        var modifiers = picked
            .Select(a => new StatModifier(a.Stat, RollValue(rng, a, itemLevel), a.Type))
            .ToList();

        return new LootDrop
        {
            Name = ComposeName(info, slot, picked),
            Rarity = rarity,
            Archetype = archetype,
            Slot = slot,
            ItemLevel = itemLevel,
            AffixNames = picked.Select(a => a.Name).ToList(),
            AffixDescriptions = picked.Select(a => a.Description).ToList(),
            Modifiers = modifiers,
        };
    }

    /// <summary>
    /// Affix count per rarity band: whites (below Uncommon) have none, then
    /// the band's passive-slot budget plus one, capped by the 3/3 rule.
    /// </summary>
    public static int AffixCountFor(ItemRarity rarity) =>
        rarity < ItemRarity.Uncommon
            ? 0
            : Math.Min(ItemRules.PassiveSlots(rarity) + 1, MaxPrefixes + MaxSuffixes);

    /// <summary>Weighted rarity roll over tradeable rolled-stat tiers.</summary>
    public static ItemRarity RollRarity(Random rng, double luck)
    {
        var tiers = Enum.GetValues<ItemRarity>()
            .Where(r => !ItemRarityData.HasFixedStats(r) && ItemRarityData.DropPercent(r) > 0)
            .ToArray();

        double Weight(ItemRarity r) =>
            ItemRarityData.DropPercent(r) * (r >= ItemRarity.Rare ? luck : 1.0);

        var total = tiers.Sum(Weight);
        var roll = rng.NextDouble() * total;
        foreach (var tier in tiers)
        {
            roll -= Weight(tier);
            if (roll <= 0)
            {
                return tier;
            }
        }

        return tiers[^1];
    }

    /// <summary>Smart loot: 70% team-favored archetypes, 30% anything.</summary>
    public static ItemArchetype RollArchetype(Random rng, IReadOnlyList<HeroSpec> team)
    {
        var all = ArchetypeCatalog.All.ToArray();

        var favored = team
            .SelectMany(h => ArchetypeCatalog.FavoredBy(h.Class))
            .Distinct()
            .ToArray();

        if (favored.Length > 0 && rng.NextDouble() < 0.70)
        {
            return favored[rng.Next(favored.Length)];
        }

        return all[rng.Next(all.Length)];
    }

    private static string RollSlot(Random rng)
    {
        var roll = rng.NextDouble();
        foreach (var (slot, weight) in SlotWeights)
        {
            roll -= weight;
            if (roll <= 0)
            {
                return slot;
            }
        }

        return SlotWeights[^1].Slot;
    }

    private static float RollValue(Random rng, AffixDefinition affix, int itemLevel)
    {
        var raw = affix.Base + affix.PerLevel * Math.Max(itemLevel, 1);
        var roll = 0.85 + rng.NextDouble() * 0.30; // uniform [0.85, 1.15]
        return (float)(raw * roll);
    }

    private static string ComposeName(
        ArchetypeInfo info, string slot, IReadOnlyList<AffixDefinition> picked)
    {
        var baseName = SlotBaseNames.GetValueOrDefault(slot, "Trinket");
        var prefix = picked.FirstOrDefault(a => a.IsPrefix)?.Name;
        var suffix = picked.FirstOrDefault(a => !a.IsPrefix)?.Name;

        var head = prefix ?? info.FlavorWord;
        return suffix is null ? $"{head} {baseName}" : $"{head} {baseName} {suffix}";
    }
}
