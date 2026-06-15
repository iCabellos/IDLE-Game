using IdleRPG.Application.Interfaces.Items;

namespace IdleRPG.Infrastructure.Items;

/// <summary>
/// Stub Steam inventory ownership check. The full implementation (calling the
/// Steam inventory endpoint and reconciling assets) arrives in F5; until then
/// ownership is optimistically granted so the equip flow is exercisable.
/// </summary>
public sealed class SteamInventoryService : ISteamInventoryService
{
    public Task<bool> OwnsAssetAsync(
        string steamId, string steamInventoryId, CancellationToken ct = default)
        => Task.FromResult(true);
}
