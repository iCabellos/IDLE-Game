using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.Entities;

/// <summary>
/// A global item definition (a template), not a per-player instance.
/// Instances are represented by <see cref="ItemInstance"/>.
/// </summary>
public class Item
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public ItemClass Class { get; set; }
    public ItemRarity BaseRarity { get; set; }
    public ItemSlot Slot { get; set; }

    /// <summary>Optional restriction limiting the item to a single class.</summary>
    public CharacterClass? CharacterRestriction { get; set; }

    /// <summary>Set membership; null for non-set items.</summary>
    public Guid? SetId { get; set; }

    public string BaseStatsJson { get; set; } = "{}";
    public string PassivesJson { get; set; } = "[]";

    public bool IsUnique { get; set; }
    public bool IsSeasonal { get; set; }

    public string? SteamMarketHashName { get; set; }
    public bool IsTradeable { get; set; } = true;
}
