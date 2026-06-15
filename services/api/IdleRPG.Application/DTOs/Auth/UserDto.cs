namespace IdleRPG.Application.DTOs.Auth;

public record UserDto
{
    public Guid Id { get; init; }
    public string SteamId { get; init; } = string.Empty;
    public string Username { get; init; } = string.Empty;
    public string AvatarUrl { get; init; } = string.Empty;
    public int AccountLevel { get; init; }

    /// <summary>active | warned | restricted | banned</summary>
    public string AccountStatus { get; init; } = "active";

    public DateTimeOffset CreatedAt { get; init; }
    public DateTimeOffset LastLoginAt { get; init; }
}
