using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.DTOs.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.GetInventory;

public sealed class GetInventoryHandler
    : IRequestHandler<GetInventoryQuery, PagedResult<InventoryItemDto>>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<ItemInstance> _instances;

    public GetInventoryHandler(ICurrentUserService currentUser, IRepository<ItemInstance> instances)
    {
        _currentUser = currentUser;
        _instances = instances;
    }

    public async Task<PagedResult<InventoryItemDto>> Handle(
        GetInventoryQuery request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        var page = Math.Max(request.Page, 1);
        var size = Math.Clamp(request.Size, 1, 100);

        var all = await _instances.GetAllAsync(new ItemInstancesByOwnerSpec(userId), ct);

        IEnumerable<ItemInstance> filtered = all;
        if (request.Rarity is { } rarity)
        {
            filtered = filtered.Where(i => i.RolledRarity == rarity);
        }
        if (request.Slot is { } slot)
        {
            filtered = filtered.Where(i => i.Item is not null && i.Item.Slot == slot);
        }

        var list = filtered.ToList();
        var pageItems = list
            .Skip((page - 1) * size)
            .Take(size)
            .Select(ToDto)
            .ToList();

        return new PagedResult<InventoryItemDto>
        {
            Items = pageItems,
            Page = page,
            Size = size,
            Total = list.Count,
        };
    }

    private static InventoryItemDto ToDto(ItemInstance instance)
    {
        var def = instance.Item;
        return new InventoryItemDto
        {
            InstanceId = instance.Id,
            ItemId = instance.ItemId,
            Name = def?.Name ?? string.Empty,
            Rarity = instance.RolledRarity.ToString(),
            Slot = def?.Slot.ToString() ?? string.Empty,
            ItemClass = def?.Class.ToString() ?? string.Empty,
            IsEquipped = instance.EquippedToCharacterId is not null,
            EquippedToCharacterId = instance.EquippedToCharacterId,
            IsTradeable = ItemRarityData.IsTradeable(instance.RolledRarity),
            RolledStatsJson = instance.RolledStatsJson,
        };
    }
}
