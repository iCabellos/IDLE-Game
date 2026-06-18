namespace IdleRPG.Domain.GameData;

/// <summary>
/// Immutable, paint-ready projection of <see cref="GameState"/> for the dumb
/// client. Exposes only fractions and qualitative labels — never raw stats.
/// </summary>
public sealed record GameSnapshot(
    long Tick,
    int LevelIndex,
    string LevelName,
    string Theme,
    int PhaseIndex,
    int PhaseCount,
    int WaveIndex,
    int WavesPerPhase,
    IReadOnlyList<HeroView> Heroes,
    IReadOnlyList<EnemyView> Enemies,
    ReelView Reel,
    string Outcome,
    string Status);

public sealed record HeroView(
    string Id,
    string Name,
    string Archetype,
    int Level,
    double HpFraction,
    bool Alive,
    bool Acting);

public sealed record EnemyView(
    string Id,
    string Kind,
    double HpFraction,
    bool Alive,
    bool IsBoss,
    bool Hit);

public sealed record ReelView(
    IReadOnlyList<ReelItemView> Items,
    string Combo,
    double Multiplier,
    int MaxRarityTier,
    bool ActorIsHero,
    DamageView? Damage,
    IReadOnlyList<SubStatView> Ledger);

public sealed record SubStatView(
    string Stat, string Before, string After, int Cell, int Line, string Target);

public sealed record ReelItemView(
    string Kind,
    string Shape,
    int Level,
    int RarityTier,
    string Rarity,
    string Primary,
    IReadOnlyList<string> Passives);

public sealed record DamageView(
    string HeroName,
    double Total,
    double CritRate,
    bool Crit,
    IReadOnlyList<DamageStepView> Steps);

public sealed record DamageStepView(string Label, double Total, string Kind);
