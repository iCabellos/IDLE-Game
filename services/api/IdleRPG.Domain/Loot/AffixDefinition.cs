using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.Loot;

/// <summary>
/// A rollable affix, ARPG-style. Prefixes read as adjectives ("Savage"),
/// suffixes as "of ..." phrases ("of Slaughter"); together with the base
/// name they compose Diablo-style item names.
///
/// Rolled value = (Base + PerLevel × itemLevel) × roll[0.85, 1.15], with
/// <see cref="ModifierType.Percent"/> affixes ignoring the level term.
/// </summary>
public sealed record AffixDefinition
{
    public required string Name { get; init; }
    public required bool IsPrefix { get; init; }

    /// <summary>A nameof() key into <see cref="ValueObjects.CharacterStats"/>.</summary>
    public required string Stat { get; init; }

    public required ModifierType Type { get; init; }
    public required float Base { get; init; }
    public float PerLevel { get; init; }

    /// <summary>Player-facing description — descriptive text, never numbers.</summary>
    public required string Description { get; init; }
}
