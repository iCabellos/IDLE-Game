using IdleRPG.Application.DTOs.Auth;
using MediatR;

namespace IdleRPG.Application.UseCases.Auth.SteamLogin;

/// <summary>
/// Completes a Steam OpenID 2.0 login. The raw OpenID callback query string is
/// verified against Steam, the profile is fetched, the user is upserted and a
/// fresh access/refresh token pair is returned.
/// </summary>
public record SteamLoginCommand(string OpenIdPayload) : IRequest<LoginResultDto>;
