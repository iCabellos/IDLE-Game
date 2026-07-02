using IdleRPG.Domain.Combat;

namespace IdleRPG.Application.Interfaces.Combat;

/// <summary>
/// Persistence of the canonical idle progression state. Backed by Redis
/// under the key <c>idle:state:{userId}</c> (implemented in Infrastructure).
/// </summary>
public interface IIdleStateStore
{
    Task<IdleState?> GetAsync(Guid userId, CancellationToken ct = default);

    Task SaveAsync(Guid userId, IdleState state, CancellationToken ct = default);
}
