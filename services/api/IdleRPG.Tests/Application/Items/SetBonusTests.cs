using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Infrastructure.Items;
using IdleRPG.Infrastructure.Persistence.Seed;

namespace IdleRPG.Tests.Application.Items;

[Trait("Category", "ItemEngine")]
public sealed class SetBonusTests
{
    private static readonly Guid IroncladSetId = ItemSeed.IroncladSetId;

    private static SetBonusCalculator BuildCalculator() =>
        new(SetBonusSeed.BuildSetBonuses());

    private static (List<ItemInstance> Equipped, List<Item> Defs) BuildLoadout(int ironcladPieces, int looseItems = 0)
    {
        var defs = new List<Item>();
        var equipped = new List<ItemInstance>();

        var slots = new[] { ItemSlot.Head, ItemSlot.Chest, ItemSlot.Legs, ItemSlot.Feet };
        for (var i = 0; i < ironcladPieces; i++)
        {
            var defId = Guid.NewGuid();
            defs.Add(new Item { Id = defId, Name = $"Ironclad {slots[i]}", Slot = slots[i], SetId = IroncladSetId });
            equipped.Add(new ItemInstance { Id = Guid.NewGuid(), ItemId = defId, EquippedSlot = slots[i] });
        }

        for (var i = 0; i < looseItems; i++)
        {
            var defId = Guid.NewGuid();
            defs.Add(new Item { Id = defId, Name = $"Loose {i}", Slot = ItemSlot.Ring, SetId = null });
            equipped.Add(new ItemInstance { Id = Guid.NewGuid(), ItemId = defId, EquippedSlot = ItemSlot.Ring });
        }

        return (equipped, defs);
    }

    [Fact]
    public void Two_pieces_activate_only_the_two_piece_bonus()
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(2);

        var active = calc.CalculateActiveBonuses(equipped, defs);

        active.Should().HaveCount(1);
        active[0].PiecesRequired.Should().Be(2);
        active[0].Modifiers.Should().ContainSingle(m =>
            m.Stat == "Defense" && m.Type == ModifierType.Percent && Math.Abs(m.Value - 0.10f) < 0.0001f);
    }

    [Fact]
    public void Three_pieces_still_only_activate_the_two_piece_bonus()
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(3);

        var active = calc.CalculateActiveBonuses(equipped, defs);

        active.Should().ContainSingle(b => b.PiecesRequired == 2);
        active.Should().NotContain(b => b.PiecesRequired == 4);
    }

    [Fact]
    public void Four_pieces_activate_both_thresholds()
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(4);

        var active = calc.CalculateActiveBonuses(equipped, defs);

        active.Should().HaveCount(2);
        active.Select(b => b.PiecesRequired).Should().BeEquivalentTo(new[] { 2, 4 });
    }

    [Fact]
    public void Four_piece_bonus_grants_25_percent_defense_and_unbreakable()
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(4);

        var fourPiece = calc.CalculateActiveBonuses(equipped, defs).Single(b => b.PiecesRequired == 4);

        fourPiece.Modifiers.Should().ContainSingle(m =>
            m.Stat == "Defense" && m.Type == ModifierType.Percent && Math.Abs(m.Value - 0.25f) < 0.0001f);
        fourPiece.Passives.Should().ContainSingle(p => p.Name == "Unbreakable");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    public void Fewer_than_two_pieces_activate_nothing(int pieces)
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(pieces);

        calc.CalculateActiveBonuses(equipped, defs).Should().BeEmpty();
    }

    [Fact]
    public void Non_set_items_are_ignored()
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(0, looseItems: 4);

        calc.CalculateActiveBonuses(equipped, defs).Should().BeEmpty();
    }

    [Fact]
    public void Loose_items_do_not_count_towards_set_thresholds()
    {
        var calc = BuildCalculator();
        var (equipped, defs) = BuildLoadout(2, looseItems: 3);

        var active = calc.CalculateActiveBonuses(equipped, defs);

        active.Should().ContainSingle(b => b.PiecesRequired == 2);
    }
}
