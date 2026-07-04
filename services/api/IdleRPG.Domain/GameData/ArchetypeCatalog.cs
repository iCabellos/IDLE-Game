using IdleRPG.Domain.Enums;
using IdleRPG.Domain.Loot;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.GameData;

/// <summary>Static identity of an <see cref="ItemArchetype"/>.</summary>
public sealed record ArchetypeInfo
{
    public required string DisplayName { get; init; }

    /// <summary>Word woven into base item names ("Colossus Cuirass").</summary>
    public required string FlavorWord { get; init; }

    /// <summary>Classes whose builds this archetype serves — drives smart loot.</summary>
    public required IReadOnlyList<CharacterClass> FavoredClasses { get; init; }

    public required IReadOnlyList<AffixDefinition> Prefixes { get; init; }
    public required IReadOnlyList<AffixDefinition> Suffixes { get; init; }
}

/// <summary>
/// Canonical archetype table (F4 loot rework). Every affix pool is
/// deliberately coherent: an archetype only rolls stats that serve its
/// theme, so drops read like a build identity instead of stat soup.
/// </summary>
public static class ArchetypeCatalog
{
    private static AffixDefinition Prefix(
        string name, string stat, ModifierType type, float @base, float perLevel, string desc) =>
        new()
        {
            Name = name, IsPrefix = true, Stat = stat, Type = type,
            Base = @base, PerLevel = perLevel, Description = desc,
        };

    private static AffixDefinition Suffix(
        string name, string stat, ModifierType type, float @base, float perLevel, string desc) =>
        new()
        {
            Name = name, IsPrefix = false, Stat = stat, Type = type,
            Base = @base, PerLevel = perLevel, Description = desc,
        };

