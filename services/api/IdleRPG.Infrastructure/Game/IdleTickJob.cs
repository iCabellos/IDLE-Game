using IdleRPG.Application.Interfaces.Game;
using Microsoft.Extensions.Logging;

namespace IdleRPG.Infrastructure.Game;

/// <summary>
/// Recurring Hangfire job that advances every idle run on the server so combat
/// keeps progressing 24/7 even when no client is connected. Registered in
/// Program.cs as a recurring job.
/// </summary>
public sealed class IdleTickJob
{
    private readonly IGameService _game;
    private readonly ILogger<IdleTickJob> _logger;

    public IdleTickJob(IGameService game, ILogger<IdleTickJob> logger)
    {
        _game = game;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken ct = default)
    {
        await _game.TickAllAsync(ct);
        _logger.LogDebug("Idle tick job advanced all runs.");
    }
}
