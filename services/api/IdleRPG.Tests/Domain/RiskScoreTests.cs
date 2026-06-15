using FluentAssertions;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;
using Xunit;

namespace IdleRPG.Tests.Domain;

[Trait("Phase", "F1")]
public class RiskScoreTests
{
    [Theory]
    [InlineData(-50, 0)]
    [InlineData(0, 0)]
    [InlineData(55, 55)]
    [InlineData(100, 100)]
    [InlineData(250, 100)]
    public void Score_is_clamped_to_0_100(int input, int expected)
    {
        new RiskScore(input).Value.Should().Be(expected);
    }

    [Fact]
    public void Apply_adds_delta_and_clamps()
    {
        new RiskScore(90).Apply(20).Value.Should().Be(100);
        new RiskScore(10).Apply(-50).Value.Should().Be(0);
        new RiskScore(40).Apply(15).Value.Should().Be(55);
    }

    [Theory]
    [InlineData(0, AntiBotRiskLevel.Normal)]
    [InlineData(20, AntiBotRiskLevel.Normal)]
    [InlineData(35, AntiBotRiskLevel.SilentMonitor)]
    [InlineData(55, AntiBotRiskLevel.VisibleWarning)]
    [InlineData(65, AntiBotRiskLevel.GameplayRestrict)]
    [InlineData(75, AntiBotRiskLevel.MarketRestrict)]
    [InlineData(85, AntiBotRiskLevel.TempSuspension)]
    [InlineData(100, AntiBotRiskLevel.PermanentBan)]
    public void Level_maps_to_correct_threshold(int value, AntiBotRiskLevel expected)
    {
        new RiskScore(value).Level.Should().Be(expected);
    }

    [Fact]
    public void Zero_is_normal()
    {
        RiskScore.Zero.Value.Should().Be(0);
        RiskScore.Zero.Level.Should().Be(AntiBotRiskLevel.Normal);
    }
}