    private static readonly IReadOnlyDictionary<ItemArchetype, ArchetypeInfo> Table =
        new Dictionary<ItemArchetype, ArchetypeInfo>
        {
            [ItemArchetype.Juggernaut] = new()
            {
                DisplayName = "Juggernaut",
                FlavorWord = "Colossus",
                FavoredClasses = new[] { CharacterClass.Warrior, CharacterClass.Paladin },
                Prefixes = new[]
                {
                    Prefix("Stalwart", nameof(CharacterStats.Defense), ModifierType.Flat, 4f, 1.2f, "More defense"),
                    Prefix("Colossal", nameof(CharacterStats.MaxHp), ModifierType.Flat, 25f, 7f, "More life"),
                    Prefix("Unyielding", nameof(CharacterStats.Defense), ModifierType.Flat, 8f, 0.8f, "More defense"),
                    Prefix("Bulwark", nameof(CharacterStats.MaxHp), ModifierType.Flat, 60f, 4f, "More life"),
                },
                Suffixes = new[]
                {
                    Suffix("of the Colossus", nameof(CharacterStats.Defense), ModifierType.Percent, 0.12f, 0f, "Much more defense"),
                    Suffix("of the Mountain", nameof(CharacterStats.MaxHp), ModifierType.Percent, 0.10f, 0f, "Much more life"),
                    Suffix("of Stone", nameof(CharacterStats.ResistPhysical), ModifierType.Flat, 0.05f, 0f, "Shrugs off physical blows"),
                    Suffix("of Ember Warding", nameof(CharacterStats.ResistFire), ModifierType.Flat, 0.06f, 0f, "Shrugs off fire"),
                    Suffix("of the Glacier", nameof(CharacterStats.ResistIce), ModifierType.Flat, 0.06f, 0f, "Shrugs off ice"),
                },
            },
            [ItemArchetype.Executioner] = new()
            {
                DisplayName = "Executioner",
                FlavorWord = "Headsman",
                FavoredClasses = new[]
                {
                    CharacterClass.Berserker, CharacterClass.Rogue, CharacterClass.Ranger,
                },
                Prefixes = new[]
                {
                    Prefix("Savage", nameof(CharacterStats.Attack), ModifierType.Flat, 3f, 1.0f, "More attack"),
                    Prefix("Honed", nameof(CharacterStats.CritRate), ModifierType.Flat, 0.04f, 0f, "Better for criticals"),
                    Prefix("Brutal", nameof(CharacterStats.CritMultiplier), ModifierType.Flat, 0.20f, 0f, "Crueler criticals"),
                    Prefix("Piercing", nameof(CharacterStats.PenPhysical), ModifierType.Flat, 0.05f, 0f, "Cuts through armor"),
                },
                Suffixes = new[]
                {
                    Suffix("of Slaughter", nameof(CharacterStats.Attack), ModifierType.Percent, 0.12f, 0f, "Much more attack"),
                    Suffix("of Precision", nameof(CharacterStats.CritRate), ModifierType.Flat, 0.05f, 0f, "Better for criticals"),
                    Suffix("of Sundering", nameof(CharacterStats.PenPhysical), ModifierType.Flat, 0.06f, 0f, "Cuts through armor"),
                    Suffix("of the Headsman", nameof(CharacterStats.CritMultiplier), ModifierType.Flat, 0.30f, 0f, "Crueler criticals"),
                },
            },
            [ItemArchetype.Stormcaller] = new()
            {
                DisplayName = "Stormcaller",
                FlavorWord = "Storm",
                FavoredClasses = new[] { CharacterClass.Mage, CharacterClass.Elementalist },
                Prefixes = new[]
                {
                    Prefix("Charged", nameof(CharacterStats.MagicPower), ModifierType.Flat, 3f, 1.0f, "More spellpower"),
                    Prefix("Arcing", nameof(CharacterStats.PenMagic), ModifierType.Flat, 0.05f, 0f, "Pierces wards"),
                    Prefix("Glacial", nameof(CharacterStats.MagicPower), ModifierType.Flat, 6f, 0.7f, "More spellpower"),
                    Prefix("Thunderous", nameof(CharacterStats.CritRate), ModifierType.Flat, 0.03f, 0f, "Better for criticals"),
                },
                Suffixes = new[]
                {
                    Suffix("of the Tempest", nameof(CharacterStats.MagicPower), ModifierType.Percent, 0.12f, 0f, "Much more spellpower"),
                    Suffix("of Storms", nameof(CharacterStats.PenMagic), ModifierType.Flat, 0.06f, 0f, "Pierces wards"),
                    Suffix("of Lightning", nameof(CharacterStats.ResistLightning), ModifierType.Flat, 0.06f, 0f, "Shrugs off lightning"),
                    Suffix("of Deep Winter", nameof(CharacterStats.ResistIce), ModifierType.Flat, 0.06f, 0f, "Shrugs off ice"),
                },
            },
            [ItemArchetype.Plaguebringer] = new()
            {
                DisplayName = "Plaguebringer",
                FlavorWord = "Blight",
                FavoredClasses = new[] { CharacterClass.Necromancer, CharacterClass.Rogue },
                Prefixes = new[]
                {
                    Prefix("Venomous", nameof(CharacterStats.MagicPower), ModifierType.Flat, 3f, 0.9f, "More spellpower"),
                    Prefix("Festering", nameof(CharacterStats.Attack), ModifierType.Flat, 3f, 0.9f, "More attack"),
                    Prefix("Virulent", nameof(CharacterStats.PenMagic), ModifierType.Flat, 0.05f, 0f, "Pierces wards"),
                    Prefix("Miasmic", nameof(CharacterStats.ResistPoison), ModifierType.Flat, 0.06f, 0f, "Shrugs off poison"),
                },
                Suffixes = new[]
                {
                    Suffix("of Contagion", nameof(CharacterStats.MagicPower), ModifierType.Percent, 0.10f, 0f, "Much more spellpower"),
                    Suffix("of Blight", nameof(CharacterStats.Attack), ModifierType.Percent, 0.10f, 0f, "Much more attack"),
                    Suffix("of Toxins", nameof(CharacterStats.PenMagic), ModifierType.Flat, 0.05f, 0f, "Pierces wards"),
                    Suffix("of the Rat", nameof(CharacterStats.Speed), ModifierType.Flat, 3f, 0f, "Acts sooner"),
                },
            },
            [ItemArchetype.Oracle] = new()
            {
                DisplayName = "Oracle",
                FlavorWord = "Dawn",
                FavoredClasses = new[] { CharacterClass.Cleric },
                Prefixes = new[]
                {
                    Prefix("Blessed", nameof(CharacterStats.MagicPower), ModifierType.Flat, 3f, 1.0f, "Stronger blessings"),
                    Prefix("Vital", nameof(CharacterStats.MaxHp), ModifierType.Flat, 25f, 6f, "More life"),
                    Prefix("Mending", nameof(CharacterStats.HpRegen), ModifierType.Flat, 1f, 0.25f, "Faster recovery"),
                    Prefix("Serene", nameof(CharacterStats.Defense), ModifierType.Flat, 3f, 0.8f, "More defense"),
                },
                Suffixes = new[]
                {
                    Suffix("of Renewal", nameof(CharacterStats.HpRegen), ModifierType.Percent, 0.15f, 0f, "Much faster recovery"),
                    Suffix("of Sanctuary", nameof(CharacterStats.MaxHp), ModifierType.Percent, 0.10f, 0f, "Much more life"),
                    Suffix("of Grace", nameof(CharacterStats.MagicPower), ModifierType.Percent, 0.10f, 0f, "Stronger blessings"),
                    Suffix("of the Vigil", nameof(CharacterStats.Defense), ModifierType.Percent, 0.08f, 0f, "More defense"),
                },
            },
            [ItemArchetype.Windrunner] = new()
            {
                DisplayName = "Windrunner",
                FlavorWord = "Gale",
                FavoredClasses = new[] { CharacterClass.Trickster, CharacterClass.Ranger },
                Prefixes = new[]
                {
                    Prefix("Swift", nameof(CharacterStats.Speed), ModifierType.Flat, 4f, 0f, "Acts sooner"),
                    Prefix("Fleet", nameof(CharacterStats.Speed), ModifierType.Flat, 6f, 0f, "Acts much sooner"),
                    Prefix("Keen", nameof(CharacterStats.CritRate), ModifierType.Flat, 0.04f, 0f, "Better for criticals"),
                    Prefix("Whistling", nameof(CharacterStats.Attack), ModifierType.Flat, 2f, 0.8f, "More attack"),
                },
                Suffixes = new[]
                {
                    Suffix("of the Gale", nameof(CharacterStats.Speed), ModifierType.Percent, 0.06f, 0f, "Acts much sooner"),
                    Suffix("of Haste", nameof(CharacterStats.Speed), ModifierType.Flat, 5f, 0f, "Acts sooner"),
                    Suffix("of the Falcon", nameof(CharacterStats.CritRate), ModifierType.Flat, 0.05f, 0f, "Better for criticals"),
                    Suffix("of Zephyrs", nameof(CharacterStats.Attack), ModifierType.Percent, 0.08f, 0f, "More attack"),
                },
            },
            [ItemArchetype.Breaker] = new()
            {
                DisplayName = "Breaker",
                FlavorWord = "Ruin",
                FavoredClasses = new[]
                {
                    CharacterClass.Warrior, CharacterClass.Berserker, CharacterClass.Elementalist,
                },
                Prefixes = new[]
                {
                    Prefix("Shattering", nameof(CharacterStats.BreakEffect), ModifierType.Flat, 0.12f, 0f, "Harder weakness breaks"),
                    Prefix("Crushing", nameof(CharacterStats.BreakEffect), ModifierType.Flat, 0.20f, 0f, "Devastating weakness breaks"),
                    Prefix("Relentless", nameof(CharacterStats.Speed), ModifierType.Flat, 3f, 0f, "Acts sooner"),
                    Prefix("Sundering", nameof(CharacterStats.PenPhysical), ModifierType.Flat, 0.04f, 0f, "Cuts through armor"),
                },
                Suffixes = new[]
                {
                    Suffix("of Ruin", nameof(CharacterStats.BreakEffect), ModifierType.Flat, 0.15f, 0f, "Harder weakness breaks"),
                    Suffix("of Aftershocks", nameof(CharacterStats.Speed), ModifierType.Flat, 4f, 0f, "Acts sooner"),
                    Suffix("of Fracture", nameof(CharacterStats.BreakEffect), ModifierType.Flat, 0.25f, 0f, "Devastating weakness breaks"),
                    Suffix("of Collapse", nameof(CharacterStats.PenMagic), ModifierType.Flat, 0.04f, 0f, "Pierces wards"),
                },
            },
            [ItemArchetype.Fortunate] = new()
            {
                DisplayName = "Fortunate",
                FlavorWord = "Fortune",
                FavoredClasses = Array.Empty<CharacterClass>(), // universal, like magic-find gear
                Prefixes = new[]
                {
                    Prefix("Lucky", nameof(CharacterStats.Luck), ModifierType.Flat, 0.20f, 0f, "Rarer finds"),
                    Prefix("Prospector's", nameof(CharacterStats.DropRate), ModifierType.Flat, 0.12f, 0f, "More finds"),
                    Prefix("Diligent", nameof(CharacterStats.IdleEfficiency), ModifierType.Flat, 0.06f, 0f, "Tireless progress"),
                    Prefix("Gilded", nameof(CharacterStats.Luck), ModifierType.Flat, 0.35f, 0f, "Much rarer finds"),
                },
                Suffixes = new[]
                {
                    Suffix("of Fortune", nameof(CharacterStats.Luck), ModifierType.Percent, 0.15f, 0f, "Rarer finds"),
                    Suffix("of Plenty", nameof(CharacterStats.DropRate), ModifierType.Percent, 0.12f, 0f, "More finds"),
                    Suffix("of Industry", nameof(CharacterStats.IdleEfficiency), ModifierType.Percent, 0.08f, 0f, "Tireless progress"),
                    Suffix("of the Magpie", nameof(CharacterStats.DropRate), ModifierType.Flat, 0.18f, 0f, "More finds"),
                },
            },
        };

    public static ArchetypeInfo For(ItemArchetype archetype) =>
        Table.TryGetValue(archetype, out var info) ? info : Table[ItemArchetype.Juggernaut];

    public static IReadOnlyCollection<ItemArchetype> All => Table.Keys.ToArray();

    /// <summary>Archetypes whose favored classes include the given class.</summary>
    public static IReadOnlyList<ItemArchetype> FavoredBy(CharacterClass characterClass) =>
        Table.Where(kv => kv.Value.FavoredClasses.Contains(characterClass))
            .Select(kv => kv.Key)
            .ToList();
}
