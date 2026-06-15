using IdleRPG.Application.DTOs.Auth;

namespace IdleRPG.Application.Interfaces.Auth;

/// <summary>
/// Validates Steam OpenID 2.0 callbacks and fetches player profile data.
/// </summary>
public interface ISteamAuthService
{
    /// <summary>
    /// Verifies the OpenID 2.0 response against steamcommunity.com and
    /// returns the authenticated Steam64 id, or null if verification fails.
    /// </summary>
    Task<string?> ValidateOpenIdAsync(string openIdPayload, CancellationToken ct = default);

    /// <summary>
    /// Calls ISteamUser/GetPlayerSummaries to fetch the player's profile.
    /// </summary>
    Task<SteamPlayerSummary?> GetPlayerSummaryAsync(string steamId, CancellationToken ct = default);
}
