using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;

namespace IdleRPG.API.Endpoints;

/// <summary>
/// Public, read-only catalog of seeded item <b>definitions</b> (not per-player
/// instances). Lets a client render real game data without an authenticated
/// Steam session — consumed by the early Android preview. Exposes no user data
/// and no raw character stats, so it stays within the "no raw numbers" UX rule.
/// </summary>
public static class CatalogEndpoints
{
    public static IEndpointRouteBuilder MapCatalogEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/catalog").WithTags("Catalog");

        // GET /catalog/items — every seeded item definition, ordered by rarity.
        group.MapGet("/items", async (IRepository<Item> items, CancellationToken ct) =>
        {
            var all = await items.GetAllAsync(null, ct);
            var dtos = all
                .OrderBy(i => (int)i.BaseRarity)
                .ThenBy(i => i.Name)
                .Select(i => new CatalogItemDto(
                    i.Id,
                    i.Name,
                    i.Description,
                    i.Class.ToString(),
                    i.Slot.ToString(),
                    i.BaseRarity.ToString(),
                    (int)i.BaseRarity,
                    i.SetId,
                    i.IsTradeable))
                .ToList();

            return Results.Ok(dtos);
        })
        .WithName("GetCatalogItems")
        .AllowAnonymous();

        return app;
    }
}

/// <summary>Read-only projection of an <see cref="Item"/> definition for clients.</summary>
public record CatalogItemDto(
    Guid Id,
    string Name,
    string Description,
    string ItemClass,
    string Slot,
    string Rarity,
    int RarityTier,
    Guid? SetId,
    bool IsTradeable);
