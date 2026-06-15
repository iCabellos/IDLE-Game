namespace IdleRPG.Domain.Enums;

/// <summary>How a stat modifier is applied during aggregation.</summary>
public enum ModifierType
{
    /// <summary>Added to the running flat total before percentages.</summary>
    Flat = 1,

    /// <summary>A fraction (0.10 = +10%) applied multiplicatively after flats.</summary>
    Percent = 2,
}
