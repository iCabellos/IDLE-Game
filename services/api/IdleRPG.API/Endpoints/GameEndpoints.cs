using IdleRPG.Application.Interfaces.Game;

namespace IdleRPG.API.Endpoints;

/// <summary>
/// Read-only window into the server-authoritative idle game. The client is a
/// dumb painter: it polls the snapshot and renders it. All combat logic, RNG,
/// progression and persistence live on the server (advanced 24/7 by the Hangfire
/// tick job). Exposes only fractions and qualitative labels — no raw stats.
/// </summary>
public static class GameEndpoints
{
    public static IEndpointRouteBuilder MapGameEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/game").WithTags("Game");

        // GET /game/state — preview user's live snapshot (anonymous, for the
        // early client). Reading also advances the run by elapsed time.
        group.MapGet("/state", async (IGameService game, CancellationToken ct) =>
        {
            var snapshot = await game.GetPreviewStateAsync(ct);
            return Results.Ok(snapshot);
        })
        .WithName("GetGameState")
        .AllowAnonymous();

        return app;
    }
}
