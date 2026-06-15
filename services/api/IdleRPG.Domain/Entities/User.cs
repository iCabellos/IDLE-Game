using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.Entities;

/// <summary>
/// A registered player, identified by their Steam id.
/// </summary>
public class User
{
    public Guid Id { get; set; }
    public string SteamId { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;
    public string? Email { get; set; }
    public int AccountLevel { get; set; } = 1;
    public AccountStatus Status { get; set; } = AccountStatus.Active;
    public int AntiBotRiskScore { get; set; }
    public bool IsBanned { get; set; }
    public DateTimeOffset? BannedAt { get; set; }
    public string? BanReason { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset LastLoginAt { get; set; }

    /// <summary>Soft-delete marker. Non-null rows are filtered out of all queries.</summary>
    public DateTimeOffset? DeletedAt { get; set; }

    // Navigation
    public ICollection<Character> Characters { get; set; } = new List<Character>();
}
