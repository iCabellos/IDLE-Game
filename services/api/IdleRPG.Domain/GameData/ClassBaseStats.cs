using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.GameData;

/// <summary>
/// Per-class base stats. Primary stats scale linearly with level
/// (per-level growth × level); secondary stats (crit, resistances, idle) use
/// flat baselines shared by all classes.
/// </summary>
public static class ClassBaseStats
{
    private sealed record Growth(
        float Attack, float Defense, float MagicPower, float MaxHp, float HpRegen);

    // Per-level growth tuned so each class has a distinct identity.
    private static readonly IReadOnlyDictionary<CharacterClass, Growth> Table =
        new Dictionary<CharacterClass, Growth>
        {
            [CharacterClass.Warrior]      = new(5.0f, 6.0f, 0.0f, 55f, 1.2f),
            [CharacterClass.Mage]         = new(1.0f, 2.0f, 7.0f, 30f, 0.6f),
            [CharacterClass.Rogue]        = new(6.0f, 3.0f, 0.0f, 35f, 0.8f),
            [CharacterClass.Cleric]       = new(2.0f, 4.0f, 5.0f, 40f, 1.5f),
            [CharacterClass.Ranger]       = new(5.5f, 3.0f, 1.0f, 35f, 0.8f),
            [CharacterClass.Necromancer]  = new(1.5f, 2.5f, 6.5f, 32f, 0.7f),
            [CharacterClass.Paladin]      = new(4.0f, 5.5f, 2.0f, 50f, 1.4f),
            [CharacterClass.Berserker]    = new(7.0f, 2.0f, 0.0f, 45f, 0.9f),
            [CharacterClass.Elementalist] = new(1.0f, 2.0f, 7.5f, 30f, 0.6f),
            [CharacterClass.Trickster]    = new(5.0f, 3.0f, 3.0f, 34f, 0.8f),
        };

    /// <summary>Returns the level-scaled base stats for a class.</summary>
    public static CharacterStats For(CharacterClass characterClass, int level)
    {
        var g = Table.TryGetValue(characterClass, out var growth)
            ? growth
            : Table[CharacterClass.Warrior];

        var lvl = Math.Max(level, 1);

        return new CharacterStats
        {
            Attack = g.Attack * lvl,
            Defense = g.Defense * lvl,
            MagicPower = g.MagicPower * lvl,
            MaxHp = g.MaxHp * lvl,
            HpRegen = g.HpRegen * lvl,

            // Shared secondary baselines.
            CritRate = 0.05f,
            CritMultiplier = 1.5f,
            IdleEfficiency = 1.0f,
            DropRate = 1.0f,
            Luck = 1.0f,
        };
    }
}
