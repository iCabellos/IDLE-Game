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
    IReadOnlyList<string> Items,
    string Combo,
    double Multiplier,
    bool ActorIsHero);
