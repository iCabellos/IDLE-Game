using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace IdleRPG.Infrastructure.Idle;

/// <summary>
/// Hangfire recurring job (every 60s): advances the idle simulation for
/// every user with an active team. One scheduler pass simulates the 60
/// elapsed ticks (1 tick = 1s); users far behind (offline) are advanced by
/// their whole elapsed window, capped and scaled by offline efficiency
/// inside <see cref="IIdleProgressService"/>.
/// </summary>
public sealed class IdleTickJob
{
    public const string JobId = "idle-tick";
    public const string CronEveryMinute = "* * * * *";

    private readonly IRepository<Character> _characters;
    private readonly IIdleProgressService _progress;
    private readonly ILogger<IdleTickJob> _logger;

    public IdleTickJob(
        IRepository<Character> characters,
        IIdleProgressService progress,
        ILogger<IdleTickJob> logger)
    {
        _characters = characters;
        _progress = progress;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken ct = default)
    {
        var active = await _characters.GetAllAsync(new ActiveCharactersSpec(), ct);
        var userIds = active.Select(c => c.UserId).Distinct().ToList();

        var failures = 0;
        foreach (var userId in userIds)
        {
            try
            {
                await _progress.AdvanceAsync(userId, ct);
            }
            catch (Exception ex)
            {
                failures++;
                _logger.LogWarning(ex, "Idle tick failed for user {UserId}", userId);
            }
        }

        _logger.LogInformation(
            "Idle tick advanced {Users} users ({Failures} failures)", userIds.Count, failures);
    }
}
