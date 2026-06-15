namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// Immutable snapshot of all combat/idle stats for a character.
/// Caps (applied by the StatAggregator in F3): CritRate &lt;= 0.75,
/// CritMultiplier &lt;= 5.0, resistances &lt;= 0.90.
/// </summary>
public record CharacterStats
{
    // Primarios
    public float Attack { get; init; }
    public float Defense { get; init; }
    public float MagicPower { get; init; }
    public float MaxHp { get; init; }
    public float HpRegen { get; init; } // HP por tick

    // Criticos
    public float CritRate { get; init; }       // 0.0 - 0.75 (cap 75%)
    public float CritMultiplier { get; init; } // 1.5 - 5.0 (cap 5x)

    // Resistencias por tipo (0.0 - 0.90 cap antes de penetracion)
    public float ResistPhysical { get; init; }
    public float ResistFire { get; init; }
    public float ResistIce { get; init; }
    public float ResistLightning { get; init; }
    public float ResistPoison { get; init; }

    // Penetracion (reduce resistencia efectiva del enemigo)
    public float PenPhysical { get; init; }
    public float PenMagic { get; init; }

    // Idle-specific
    public float IdleEfficiency { get; init; } // 1.0 = 100% base
    public float DropRate { get; init; }        // 1.0 = 100% base
    public float Luck { get; init; }            // afecta rarity roll

    /// <summary>An all-zero stat block; convenient as an aggregation seed.</summary>
    public static CharacterStats Zero { get; } = new();
}
