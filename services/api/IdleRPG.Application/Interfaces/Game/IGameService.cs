using IdleRPG.Domain.GameData;

namespace IdleRPG.Application.Interfaces.Game;

/// <summary>
/// Server-authoritative idle game. The run advances on the server (lazily on
/// read by elapsed time, and 24/7 via the Hangfire tick job); the client only
/// reads the projected <see cref="GameSnapshot"/> and paints it.
/// </summary>
public interface IGameService
{
    /// <summary>
    /// Returns the user's current snapshot, creating the run on first access and
    /// advancing it by the real time elapsed since the last update.
    /// </summary>
    Task<GameSnapshot> GetStateAsync(Guid userId, CancellationToken ct = default);

    /// <summary>
    /// The demo/preview user's snapshot (no auth required) for the early client.
    /// </summary>
    Task<GameSnapshot> GetPreviewStateAsync(CancellationToken ct = default);

    /// <summary>
    /// Advances every active run by the elapsed time. Invoked by the recurring
    /// Hangfire job so combat keeps running 24/7 even with no client connected.
    /// </summary>
    Task TickAllAsync(CancellationToken ct = default);
}
