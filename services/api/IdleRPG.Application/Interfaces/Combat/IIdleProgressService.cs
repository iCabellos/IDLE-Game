using IdleRPG.Domain.Combat;

namespace IdleRPG.Application.Interfaces.Combat;

/// <summary>The idle state plus the team it was simulated with.</summary>
public sealed record IdleProgress(IdleState State, IReadOnlyList<HeroSpec> Team);

/// <summary>
/// Orchestrates idle progression for one user: loads the team and its cached
/// stats, advances the deterministic simulation by the wall-clock time since
/// the last advance (scaled by offline efficiency) and persists the state.
/// Called from the combat use cases and from the Hangfire idle tick job.
/// </summary>
public interface IIdleProgressService
{
    /// <summary>
    /// Advances and persists the user's idle state. Returns null when the
    /// user has no active team (nothing to simulate).
    /// </summary>
    Task<IdleProgress?> AdvanceAsync(Guid userId, CancellationToken ct = default);
}
