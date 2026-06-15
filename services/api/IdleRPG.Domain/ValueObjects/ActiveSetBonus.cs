namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// A set bonus that is currently active because enough pieces are equipped.
/// </summary>
public sealed record ActiveSetBonus(
    Guid SetId,
    int PiecesEquipped,
    int PiecesRequired,
    IReadOnlyList<StatModifier> Modifiers,
    IReadOnlyList<Passive> Passives);
