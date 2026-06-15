namespace IdleRPG.Domain.Enums;

/// <summary>
/// 21 rarity tiers. Stat multipliers, drop rates and tradeability are
/// defined in <see cref="IdleRPG.Domain.Enums.ItemRarityData"/>.
/// </summary>
public enum ItemRarity
{
    Broken = 1,       // mult:0.30 drop%:30.00 tradeable:true
    Worn = 2,         // mult:0.50 drop%:25.00 tradeable:true
    Common = 3,       // mult:0.70 drop%:20.00 tradeable:true
    Uncommon = 4,     // mult:0.90 drop%:12.00 tradeable:true
    Rare = 5,         // mult:1.10 drop%: 6.00 tradeable:true
    Superior = 6,     // mult:1.30 drop%: 3.00 tradeable:true
    Epic = 7,         // mult:1.60 drop%: 1.50 tradeable:true
    Mythic = 8,       // mult:2.00 drop%: 0.80 tradeable:true
    Ancient = 9,      // mult:2.50 drop%: 0.40 tradeable:true
    Relic = 10,       // mult:3.00 drop%: 0.15 tradeable:true
    Legendary = 11,   // mult:4.00 drop%: 0.05 tradeable:true
    Ascended = 12,    // mult:5.50 drop%: 0.02 tradeable:true
    Divine = 13,      // mult:7.00 drop%:0.008 tradeable:true
    Celestial = 14,   // mult:9.00 drop%:0.003 tradeable:true
    Primordial = 15,  // mult:12.0 drop%:0.001 tradeable:true
    Transcendent = 16,// mult:16.0 drop%:0.0004 tradeable:true
    Unique = 17,      // mult:FIXED drop%:0.0001 tradeable:false
    Seasonal = 18,    // mult:FIXED drop%:event tradeable:false
    Founder = 19,     // mult:FIXED drop%:0 tradeable:false
    EventLimited = 20,// mult:FIXED drop%:event tradeable:false
    OneOfOne = 21     // mult:FIXED drop%:0 tradeable:false
}
