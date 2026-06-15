using IdleRPG.Application.UseCases.Auth.GetMe;
using IdleRPG.Application.UseCases.Auth.Logout;
using IdleRPG.Application.UseCases.Auth.RefreshToken;
using IdleRPG.Application.UseCases.Auth.SteamLogin;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace IdleRPG.API.Endpoints;

/// <summary>Steam authentication endpoints.</summary>
public static class AuthEndpoints
{
    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/auth").WithTags("Auth");

        // POST /auth/steam/login — complete a Steam OpenID 2.0 login.
        group.MapPost("/steam/login", async (
            [FromBody] SteamLoginRequest request,
            ISender sender,
            CancellationToken ct) =>
        {
            var result = await sender.Send(new SteamLoginCommand(request.OpenIdPayload), ct);
            return Results.Ok(result);
        })
        .WithName("SteamLogin")
        .AllowAnonymous();

        // POST /auth/refresh — exchange a refresh token for a new access token.
        group.MapPost("/refresh", async (
            [FromBody] RefreshRequest request,
            ISender sender,
            CancellationToken ct) =>
        {
            var result = await sender.Send(new RefreshTokenCommand(request.RefreshToken), ct);
            return Results.Ok(result);
        })
        .WithName("RefreshToken")
        .AllowAnonymous();

        // DELETE /auth/logout — revoke a refresh token.
        group.MapDelete("/logout", async (
            [FromBody] RefreshRequest request,
            ISender sender,
            CancellationToken ct) =>
        {
            await sender.Send(new LogoutCommand(request.RefreshToken), ct);
            return Results.NoContent();
        })
        .WithName("Logout")
        .RequireAuthorization();

        // GET /auth/me — the authenticated user's profile.
        group.MapGet("/me", async (ISender sender, CancellationToken ct) =>
        {
            var result = await sender.Send(new GetMeQuery(), ct);
            return Results.Ok(result);
        })
        .WithName("GetMe")
        .RequireAuthorization();

        return app;
    }
}

public record SteamLoginRequest(string OpenIdPayload);

public record RefreshRequest(string RefreshToken);
