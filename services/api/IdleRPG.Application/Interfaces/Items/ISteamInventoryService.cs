namespace IdleRPG.Application.Interfaces.Items;

/// <summary>
/// Abstraction over the Steam inventory used to validate that a player still
/// owns a given inventory asset. The full implementation arrives in F5.
/// </summary>
public interface ISteamInventoryService
{
    Task<bool> OwnsAssetAsync(string steamId, string steamInventoryId, CancellationToken ct = default);
}
