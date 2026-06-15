namespace IdleRPG.Application.DTOs.Auth;

/// <summary>Result of a successful Steam login.</summary>
public record LoginResultDto
{
    public string AccessToken { get; init; } = string.Empty;
    public string RefreshToken { get; init; } = string.Empty;
    public int ExpiresIn { get; init; } = 900;
    public UserDto User { get; init; } = new();
}

/// <summary>Result of refreshing an access token.</summary>
public record RefreshResultDto
{
    public string AccessToken { get; init; } = string.Empty;
    public int ExpiresIn { get; init; } = 900;
}

/// <summary>Player profile data returned by the Steam Web API.</summary>
public record SteamPlayerSummary
{
    public string SteamId { get; init; } = string.Empty;
    public string PersonaName { get; init; } = string.Empty;
    public string AvatarUrl { get; init; } = string.Empty;
}
