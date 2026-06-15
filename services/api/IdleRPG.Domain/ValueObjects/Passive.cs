namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// A named passive ability carried by an item or granted by a set bonus. Its
/// gameplay effect is expressed as a list of stat modifiers.
/// </summary>
public sealed record Passive(string Name, IReadOnlyList<StatModifier> Modifiers)
{
    public Passive() : this(string.Empty, Array.Empty<StatModifier>())
    {
    }
}
