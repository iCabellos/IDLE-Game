namespace IdleRPG.Domain.GameData;

/// <summary>
/// Mutable, server-authoritative combat state. Serialized into
/// <c>GameRun.StateJson</c>. Plain mutable POCOs so System.Text.Json can
/// round-trip it without custom converters.
/// </summary>
public sealed class GameState
{
    public int Tick { get; set; }
    public int LevelIndex { get; set; }
    public int PhaseIndex { get; set; }
    public int WaveIndex { get; set; }
    public int Turn { get; set; }
    public List<HeroState> Heroes { get; set; } = new();
    public List<EnemyState> Enemies { get; set; } = new();
    public ReelState Reel { get; set; } = new();
    public string Outcome { get; set; } = "HIT";
    public string Status { get; set; } = "fighting";
}

public sealed class HeroState
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Archetype { get; set; } = "physical";
    public int Level { get; set; } = 1;
    public double MaxHp { get; set; }
    public double Hp { get; set; }
    public int ReviveIn { get; set; } = -1;

    /// <summary>The (up to) 7 equipped reel kinds this hero can roll.</summary>
    public List<string> SlotKinds { get; set; } = new();

    /// <summary>Reel luck (raises odds of pair / synergy / jackpot).</summary>
    public double Luck { get; set; }
}

public sealed class EnemyState
{
    public string Id { get; set; } = string.Empty;
    public string Kind { get; set; } = "slime";
    public double MaxHp { get; set; }
    public double Hp { get; set; }
    public bool IsBoss { get; set; }
}

public sealed class ReelState
{
    public List<ReelItem> Items { get; set; } = new();
    public string Combo { get; set; } = "MIXED";
    public double Multiplier { get; set; } = 1;
    public int MaxRarityTier { get; set; } = 1;
    public bool ActorIsHero { get; set; } = true;
    public string? ActorId { get; set; }
    public string? TargetId { get; set; }
}

/// <summary>One item shown in a reel position, with its resolved benefit.</summary>
public sealed class ReelItem
{
    public string Kind { get; set; } = string.Empty;
    public string Shape { get; set; } = "sword";
    public int RarityTier { get; set; } = 1;
    public string Rarity { get; set; } = "Broken";
    public string Primary { get; set; } = string.Empty;
    public List<string> Passives { get; set; } = new();
}
