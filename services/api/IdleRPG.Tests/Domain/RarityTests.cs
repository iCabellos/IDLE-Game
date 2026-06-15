using FluentAssertions;
using IdleRPG.Domain.Enums;
using Xunit;

namespace IdleRPG.Tests.Domain;

[Trait("Phase", "F1")]
public class RarityTests
{
    [Fact]
    public void Broken_is_the_lowest_tier_and_OneOfOne_the_highest()
    {
        ((int)ItemRarity.Broken).Should().Be(1);
        ((int)ItemRarity.OneOfOne).Should().Be(21);
    }

    [Fact]
    public void All_21_tiers_have_reference_data()
    {
        foreach (ItemRarity rarity in Enum.GetValues<ItemRarity>())
        {
            var info = ItemRarityData.Get(rarity);
            info.Should().NotBeNull();
        }
    }

    [Theory]
    [InlineData(ItemRarity.Broken, 0.30f)]
    [InlineData(ItemRarity.Common, 0.70f)]
    [InlineData(ItemRarity.Legendary, 4.00f)]
    [InlineData(ItemRarity.Transcendent, 16.0f)]
    public void Multiplier_matches_table(ItemRarity rarity, float expected)
    {
        ItemRarityData.Multiplier(rarity).Should().Be(expected);
    }

    [Theory]
    [InlineData(ItemRarity.Unique)]
    [InlineData(ItemRarity.Seasonal)]
    [InlineData(ItemRarity.Founder)]
    [InlineData(ItemRarity.EventLimited)]
    [InlineData(ItemRarity.OneOfOne)]
    public void Top_tiers_have_fixed_stats_and_are_not_tradeable(ItemRarity rarity)
    {
        ItemRarityData.HasFixedStats(rarity).Should().BeTrue();
        ItemRarityData.IsTradeable(rarity).Should().BeFalse();
        ItemRarityData.Multiplier(rarity).Should().BeNull();
    }

    [Theory]
    [InlineData(ItemRarity.Broken)]
    [InlineData(ItemRarity.Rare)]
    [InlineData(ItemRarity.Transcendent)]
    public void Rolled_tiers_are_tradeable_with_a_multiplier(ItemRarity rarity)
    {
        ItemRarityData.HasFixedStats(rarity).Should().BeFalse();
        ItemRarityData.IsTradeable(rarity).Should().BeTrue();
        ItemRarityData.Multiplier(rarity).Should().NotBeNull();
    }

    [Fact]
    public void Drop_percentages_decrease_as_rarity_increases_for_rolled_tiers()
    {
        ItemRarityData.DropPercent(ItemRarity.Broken)
            .Should().BeGreaterThan(ItemRarityData.DropPercent(ItemRarity.Common));
        ItemRarityData.DropPercent(ItemRarity.Common)
            .Should().BeGreaterThan(ItemRarityData.DropPercent(ItemRarity.Legendary));
    }
}
