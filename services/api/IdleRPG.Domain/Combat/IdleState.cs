using IdleRPG.Domain.Loot;

namespace IdleRPG.Domain.Combat;

/// <summary>Readable outcome of the most recent simulated battle.</summary>
public enum IdleBattleOutcome
{
    Winning = 1,
    Danger = 2,
    Stuck = 3
}

/// <summary>
/// Canonical idle progression state stored in Redis under
/// <c>idle:state:{userId}</c>. Mutable by the simulator only; everything the
/// client sees is derived from this into readable, non-numeric statuses.
/// </summary>
public sealed class IdleState
{
    public int Zone { get; set; } = 1;

    /// <summary>Wave within the zone, 1..10 (10 = boss).</summary>
    public int Wave { get; set; } = 1;

    /// <summary>Battles fought so far — seeds the next battle deterministically.</summary>
    public long BattleCounter { get; set; }

    /// <summary>Unspent simulation ticks smaller than one battle's cost.</summary>
    public int CarryTicks { get; set; }

    public long PendingXp { get; set; }

    /// <summary>
    /// Generated ARPG drops (named, archetyped, affixed) awaiting the Steam
    /// sync (F5). Capped at <see cref="IdleSimulator.MaxPendingLoot"/>;
    /// overflow is tallied in <see cref="OverflowLoot"/>.
    /// </summary>
    public List<LootDrop> PendingLoot { get; set; } = new();

    /// <summary>Drops beyond the pending-loot cap (summarised, not lost silently).</summary>
    public int OverflowLoot { get; set; }

    public int ConsecutiveLosses { get; set; }

    public IdleBattleOutcome LastOutcome { get; set; } = IdleBattleOutcome.Winning;

    public long TotalKills { get; set; }

    public long LastSimulatedAtUnix { get; set; }

    /// <summary>True while the team cannot beat the current wave (needs gear/levels).</summary>
    public bool IsStuck => ConsecutiveLosses >= IdleSimulator.StuckThreshold;
}

/// <summary>Aggregate of what happened during one simulation advance.</summary>
public sealed record IdleAdvanceReport
{
    public int BattlesWon { get; init; }
    public int BattlesLost { get; init; }
    public long XpGained { get; init; }
    public int DropsRolled { get; init; }
    public int ZonesCleared { get; init; }
}
