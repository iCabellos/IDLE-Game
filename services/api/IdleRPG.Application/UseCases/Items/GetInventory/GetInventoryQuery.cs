using IdleRPG.Application.DTOs.Items;
using IdleRPG.Domain.Enums;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.GetInventory;

/// <summary>A paginated, optionally filtered view of the caller's inventory.</summary>
public sealed record GetInventoryQuery(
    int Page = 1,
    int Size = 20,
    ItemRarity? Rarity = null,
    ItemSlot? Slot = null)
    : IRequest<PagedResult<InventoryItemDto>>;
