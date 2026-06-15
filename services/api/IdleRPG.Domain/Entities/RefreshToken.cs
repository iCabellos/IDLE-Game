namespace IdleRPG.Domain.Entities;

/// <summary>
/// A hashed refresh token. The raw token value is only ever returned to the
/// client once; the database stores a SHA-256 hash for lookup/revocation.
/// </summary>
public class RefreshToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    /// <summary>SHA-256 hash (hex) of the raw refresh token.</summary>
    public string TokenHash { get; set; } = string.Empty;

    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? RevokedAt { get; set; }

    public bool IsActive => RevokedAt is null && ExpiresAt > DateTimeOffset.UtcNow;

    // Navigation
    public User? User { get; set; }
}
