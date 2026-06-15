using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.ValueObjects;
using IdleRPG.Infrastructure.Items;

namespace IdleRPG.Tests.Application.Items;

[Trait("Category", "ItemEngine")]
public sealed class StatAggregatorTests
{
    private static readonly StatAggregator Aggregator = new();

    private static Character Char(CharacterClass cls = CharacterClass.Warrior, int level = 1) =>
        new() { Id = Guid.NewGuid(), Class = cls, Level = level, Name = "Hero", Role = CharacterRole.Tank };

    private static ItemInstance ItemWithStats(IReadOnlyDictionary<string, float> stats, IReadOnlyList<Passive>? passives = null)
        => new()
        {
            Id = Guid.NewGuid(),
            RolledStatsJson = RolledItemData.Serialize(
                new RolledItemData(stats, passives ?? Array.Empty<Passive>())),
        };

    private static ActiveSetBonus Bonus(params StatModifier[] mods)
        => new(Guid.NewGuid(), 4, 2, mods, Array.Empty<Passive>());

    [Theory]
    [InlineData(1)]
    [InlineData(10)]
    [InlineData(100)]
    public void Base_defense_scales_with_level(int level)
    {
        var stats = Aggregator.Aggregate(
            Char(level: level),
            Array.Empty<ItemInstance>(),
            Array.Empty<Item>(),
            Array.Empty<ActiveSetBonus>());

        // Warrior defense growth is 6.0 per level.
        stats.Defense.Should().BeApproximately(6.0f * level, 0.001f);
    }

    [Fact]
    public void Item_flat_stats_are_added()
    {
        var item = ItemWithStats(new Dictionary<string, float> { ["Defense"] = 40f });

        var stats = Aggregator.Aggregate(
            Char(), new[] { item }, Array.Empty<Item>(), Array.Empty<ActiveSetBonus>());

        // Warrior level 1 base defense (6) + item (40).
        stats.Defense.Should().BeApproximately(46f, 0.001f);
    }

    [Fact]
    public void Set_bonus_percent_is_applied_to_total()
    {
        var item = ItemWithStats(new Dictionary<string, float> { ["Defense"] = 40f });
        var bonus = Bonus(new StatModifier("Defense", 0.10f, ModifierType.Percent));

        var stats = Aggregator.Aggregate(
            Char(), new[] { item }, Array.Empty<Item>(), new[] { bonus });

        // (6 + 40) * 1.10 = 50.6
        stats.Defense.Should().BeApproximately(50.6f, 0.01f);
    }

    [Fact]
    public void Multiple_set_bonus_percents_are_summed()
    {
        var item = ItemWithStats(new Dictionary<string, float> { ["Defense"] = 40f });
        var twoPiece = Bonus(new StatModifier("Defense", 0.10f, ModifierType.Percent));
        var fourPiece = Bonus(new StatModifier("Defense", 0.25f, ModifierType.Percent));

        var stats = Aggregator.Aggregate(
            Char(), new[] { item }, Array.Empty<Item>(), new[] { twoPiece, fourPiece });

        // (6 + 40) * (1 + 0.10 + 0.25) = 46 * 1.35 = 62.1
        stats.Defense.Should().BeApproximately(62.1f, 0.01f);
    }

    [Fact]
    public void Set_bonus_flat_modifier_is_added()
    {
        var bonus = Bonus(new StatModifier("Attack", 15f, ModifierType.Flat));

        var stats = Aggregator.Aggregate(
            Char(), Array.Empty<ItemInstance>(), Array.Empty<Item>(), new[] { bonus });

        // Warrior level 1 attack growth (5) + flat (15).
        stats.Attack.Should().BeApproximately(20f, 0.001f);
    }

    [Fact]
    public void Crit_rate_is_capped_at_0_75()
    {
        var bonus = Bonus(new StatModifier("CritRate", 1.0f, ModifierType.Flat));

        var stats = Aggregator.Aggregate(
            Char(), Array.Empty<ItemInstance>(), Array.Empty<Item>(), new[] { bonus });

        stats.CritRate.Should().Be(CharacterStats.CritRateCap);
        stats.CritRate.Should().Be(0.75f);
    }

    [Fact]
    public void Crit_multiplier_is_capped_at_5()
    {
        var bonus = Bonus(new StatModifier("CritMultiplier", 10f, ModifierType.Flat));

        var stats = Aggregator.Aggregate(
            Char(), Array.Empty<ItemInstance>(), Array.Empty<Item>(), new[] { bonus });

        stats.CritMultiplier.Should().Be(CharacterStats.CritMultiplierCap);
        stats.CritMultiplier.Should().Be(5.0f);
    }

    [Fact]
    public void Crit_multiplier_has_a_floor_of_1_5()
    {
        var stats = Aggregator.Aggregate(
            Char(), Array.Empty<ItemInstance>(), Array.Empty<Item>(), Array.Empty<ActiveSetBonus>());

        stats.CritMultiplier.Should().BeGreaterThanOrEqualTo(1.5f);
    }

    [Theory]
    [InlineData("ResistPhysical")]
    [InlineData("ResistFire")]
    [InlineData("ResistIce")]
    [InlineData("ResistLightning")]
    [InlineData("ResistPoison")]
    public void Resistances_are_capped_at_0_90(string resistStat)
    {
        var bonus = Bonus(new StatModifier(resistStat, 1.0f, ModifierType.Flat));

        var stats = Aggregator.Aggregate(
            Char(), Array.Empty<ItemInstance>(), Array.Empty<Item>(), new[] { bonus });

        var value = stats.ToDictionary()[resistStat];
        value.Should().Be(CharacterStats.ResistCap);
        value.Should().Be(0.90f);
    }

    [Fact]
    public void Item_passive_percent_is_applied()
    {
        var item = ItemWithStats(
            new Dictionary<string, float> { ["Attack"] = 100f },
            new[] { new Passive("Sharp", new[] { new StatModifier("Attack", 0.20f, ModifierType.Percent) }) });

        var stats = Aggregator.Aggregate(
            Char(), new[] { item }, Array.Empty<Item>(), Array.Empty<ActiveSetBonus>());

        // (5 base + 100 item) * 1.20 = 126
        stats.Attack.Should().BeApproximately(126f, 0.01f);
    }

    [Fact]
    public void Set_bonus_passive_modifiers_are_applied()
    {
        var bonus = new ActiveSetBonus(
            Guid.NewGuid(), 4, 4,
            Array.Empty<StatModifier>(),
            new[] { new Passive("Unbreakable", new[] { new StatModifier("MaxHp", 0.15f, ModifierType.Percent) }) });

        var stats = Aggregator.Aggregate(
            Char(level: 10), Array.Empty<ItemInstance>(), Array.Empty<Item>(), new[] { bonus });

        // Warrior MaxHp growth 55/level -> 550 at lvl 10, * 1.15 = 632.5
        stats.MaxHp.Should().BeApproximately(632.5f, 0.1f);
    }

    [Fact]
    public void Empty_loadout_returns_base_class_stats()
    {
        var expected = ClassBaseStats.For(CharacterClass.Mage, 5);

        var stats = Aggregator.Aggregate(
            Char(CharacterClass.Mage, 5),
            Array.Empty<ItemInstance>(),
            Array.Empty<Item>(),
            Array.Empty<ActiveSetBonus>());

        stats.MagicPower.Should().BeApproximately(expected.MagicPower, 0.001f);
        stats.Attack.Should().BeApproximately(expected.Attack, 0.001f);
    }
}
