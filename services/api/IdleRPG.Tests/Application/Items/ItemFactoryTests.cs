using System.Text.Json;
using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.ValueObjects;
using IdleRPG.Infrastructure.Items;
using IdleRPG.Tests.Application;

namespace IdleRPG.Tests.Application.Items;

[Trait("Category", "ItemEngine")]
public sealed class ItemFactoryTests
{
    private const float BaseStat = 100f;

    private static (ItemFactory Factory, Guid DefId) BuildFactory(
        string baseStatsJson = "{\"Attack\":100}",
        string passivesJson = "[]",
        Random? rng = null)
    {
        var repo = new InMemoryRepository<Item>(i => i.Id);
        var defId = Guid.NewGuid();
        repo.Items.Add(new Item
        {
            Id = defId,
            Name = "Test Blade",
            Slot = ItemSlot.MainHand,
            Class = ItemClass.Weapon,
            BaseStatsJson = baseStatsJson,
            PassivesJson = passivesJson,
        });
        return (new ItemFactory(repo, rng ?? new Random(12345)), defId);
    }

    private static string PoolOf(int count)
    {
        var pool = Enumerable.Range(1, count)
            .Select(i => new Passive($"Passive{i}", Array.Empty<StatModifier>()))
            .ToList();
        return JsonSerializer.Serialize(pool);
    }

    public static IEnumerable<object[]> RolledRarities() =>
        new[]
        {
            ItemRarity.Broken, ItemRarity.Worn, ItemRarity.Common, ItemRarity.Uncommon,
            ItemRarity.Rare, ItemRarity.Superior, ItemRarity.Epic, ItemRarity.Mythic,
            ItemRarity.Ancient, ItemRarity.Relic, ItemRarity.Legendary, ItemRarity.Ascended,
            ItemRarity.Divine, ItemRarity.Celestial, ItemRarity.Primordial, ItemRarity.Transcendent,
        }.Select(r => new object[] { r });

    public static IEnumerable<object[]> FixedRarities() =>
        new[]
        {
            ItemRarity.Unique, ItemRarity.Seasonal, ItemRarity.Founder,
            ItemRarity.EventLimited, ItemRarity.OneOfOne,
        }.Select(r => new object[] { r });

    public static IEnumerable<object[]> AllRarities() =>
        Enum.GetValues<ItemRarity>().Select(r => new object[] { r });

    [Theory]
    [MemberData(nameof(RolledRarities))]
    public async Task RolledStat_is_within_rarity_range(ItemRarity rarity)
    {
        var (factory, defId) = BuildFactory(rng: new Random((int)rarity * 7 + 1));
        var mult = ItemRarityData.Multiplier(rarity)!.Value;
        var min = BaseStat * mult * 0.85f;
        var max = BaseStat * mult * 1.15f;

        for (var i = 0; i < 200; i++)
        {
            var instance = await factory.CreateAsync(defId, rarity, Guid.NewGuid(), "steam-1");
            var rolled = RolledItemData.Parse(instance.RolledStatsJson).Stats["Attack"];
            rolled.Should().BeInRange(min - 0.01f, max + 0.01f);
        }
    }

    [Theory]
    [MemberData(nameof(RolledRarities))]
    public void RollStat_respects_clamp_bounds(ItemRarity rarity)
    {
        var (factory, _) = BuildFactory();
        var mult = ItemRarityData.Multiplier(rarity)!.Value;

        for (var i = 0; i < 500; i++)
        {
            var v = factory.RollStat(BaseStat, mult);
            v.Should().BeInRange(BaseStat * mult * 0.85f - 0.01f, BaseStat * mult * 1.15f + 0.01f);
        }
    }

    [Theory]
    [MemberData(nameof(AllRarities))]
    public async Task Passive_count_matches_rarity_slots(ItemRarity rarity)
    {
        var (factory, defId) = BuildFactory(passivesJson: PoolOf(6), rng: new Random((int)rarity + 99));
        var instance = await factory.CreateAsync(defId, rarity, Guid.NewGuid(), "steam-1");

        var passives = RolledItemData.Parse(instance.RolledStatsJson).Passives;
        passives.Count.Should().Be(ItemRules.PassiveSlots(rarity));
    }

    [Theory]
    [MemberData(nameof(FixedRarities))]
    public async Task Fixed_rarity_stats_are_not_rolled(ItemRarity rarity)
    {
        var (factory, defId) = BuildFactory(baseStatsJson: "{\"Attack\":100,\"Defense\":42}");
        var instance = await factory.CreateAsync(defId, rarity, Guid.NewGuid(), "steam-1");

        var stats = RolledItemData.Parse(instance.RolledStatsJson).Stats;
        stats["Attack"].Should().Be(100f);
        stats["Defense"].Should().Be(42f);
    }

    [Theory]
    [MemberData(nameof(FixedRarities))]
    public void Fixed_rarities_have_no_multiplier(ItemRarity rarity)
    {
        ItemRarityData.HasFixedStats(rarity).Should().BeTrue();
        ItemRarityData.Multiplier(rarity).Should().BeNull();
    }

    [Fact]
    public async Task Passive_count_is_capped_by_pool_size()
    {
        // Transcendent grants 5 slots but the pool only has 2 passives.
        var (factory, defId) = BuildFactory(passivesJson: PoolOf(2));
        var instance = await factory.CreateAsync(defId, ItemRarity.Transcendent, Guid.NewGuid(), "steam-1");

        RolledItemData.Parse(instance.RolledStatsJson).Passives.Count.Should().Be(2);
    }

    [Fact]
    public async Task CreateAsync_sets_ownership_and_identity_fields()
    {
        var (factory, defId) = BuildFactory();
        var ownerId = Guid.NewGuid();

        var instance = await factory.CreateAsync(defId, ItemRarity.Rare, ownerId, "steam-77");

        instance.Id.Should().NotBeEmpty();
        instance.ItemId.Should().Be(defId);
        instance.OwnerId.Should().Be(ownerId);
        instance.SteamInventoryId.Should().Be("steam-77");
        instance.RolledRarity.Should().Be(ItemRarity.Rare);
    }

    [Fact]
    public async Task CreateAsync_throws_when_definition_missing()
    {
        var (factory, _) = BuildFactory();
        var act = () => factory.CreateAsync(Guid.NewGuid(), ItemRarity.Rare, Guid.NewGuid(), "steam-1");
        await act.Should().ThrowAsync<InvalidOperationException>();
    }
}
