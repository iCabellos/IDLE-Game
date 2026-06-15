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

    /// <summary>Stat caps applied by the aggregator after all modifiers.</summary>
    public const float CritRateCap = 0.75f;
    public const float CritMultiplierCap = 5.0f;
    public const float ResistCap = 0.90f;

    /// <summary>Projects every stat into a name→value dictionary for aggregation.</summary>
    public IDictionary<string, float> ToDictionary() => new Dictionary<string, float>
    {
        [nameof(Attack)] = Attack,
        [nameof(Defense)] = Defense,
        [nameof(MagicPower)] = MagicPower,
        [nameof(MaxHp)] = MaxHp,
        [nameof(HpRegen)] = HpRegen,
        [nameof(CritRate)] = CritRate,
        [nameof(CritMultiplier)] = CritMultiplier,
        [nameof(ResistPhysical)] = ResistPhysical,
        [nameof(ResistFire)] = ResistFire,
        [nameof(ResistIce)] = ResistIce,
        [nameof(ResistLightning)] = ResistLightning,
        [nameof(ResistPoison)] = ResistPoison,
        [nameof(PenPhysical)] = PenPhysical,
        [nameof(PenMagic)] = PenMagic,
        [nameof(IdleEfficiency)] = IdleEfficiency,
        [nameof(DropRate)] = DropRate,
        [nameof(Luck)] = Luck,
    };

    /// <summary>Rebuilds a stat block from a name→value dictionary.</summary>
    public static CharacterStats FromDictionary(IReadOnlyDictionary<string, float> d)
    {
        float Get(string k) => d.TryGetValue(k, out var v) ? v : 0f;
        return new CharacterStats
        {
            Attack = Get(nameof(Attack)),
            Defense = Get(nameof(Defense)),
            MagicPower = Get(nameof(MagicPower)),
            MaxHp = Get(nameof(MaxHp)),
            HpRegen = Get(nameof(HpRegen)),
            CritRate = Get(nameof(CritRate)),
            CritMultiplier = Get(nameof(CritMultiplier)),
            ResistPhysical = Get(nameof(ResistPhysical)),
            ResistFire = Get(nameof(ResistFire)),
            ResistIce = Get(nameof(ResistIce)),
            ResistLightning = Get(nameof(ResistLightning)),
            ResistPoison = Get(nameof(ResistPoison)),
            PenPhysical = Get(nameof(PenPhysical)),
            PenMagic = Get(nameof(PenMagic)),
            IdleEfficiency = Get(nameof(IdleEfficiency)),
            DropRate = Get(nameof(DropRate)),
            Luck = Get(nameof(Luck)),
        };
    }

    /// <summary>Returns a copy with all gameplay caps enforced.</summary>
    public CharacterStats ApplyCaps() => this with
    {
        CritRate = Math.Clamp(CritRate, 0f, CritRateCap),
        CritMultiplier = Math.Clamp(CritMultiplier, 1.5f, CritMultiplierCap),
        ResistPhysical = Math.Clamp(ResistPhysical, 0f, ResistCap),
        ResistFire = Math.Clamp(ResistFire, 0f, ResistCap),
        ResistIce = Math.Clamp(ResistIce, 0f, ResistCap),
        ResistLightning = Math.Clamp(ResistLightning, 0f, ResistCap),
        ResistPoison = Math.Clamp(ResistPoison, 0f, ResistCap),
    };
}
