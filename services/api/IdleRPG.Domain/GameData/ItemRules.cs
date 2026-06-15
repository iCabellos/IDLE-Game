using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.GameData;

/// <summary>Static gameplay rules for items: passive slot counts by rarity.</summary>
public static class ItemRules
{
    /// <summary>
    /// Number of passive slots a rolled item gets, by rarity tier:
    /// Broken-Superior: 0, Epic-Mythic: 1, Ancient-Relic: 2,
    /// Legendary-Ascended: 3, Divine-Celestial: 4, Primordial and above: 5.
    /// </summary>
    public static int PassiveSlots(ItemRarity rarity) => rarity switch
    {
        <= ItemRarity.Superior => 0,
        <= ItemRarity.Mythic => 1,
        <= ItemRarity.Relic => 2,
        <= ItemRarity.Ascended => 3,
        <= ItemRarity.Celestial => 4,
        _ => 5,
    };
}
