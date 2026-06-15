using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;

namespace IdleRPG.Application.Interfaces.Items;

/// <summary>Creates owned item instances from a definition with rolled stats.</summary>
public interface IItemFactory
{
    Task<ItemInstance> CreateAsync(
        Guid itemDefId,
        ItemRarity rarity,
        Guid ownerId,
        string steamInventoryId,
        CancellationToken ct = default);
}
