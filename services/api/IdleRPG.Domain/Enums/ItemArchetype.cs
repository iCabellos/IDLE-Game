namespace IdleRPG.Domain.Enums;

/// <summary>
/// Thematic identity of a generated item, ARPG-style (F4 loot rework).
/// Each archetype owns a coherent affix pool and favors specific classes,
/// which drives Diablo-style smart loot: drops lean toward archetypes the
/// active team can actually use.
/// </summary>
public enum ItemArchetype
{
    /// <summary>Immovable frontline: defense, max HP, resistances.</summary>
    Juggernaut = 1,

    /// <summary>Physical killer: attack, crit chance/damage, armor pen.</summary>
    Executioner = 2,

    /// <summary>Elemental burst caster: magic power, magic pen, ice/lightning.</summary>
    Stormcaller = 3,

    /// <summary>Decay and venom: poison damage, hybrid attack/magic.</summary>
    Plaguebringer = 4,

    /// <summary>Mender and protector: healing power, regen, max HP.</summary>
    Oracle = 5,

    /// <summary>Tempo fighter: speed, crit, acting before the enemy.</summary>
    Windrunner = 6,

    /// <summary>Weakness exploiter: break effect and speed (HSR combat).</summary>
    Breaker = 7,

    /// <summary>Treasure hunter: luck, drop rate, idle efficiency.</summary>
    Fortunate = 8
}
