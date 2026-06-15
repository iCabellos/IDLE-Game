namespace IdleRPG.Domain.Enums;

/// <summary>
/// Reference data for each <see cref="ItemRarity"/> tier: stat multiplier,
/// base drop percentage and tradeability. Tiers 17-21 use fixed (designer
/// authored) stats so their multiplier is recorded as <c>null</c>.
/// </summary>
public sealed record RarityInfo(float? Multiplier, double DropPercent, bool Tradeable);

public static class ItemRarityData
{
    private static readonly IReadOnlyDictionary<ItemRarity, RarityInfo> Table =
        new Dictionary<ItemRarity, RarityInfo>
        {
            [ItemRarity.Broken] = new(0.30f, 30.00, true),
            [ItemRarity.Worn] = new(0.50f, 25.00, true),
            [ItemRarity.Common] = new(0.70f, 20.00, true),
            [ItemRarity.Uncommon] = new(0.90f, 12.00, true),
            [ItemRarity.Rare] = new(1.10f, 6.00, true),
            [ItemRarity.Superior] = new(1.30f, 3.00, true),
            [ItemRarity.Epic] = new(1.60f, 1.50, true),
            [ItemRarity.Mythic] = new(2.00f, 0.80, true),
            [ItemRarity.Ancient] = new(2.50f, 0.40, true),
            [ItemRarity.Relic] = new(3.00f, 0.15, true),
            [ItemRarity.Legendary] = new(4.00f, 0.05, true),
            [ItemRarity.Ascended] = new(5.50f, 0.02, true),
            [ItemRarity.Divine] = new(7.00f, 0.008, true),
            [ItemRarity.Celestial] = new(9.00f, 0.003, true),
            [ItemRarity.Primordial] = new(12.0f, 0.001, true),
            [ItemRarity.Transcendent] = new(16.0f, 0.0004, true),
            [ItemRarity.Unique] = new(null, 0.0001, false),
            [ItemRarity.Seasonal] = new(null, 0.0, false),       // event-driven
            [ItemRarity.Founder] = new(null, 0.0, false),
            [ItemRarity.EventLimited] = new(null, 0.0, false),   // event-driven
            [ItemRarity.OneOfOne] = new(null, 0.0, false)
        };

    public static RarityInfo Get(ItemRarity rarity) => Table[rarity];

    public static float? Multiplier(ItemRarity rarity) => Table[rarity].Multiplier;

    public static double DropPercent(ItemRarity rarity) => Table[rarity].DropPercent;

    public static bool IsTradeable(ItemRarity rarity) => Table[rarity].Tradeable;

    /// <summary>True when the tier uses fixed (non-rolled) stats (Unique and above).</summary>
    public static bool HasFixedStats(ItemRarity rarity) => Table[rarity].Multiplier is null;
}
