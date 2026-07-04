using IdleRPG.Application.UseCases.Combat.ClaimRewards;
using IdleRPG.Application.UseCases.Combat.GetCombatState;
using IdleRPG.Application.UseCases.Combat.GetZones;
using MediatR;

namespace IdleRPG.API.Endpoints;

/// <summary>
/// Idle combat endpoints (F4). Responses follow the UX rule: readable
/// statuses (winning / danger / stuck / rewards_ready), never raw stats.
/// </summary>
public static class CombatEndpoints
{
    public static IEndpointRouteBuilder MapCombatEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/combat").WithTags("Combat").RequireAuthorization();

        // GET /combat/state — advances the idle sim and returns readable state.
        group.MapGet("/state", async (ISender sender, CancellationToken ct) =>
        {
            var result = await sender.Send(new GetCombatStateQuery(), ct);
            return Results.Ok(result);
        })
        .WithName("GetCombatState");

        // POST /combat/claim — applies pending XP to the team.
        group.MapPost("/claim", async (ISender sender, CancellationToken ct) =>
        {
            var result = await sender.Send(new ClaimRewardsCommand(), ct);
            return Results.Ok(result);
        })
        .WithName("ClaimCombatRewards");

        // GET /combat/zones — progression map around the current zone.
        group.MapGet("/zones", async (ISender sender, CancellationToken ct) =>
        {
            var result = await sender.Send(new GetZonesQuery(), ct);
            return Results.Ok(result);
        })
        .WithName("GetCombatZones");

        return app;
    }
}
