using IdleRPG.Application.Interfaces.Caching;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Domain.Combat;

namespace IdleRPG.Infrastructure.Idle;

/// <summary>
/// Persists <see cref="IdleState"/> in Redis under the canonical key
/// <c>idle:state:{userId}</c>. The sliding 30-day TTL keeps state alive for
/// any account that logs in (or is ticked by the job) at least monthly.
/// </summary>
public sealed class RedisIdleStateStore : IIdleStateStore
{
    private static readonly TimeSpan StateTtl = TimeSpan.FromDays(30);

    private readonly ICacheService _cache;

    public RedisIdleStateStore(ICacheService cache)
    {
        _cache = cache;
    }

    public Task<IdleState?> GetAsync(Guid userId, CancellationToken ct = default) =>
        _cache.GetAsync<IdleState>($"idle:state:{userId}", ct);

    public Task SaveAsync(Guid userId, IdleState state, CancellationToken ct = default) =>
        _cache.SetAsync($"idle:state:{userId}", state, StateTtl, ct);
}
