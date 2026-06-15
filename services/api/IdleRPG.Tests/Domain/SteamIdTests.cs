using FluentAssertions;
using IdleRPG.Domain.ValueObjects;
using Xunit;

namespace IdleRPG.Tests.Domain;

[Trait("Phase", "F1")]
public class SteamIdTests
{
    [Fact]
    public void Create_accepts_a_valid_17_digit_id()
    {
        var id = SteamId.Create("76561197960287930");
        id.Value.Should().Be("76561197960287930");
        ((string)id).Should().Be("76561197960287930");
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("123")]                  // too short
    [InlineData("765611979602879300")]   // 18 digits
    [InlineData("7656119796028793a")]    // non-numeric
    public void TryCreate_rejects_invalid_ids(string? input)
    {
        SteamId.TryCreate(input, out _).Should().BeFalse();
    }

    [Fact]
    public void Create_throws_on_invalid_id()
    {
        var act = () => SteamId.Create("not-an-id");
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void TryCreate_trims_whitespace()
    {
        SteamId.TryCreate("  76561197960287930  ", out var id).Should().BeTrue();
        id.Value.Should().Be("76561197960287930");
    }
}
