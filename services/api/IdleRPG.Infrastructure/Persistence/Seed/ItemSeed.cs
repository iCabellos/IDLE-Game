using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Persistence.Seed;

/// <summary>
/// Seeds the global item catalogue: two early-game items per equippable slot
/// plus the four-piece Warrior "Ironclad Set". Idempotent — items are keyed by
/// deterministic ids and only inserted when missing.
/// </summary>
public static class ItemSeed
{
    public static readonly Guid IroncladSetId = SeedIds.From("set:ironclad");

    public static async Task SeedAsync(AppDbContext context, CancellationToken ct = default)
    {
        var items = BuildItems();

        var existingIds = await context.Items
            .Select(i => i.Id)
            .ToListAsync(ct);
        var existing = existingIds.ToHashSet();

        var toAdd = items.Where(i => !existing.Contains(i.Id)).ToList();
        if (toAdd.Count > 0)
        {
            await context.Items.AddRangeAsync(toAdd, ct);
            await context.SaveChangesAsync(ct);
        }
    }

    public static IReadOnlyList<Item> BuildItems()
    {
        var items = new List<Item>();

        // Two early-game items per equippable slot (Broken..Rare).
        var slots = new[]
        {
            ItemSlot.Head, ItemSlot.Chest, ItemSlot.Legs, ItemSlot.Feet, ItemSlot.Hands,
            ItemSlot.MainHand, ItemSlot.OffHand, ItemSlot.Ring, ItemSlot.Amulet,
        };

        var rarities = new[]
        {
            ItemRarity.Broken, ItemRarity.Worn, ItemRarity.Common, ItemRarity.Uncommon, ItemRarity.Rare,
        };

        var index = 0;
        foreach (var slot in slots)
        {
            for (var n = 0; n < 2; n++)
            {
                var rarity = rarities[index % rarities.Length];
                var name = $"{rarity} {SlotNoun(slot)} {n + 1}";
                items.Add(new Item
                {
                    Id = SeedIds.From($"item:{slot}:{n}"),
                    Name = name,
                    Description = $"An early-game {SlotNoun(slot).ToLowerInvariant()} of {rarity.ToString().ToLowerInvariant()} quality.",
                    Class = ClassForSlot(slot),
                    BaseRarity = rarity,
                    Slot = slot,
                    BaseStatsJson = BaseStatsForSlot(slot),
                    PassivesJson = "[]",
                    IsTradeable = ItemRarityData.IsTradeable(rarity),
                    SteamMarketHashName = $"IdleRPG_{slot}_{rarity}_{n + 1}",
                });
                index++;
            }
        }

        // Ironclad Set — 4 Warrior armor pieces.
        var setPieces = new (ItemSlot Slot, string Name)[]
        {
            (ItemSlot.Head, "Ironclad Helm"),
            (ItemSlot.Chest, "Ironclad Cuirass"),
            (ItemSlot.Legs, "Ironclad Greaves"),
            (ItemSlot.Feet, "Ironclad Sabatons"),
        };

        foreach (var (slot, name) in setPieces)
        {
            items.Add(new Item
            {
                Id = SeedIds.From($"item:ironclad:{slot}"),
                Name = name,
                Description = "Part of the Ironclad Set. 2-piece: +10% Defense. 4-piece: +25% Defense and the 'Unbreakable' passive.",
                Class = ItemClass.Armor,
                BaseRarity = ItemRarity.Superior,
                Slot = slot,
                CharacterRestriction = CharacterClass.Warrior,
                SetId = IroncladSetId,
                BaseStatsJson = "{\"Defense\":40}",
                PassivesJson = "[]",
                IsTradeable = true,
                SteamMarketHashName = $"IdleRPG_Ironclad_{slot}",
            });
        }

        return items;
    }

    private static ItemClass ClassForSlot(ItemSlot slot) => slot switch
    {
        ItemSlot.MainHand or ItemSlot.OffHand => ItemClass.Weapon,
        ItemSlot.Ring or ItemSlot.Amulet => ItemClass.Accessory,
        _ => ItemClass.Armor,
    };

    private static string SlotNoun(ItemSlot slot) => slot switch
    {
        ItemSlot.Head => "Helm",
        ItemSlot.Chest => "Chestplate",
        ItemSlot.Legs => "Leggings",
        ItemSlot.Feet => "Boots",
        ItemSlot.Hands => "Gauntlets",
        ItemSlot.MainHand => "Sword",
        ItemSlot.OffHand => "Shield",
        ItemSlot.Ring => "Ring",
        ItemSlot.Amulet => "Amulet",
        _ => slot.ToString(),
    };

    private static string BaseStatsForSlot(ItemSlot slot) => slot switch
    {
        ItemSlot.MainHand => "{\"Attack\":25}",
        ItemSlot.OffHand => "{\"Defense\":15,\"MaxHp\":40}",
        ItemSlot.Ring or ItemSlot.Amulet => "{\"CritRate\":0.03}",
        _ => "{\"Defense\":12,\"MaxHp\":30}",
    };
}
