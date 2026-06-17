namespace IdleRPG.Domain.Entities;

/// <summary>
/// Server-authoritative idle-combat run owned by a <see cref="User"/> (one run
/// per user). Progression columns are promoted for querying; the full volatile
/// combat state (hero/enemy HP, slot reel, RNG progress) lives in
/// <see cref="StateJson"/> as <c>IdleRPG.Domain.GameData.GameState</c>.
/// </summary>
public class GameRun
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public int LevelIndex { get; set; }
    public int PhaseIndex { get; set; }
    public int WaveIndex { get; set; }
    public long TickCount { get; set; }

    /// <summary>Serialized mutable combat state (jsonb).</summary>
    public string StateJson { get; set; } = "{}";

    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // Navigation
    public User? User { get; set; }
}
