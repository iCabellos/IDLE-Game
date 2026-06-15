using IdleRPG.Application.Common;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;

namespace IdleRPG.Application.Interfaces.Items;

/// <summary>Validates item ownership and equip compatibility.</summary>
public interface IItemValidator
{
    Task<ValidationResult> ValidateSteamOwnershipAsync(
        string steamId, string steamInventoryId, CancellationToken ct = default);

    ValidationResult ValidateSlotCompatibility(Character character, Item item, ItemSlot slot);

    ValidationResult ValidateCharacterRestriction(Character character, Item item);
}
