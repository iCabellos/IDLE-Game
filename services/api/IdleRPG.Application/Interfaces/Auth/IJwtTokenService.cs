using IdleRPG.Domain.Entities;

namespace IdleRPG.Application.Interfaces.Auth;

/// <summary>
/// Issues signed JWT access tokens and opaque refresh tokens.
/// </summary>
public interface IJwtTokenService
{
    /// <summary>
    /// Creates a signed access token for the user. Claims: sub=userId,
    /// steam=steamId, name=username. Lifetime is 15 minutes.
    /// </summary>
    string CreateAccessToken(User user);

    /// <summary>
    /// Generates a cryptographically-random raw refresh token (returned to the
    /// client once) together with its SHA-256 hash (persisted for lookup).
    /// </summary>
    (string RawToken, string TokenHash) CreateRefreshToken();

    /// <summary>Hashes a raw refresh token with SHA-256 for database lookup.</summary>
    string HashRefreshToken(string rawToken);

    /// <summary>Access token lifetime in seconds (900 = 15 minutes).</summary>
    int AccessTokenLifetimeSeconds { get; }

    /// <summary>Refresh token lifetime, in days (7).</summary>
    int RefreshTokenLifetimeDays { get; }
}
