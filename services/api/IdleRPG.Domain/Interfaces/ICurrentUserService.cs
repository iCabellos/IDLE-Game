namespace IdleRPG.Domain.Interfaces;

/// <summary>
/// Exposes the identity of the user making the current request.
/// </summary>
public interface ICurrentUserService
{
    Guid? UserId { get; }

    string? SteamId { get; }

    bool IsAuthenticated { get; }
}
