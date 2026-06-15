using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// A single modification to a named <see cref="CharacterStats"/> property, e.g.
/// ("Defense", 0.10, Percent) for "+10% Defense".
/// </summary>
public sealed record StatModifier(string Stat, float Value, ModifierType Type = ModifierType.Flat);
