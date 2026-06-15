using IdleRPG.Application.UseCases.Items.CompareItems;
using IdleRPG.Application.UseCases.Items.EquipItem;
using IdleRPG.Application.UseCases.Items.GetInventory;
using IdleRPG.Application.UseCases.Items.UnequipItem;
using IdleRPG.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace IdleRPG.API.Endpoints;

/// <summary>Item inventory and equipment endpoints.</summary>
public static class ItemEndpoints
{
    public static IEndpointRouteBuilder MapItemEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/items").WithTags("Items").RequireAuthorization();

        // GET /items/inventory?page&size&rarity&slot
        group.MapGet("/inventory", async (
            ISender sender,
            CancellationToken ct,
            [FromQuery] int page = 1,
            [FromQuery] int size = 20,
            [FromQuery] ItemRarity? rarity = null,
            [FromQuery] ItemSlot? slot = null) =>
        {
            var result = await sender.Send(new GetInventoryQuery(page, size, rarity, slot), ct);
            return Results.Ok(result);
        })
        .WithName("GetInventory");

        // POST /items/equip
        group.MapPost("/equip", async (
            [FromBody] EquipItemRequest request,
            ISender sender,
            CancellationToken ct) =>
        {
            var result = await sender.Send(
                new EquipItemCommand(request.CharacterId, request.ItemInstanceId, request.TargetSlot), ct);
            return Results.Ok(result);
        })
        .WithName("EquipItem");

        // POST /items/unequip
        group.MapPost("/unequip", async (
            [FromBody] UnequipItemRequest request,
            ISender sender,
            CancellationToken ct) =>
        {
            var result = await sender.Send(
                new UnequipItemCommand(request.CharacterId, request.ItemInstanceId), ct);
            return Results.Ok(result);
        })
        .WithName("UnequipItem");

        // GET /items/compare/{id1}/{id2}
        group.MapGet("/compare/{id1:guid}/{id2:guid}", async (
            Guid id1,
            Guid id2,
            ISender sender,
            CancellationToken ct) =>
        {
            var result = await sender.Send(new CompareItemsQuery(id1, id2), ct);
            return Results.Ok(result);
        })
        .WithName("CompareItems");

        return app;
    }
}

public record EquipItemRequest(Guid CharacterId, Guid ItemInstanceId, ItemSlot TargetSlot);

public record UnequipItemRequest(Guid CharacterId, Guid ItemInstanceId);
