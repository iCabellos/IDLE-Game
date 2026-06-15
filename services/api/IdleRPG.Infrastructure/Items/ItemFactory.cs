using System.Text.Json;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Infrastructure.Items;

/// <summary>
/// Creates owned <see cref="ItemInstance"/>s from a global <see cref="Item"/>
/// definition, rolling stats with a Box-Muller normal distribution scaled by
/// the rarity multiplier and selecting passives from the definition's pool.
/// </summary>
public sealed class ItemFactory : IItemFactory
{
    private readonly IRepository<Item> _items;
    private readonly Random _rng;

    public ItemFactory(IRepository<Item> items) : this(items, Random.Shared)
    {
    }

    /// <summary>Test-friendly constructor accepting a seeded RNG.</summary>
    public ItemFactory(IRepository<Item> items, Random rng)
    {
        _items = items;
        _rng = rng;
    }

    public async Task<ItemInstance> CreateAsync(
        Guid itemDefId,
        ItemRarity rarity,
        Guid ownerId,
        string steamInventoryId,
        CancellationToken ct = default)
    {
        var definition = await _items.GetByIdAsync(itemDefId, ct)
            ?? throw new InvalidOperationException($"Item definition {itemDefId} not found.");

        var baseStats = ParseStats(definition.BaseStatsJson);
        var rolledStats = RollStats(baseStats, rarity);
        var passives = GeneratePassives(definition, rarity);

        var rolled = new RolledItemData(rolledStats, passives);
        var now = DateTimeOffset.UtcNow;

        return new ItemInstance
        {
            Id = Guid.NewGuid(),
            ItemId = definition.Id,
            OwnerId = ownerId,
            SteamInventoryId = steamInventoryId,
            RolledRarity = rarity,
            RolledStatsJson = RolledItemData.Serialize(rolled),
            AcquiredAt = now,
            UpdatedAt = now,
        };
    }

    /// <summary>
    /// Rolls every base stat. Fixed-stat rarities (Unique and above) are copied
    /// verbatim; all others scale by the rarity multiplier and a Box-Muller roll.
    /// </summary>
    private IReadOnlyDictionary<string, float> RollStats(
        IReadOnlyDictionary<string, float> baseStats, ItemRarity rarity)
    {
        if (ItemRarityData.HasFixedStats(rarity))
        {
            return new Dictionary<string, float>(baseStats);
        }

        var mult = ItemRarityData.Multiplier(rarity)!.Value;
        var result = new Dictionary<string, float>(baseStats.Count);
        foreach (var (stat, value) in baseStats)
        {
            result[stat] = RollStat(value, mult);
        }

        return result;
    }

    /// <summary>
    /// Box-Muller roll: returns <c>baseStat * mult * roll</c> where
    /// <c>roll</c> is a normal-distributed value clamped to [0.85, 1.15].
    /// </summary>
    public float RollStat(float baseStat, float mult)
    {
        double u1 = 1.0 - _rng.NextDouble();
        double u2 = 1.0 - _rng.NextDouble();
        double normal = Math.Sqrt(-2.0 * Math.Log(u1)) * Math.Sin(2.0 * Math.PI * u2);
        float roll = Math.Clamp(1f + (float)(normal * 0.15), 0.85f, 1.15f);
        return baseStat * mult * roll;
    }

    /// <summary>
    /// Selects up to <see cref="ItemRules.PassiveSlots"/> passives at random from
    /// the definition's pool (without replacement).
    /// </summary>
    private IReadOnlyList<Passive> GeneratePassives(Item definition, ItemRarity rarity)
    {
        var slots = ItemRules.PassiveSlots(rarity);
        if (slots == 0)
        {
            return Array.Empty<Passive>();
        }

        var pool = ParsePassives(definition.PassivesJson);
        if (pool.Count == 0)
        {
            return Array.Empty<Passive>();
        }

        return pool
            .OrderBy(_ => _rng.Next())
            .Take(slots)
            .ToList();
    }

    private static IReadOnlyDictionary<string, float> ParseStats(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new Dictionary<string, float>();
        }

        return JsonSerializer.Deserialize<Dictionary<string, float>>(json)
               ?? new Dictionary<string, float>();
    }

    private static IReadOnlyList<Passive> ParsePassives(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return Array.Empty<Passive>();
        }

        return JsonSerializer.Deserialize<List<Passive>>(json)
               ?? new List<Passive>();
    }
}
