using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.GameData;

/// <summary>
/// Combat kit of a character class (F4). Defines the elemental damage type,
/// the scaling stat, ability multipliers, ultimate energy cost and toughness
/// (break) power. Ability *behaviour* (damage vs heal vs buff) is decided by
/// the character's <see cref="CharacterRole"/> at battle time; the kit only
/// provides the numbers.
/// </summary>
public sealed record ClassKit
{
    public required DamageType DamageType { get; init; }

    /// <summary>True = abilities scale with MagicPower, false = Attack.</summary>
    public required bool ScalesWithMagic { get; init; }

    public required float BasicMultiplier { get; init; }
    public required float SkillMultiplier { get; init; }
    public required float UltimateMultiplier { get; init; }

    /// <summary>Energy needed to charge the ultimate (HSR-style 100-140).</summary>
    public required int UltimateEnergyCost { get; init; }
}

/// <summary>Canonical kit table, one entry per <see cref="CharacterClass"/>.</summary>
public static class ClassKits
{
    // Elements are spread evenly (2 classes per damage type) so any enemy
    // weakness combination can be covered by some team composition.
    private static readonly IReadOnlyDictionary<CharacterClass, ClassKit> Table =
        new Dictionary<CharacterClass, ClassKit>
        {
            [CharacterClass.Warrior] = new()
            {
                DamageType = DamageType.Physical, ScalesWithMagic = false,
                BasicMultiplier = 1.0f, SkillMultiplier = 2.0f, UltimateMultiplier = 4.0f,
                UltimateEnergyCost = 120,
            },
            [CharacterClass.Mage] = new()
            {
                DamageType = DamageType.Ice, ScalesWithMagic = true,
                BasicMultiplier = 1.0f, SkillMultiplier = 2.6f, UltimateMultiplier = 5.0f,
                UltimateEnergyCost = 140,
            },
            [CharacterClass.Rogue] = new()
            {
                DamageType = DamageType.Poison, ScalesWithMagic = false,
                BasicMultiplier = 1.1f, SkillMultiplier = 2.4f, UltimateMultiplier = 4.5f,
                UltimateEnergyCost = 110,
            },
            [CharacterClass.Cleric] = new()
            {
                DamageType = DamageType.Lightning, ScalesWithMagic = true,
                BasicMultiplier = 0.8f, SkillMultiplier = 1.8f, UltimateMultiplier = 3.0f,
                UltimateEnergyCost = 130,
            },
            [CharacterClass.Ranger] = new()
            {
                DamageType = DamageType.Physical, ScalesWithMagic = false,
                BasicMultiplier = 1.1f, SkillMultiplier = 2.3f, UltimateMultiplier = 4.2f,
                UltimateEnergyCost = 115,
            },
            [CharacterClass.Necromancer] = new()
            {
                DamageType = DamageType.Poison, ScalesWithMagic = true,
                BasicMultiplier = 0.9f, SkillMultiplier = 2.4f, UltimateMultiplier = 4.6f,
                UltimateEnergyCost = 130,
            },
            [CharacterClass.Paladin] = new()
            {
                DamageType = DamageType.Fire, ScalesWithMagic = false,
                BasicMultiplier = 0.9f, SkillMultiplier = 1.8f, UltimateMultiplier = 3.5f,
                UltimateEnergyCost = 125,
            },
            [CharacterClass.Berserker] = new()
            {
                DamageType = DamageType.Fire, ScalesWithMagic = false,
                BasicMultiplier = 1.2f, SkillMultiplier = 2.8f, UltimateMultiplier = 5.5f,
                UltimateEnergyCost = 130,
            },
            [CharacterClass.Elementalist] = new()
            {
                DamageType = DamageType.Lightning, ScalesWithMagic = true,
                BasicMultiplier = 1.0f, SkillMultiplier = 2.7f, UltimateMultiplier = 5.2f,
                UltimateEnergyCost = 140,
            },
            [CharacterClass.Trickster] = new()
            {
                DamageType = DamageType.Ice, ScalesWithMagic = false,
                BasicMultiplier = 1.0f, SkillMultiplier = 2.2f, UltimateMultiplier = 4.0f,
                UltimateEnergyCost = 115,
            },
        };

    /// <summary>Returns the kit for a class (unknown classes fall back to Warrior).</summary>
    public static ClassKit For(CharacterClass characterClass) =>
        Table.TryGetValue(characterClass, out var kit) ? kit : Table[CharacterClass.Warrior];
}
