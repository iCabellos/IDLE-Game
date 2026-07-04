namespace IdleRPG.Domain.Combat;

/// <summary>
/// Deterministic outcome of one simulated battle. Aggregated counters exist
/// so tests can assert that every HSR-style mechanic actually fires.
/// </summary>
public sealed record BattleResult
{
    public required bool Victory { get; init; }

    /// <summary>Total action value elapsed on the battle timeline.</summary>
    public required float ElapsedAv { get; init; }

    /// <summary>Battle duration in idle ticks (1 tick = 1s = 10 AV).</summary>
    public required int Ticks { get; init; }

    public required int HeroActions { get; init; }
    public required int BasicsCast { get; init; }
    public required int SkillsCast { get; init; }
    public required int UltimatesCast { get; init; }
    public required int HealsCast { get; init; }
    public required int BuffsCast { get; init; }
    public required int BreaksTriggered { get; init; }

    public required float DamageDealtByHeroes { get; init; }
    public required float DamageTakenByHeroes { get; init; }

    public required int HeroesDown { get; init; }

    /// <summary>Lowest surviving-hero HP fraction at battle end (0 when a hero died).</summary>
    public required float LowestHeroHpFraction { get; init; }
}
