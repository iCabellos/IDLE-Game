using FluentAssertions;
using IdleRPG.Application.UseCases.Items.CompareItems;
using IdleRPG.Application.UseCases.Items.GetInventory;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;
using IdleRPG.Tests.Application;

namespace IdleRPG.Tests.Application.Items;

[Trait("Category", "ItemEngine")]
public sealed class InventoryAndCompareTests
{
    private readonly Guid _userId = Guid.NewGuid();
    private readonly InMemoryRepository<ItemInstance> _instances = new(i => i.Id);
    private readonly FakeCurrentUserService _currentUser;

    public InventoryAndCompareTests()
    {
        _currentUser = new FakeCurrentUserService { UserId = _userId, SteamId = "steam-1" };
    }

    private ItemInstance Add(ItemSlot slot, ItemRarity rarity, Guid? owner = null, string statsJson = "{}")
    {
        var def = new Item { Id = Guid.NewGuid(), Name = $"{rarity} {slot}", Slot = slot };
        var instance = new ItemInstance
        {
            Id = Guid.NewGuid(),
            ItemId = def.Id,
            OwnerId = owner ?? _userId,
            RolledRarity = rarity,
            RolledStatsJson = statsJson,
            Item = def,
            AcquiredAt = DateTimeOffset.UtcNow,
        };
        _instances.Items.Add(instance);
        return instance;
    }

    private GetInventoryHandler Inventory() => new(_currentUser, _instances);
    private CompareItemsHandler Compare() => new(_currentUser, _instances);

    [Fact]
    public async Task Inventory_returns_only_callers_items()
    {
        Add(ItemSlot.Head, ItemRarity.Rare);
        Add(ItemSlot.Chest, ItemRarity.Epic);
        Add(ItemSlot.Legs, ItemRarity.Rare, owner: Guid.NewGuid());

        var result = await Inventory().Handle(new GetInventoryQuery(), CancellationToken.None);

        result.Total.Should().Be(2);
    }

    [Fact]
    public async Task Inventory_filters_by_rarity()
    {
        Add(ItemSlot.Head, ItemRarity.Rare);
        Add(ItemSlot.Chest, ItemRarity.Epic);

        var result = await Inventory().Handle(
            new GetInventoryQuery(Rarity: ItemRarity.Epic), CancellationToken.None);

        result.Total.Should().Be(1);
        result.Items.Single().Rarity.Should().Be("Epic");
    }

    [Fact]
    public async Task Inventory_filters_by_slot()
    {
        Add(ItemSlot.Head, ItemRarity.Rare);
        Add(ItemSlot.Head, ItemRarity.Epic);
        Add(ItemSlot.Chest, ItemRarity.Rare);

        var result = await Inventory().Handle(
            new GetInventoryQuery(Slot: ItemSlot.Head), CancellationToken.None);

        result.Total.Should().Be(2);
        result.Items.Should().OnlyContain(i => i.Slot == "Head");
    }

    [Fact]
    public async Task Inventory_paginates()
    {
        for (var i = 0; i < 25; i++)
        {
            Add(ItemSlot.Ring, ItemRarity.Common);
        }

        var page1 = await Inventory().Handle(new GetInventoryQuery(1, 10), CancellationToken.None);
        var page3 = await Inventory().Handle(new GetInventoryQuery(3, 10), CancellationToken.None);

        page1.Items.Should().HaveCount(10);
        page1.Total.Should().Be(25);
        page3.Items.Should().HaveCount(5);
    }

    [Fact]
    public async Task Compare_picks_the_stronger_item()
    {
        var weak = Add(ItemSlot.MainHand, ItemRarity.Rare,
            statsJson: RolledItemData.Serialize(new RolledItemData(
                new Dictionary<string, float> { ["Attack"] = 100f }, Array.Empty<Passive>())));
        var strong = Add(ItemSlot.MainHand, ItemRarity.Epic,
            statsJson: RolledItemData.Serialize(new RolledItemData(
                new Dictionary<string, float> { ["Attack"] = 160f }, Array.Empty<Passive>())));

        var result = await Compare().Handle(
            new CompareItemsQuery(weak.Id, strong.Id), CancellationToken.None);

        result.BetterItem.Should().Be(strong.Id);
        result.Improvements.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Compare_reports_crit_advantage()
    {
        var plain = Add(ItemSlot.Ring, ItemRarity.Rare,
            statsJson: RolledItemData.Serialize(new RolledItemData(
                new Dictionary<string, float> { ["CritRate"] = 0.05f }, Array.Empty<Passive>())));
        var critty = Add(ItemSlot.Ring, ItemRarity.Epic,
            statsJson: RolledItemData.Serialize(new RolledItemData(
                new Dictionary<string, float> { ["CritRate"] = 0.20f }, Array.Empty<Passive>())));

        var result = await Compare().Handle(
            new CompareItemsQuery(plain.Id, critty.Id), CancellationToken.None);

        result.BetterItem.Should().Be(critty.Id);
        result.Improvements.Should().Contain("Better for crits");
    }

    [Fact]
    public async Task Compare_reports_equivalence_for_identical_items()
    {
        var stats = RolledItemData.Serialize(new RolledItemData(
            new Dictionary<string, float> { ["Attack"] = 100f }, Array.Empty<Passive>()));
        var a = Add(ItemSlot.MainHand, ItemRarity.Rare, statsJson: stats);
        var b = Add(ItemSlot.MainHand, ItemRarity.Rare, statsJson: stats);

        var result = await Compare().Handle(new CompareItemsQuery(a.Id, b.Id), CancellationToken.None);

        result.BetterItem.Should().BeNull();
    }
}
