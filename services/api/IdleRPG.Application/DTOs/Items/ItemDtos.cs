namespace IdleRPG.Application.DTOs.Items;

/// <summary>A single inventory entry (instance + definition metadata).</summary>
public record InventoryItemDto
{
    public Guid InstanceId { get; init; }
    public Guid ItemId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Rarity { get; init; } = string.Empty;
    public string Slot { get; init; } = string.Empty;
    public string ItemClass { get; init; } = string.Empty;
    public bool IsEquipped { get; init; }
    public Guid? EquippedToCharacterId { get; init; }
    public bool IsTradeable { get; init; }
    public string RolledStatsJson { get; init; } = "{}";
}

/// <summary>A page of results plus paging metadata.</summary>
public record PagedResult<T>
{
    public IReadOnlyList<T> Items { get; init; } = Array.Empty<T>();
    public int Page { get; init; }
    public int Size { get; init; }
    public int Total { get; init; }
}

/// <summary>A character's identity plus aggregated, human-readable stats.</summary>
public record CharacterSummaryDto
{
    public Guid CharacterId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Class { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public int Level { get; init; }
    public IReadOnlyDictionary<string, float> Stats { get; init; } =
        new Dictionary<string, float>();
    public IReadOnlyList<string> ActiveSetBonuses { get; init; } = Array.Empty<string>();
}

/// <summary>
/// Descriptive (non-numeric) comparison between two item instances, e.g.
/// { BetterItem = "id1", Improvements = ["Attack +23%", "Better for crits"] }.
/// </summary>
public record ItemComparisonDto
{
    public Guid? BetterItem { get; init; }
    public IReadOnlyList<string> Improvements { get; init; } = Array.Empty<string>();
}
