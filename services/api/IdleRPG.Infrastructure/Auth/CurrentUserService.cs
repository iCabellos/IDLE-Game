using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using IdleRPG.Domain.Interfaces;
using Microsoft.AspNetCore.Http;

namespace IdleRPG.Infrastructure.Auth;

/// <summary>Reads the authenticated user's identity from the current HTTP request.</summary>
public sealed class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _accessor;

    public CurrentUserService(IHttpContextAccessor accessor)
    {
        _accessor = accessor;
    }

    private ClaimsPrincipal? User => _accessor.HttpContext?.User;

    public Guid? UserId
    {
        get
        {
            var sub = User?.FindFirstValue(JwtRegisteredClaimNames.Sub)
                      ?? User?.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(sub, out var id) ? id : null;
        }
    }

    public string? SteamId => User?.FindFirstValue("steam");

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated ?? false;
}
