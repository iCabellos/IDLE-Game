using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.Loot;

/// <summary>
/// A generated item drop, ARPG-style: named, themed by archetype and
/// carrying rolled affixes. Lives in the idle state until the Steam
/// integration (F5) materialises it as a real inventory item — the rolled
/// modifiers slot directly into <see cref="RolledItemData"/> at that point.
/// </summary>
public sealed record LootDrop
{
    /// <summary>Diablo-style composed name, e.g. "Savage Signet of Slaughter".</summary>
    public required string Name { get; init; }

    public required ItemRarity Rarity { get; init; }
    public required ItemArchetype Archetype { get; init; }

    /// <summary>Equipment slot name (matches the ItemSlot enum names).</summary>
    public required string Slot { get; init; }

    /// <summary>Enemy level the item dropped at; scales flat affix values.</summary>
    public required int ItemLevel { get; init; }

    /// <summary>Affix names in roll order ("Savage", "of Slaughter", ...).</summary>
    public IReadOnlyList<string> AffixNames { get; init; } = Array.Empty<string>();

    /// <summary>Player-facing affix descriptions — text only, never numbers.</summary>
    public IReadOnlyList<string> AffixDescriptions { get; init; } = Array.Empty<string>();

    /// <summary>Rolled stat values (backend-internal; not surfaced raw to UI).</summary>
    public IReadOnlyList<StatModifier> Modifiers { get; init; } = Array.Empty<StatModifier>();
}
