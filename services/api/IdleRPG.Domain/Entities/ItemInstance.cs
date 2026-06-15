using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.Entities;

/// <summary>
/// A concrete, owned instance of an <see cref="Item"/> definition with its
/// own rolled rarity and stats, optionally equipped to a character and/or
/// mirrored in the owner's Steam inventory.
/// </summary>
public class ItemInstance
{
    public Guid Id { get; set; }
    public Guid ItemId { get; set; }
    public Guid OwnerId { get; set; }
    public string SteamInventoryId { get; set; } = string.Empty;
    public ItemRarity RolledRarity { get; set; }
    public string RolledStatsJson { get; set; } = "{}";
    public DateTimeOffset AcquiredAt { get; set; }

    public Guid? EquippedToCharacterId { get; set; }
    public ItemSlot? EquippedSlot { get; set; }

    public bool IsListedOnMarket { get; set; }
    public DateTimeOffset? LastSteamValidation { get; set; }

    // Navigation
    public Item? Item { get; set; }
    public User? Owner { get; set; }
    public Character? EquippedToCharacter { get; set; }
}
