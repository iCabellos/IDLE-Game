using FluentAssertions;
using IdleRPG.Domain.Combat;

namespace IdleRPG.Tests.Domain.Combat;

[Trait("Phase", "F4")]
public class CombatFormulasTests
{
    [Theory]
    [InlineData(0.50f, 0.20f, 0.30f)] // simple subtraction
    [InlineData(0.10f, 0.50f, 0.00f)] // floored at 0
    [InlineData(1.50f, 0.00f, 0.90f)] // capped at 0.90
    public void EffectiveResistance_is_clamped_between_0_and_cap(
        float resist, float pen, float expected)
    {
        CombatFormulas.EffectiveResistance(resist, pen).Should().BeApproximately(expected, 0.0001f);
    }

    [Fact]
    public void FinalDamage_applies_crit_and_resistance()
    {
        // 100 base, crit x2, 25% effective resistance => 100 * 2 * 0.75 = 150.
        CombatFormulas.FinalDamage(100f, crit: true, critMultiplier: 2f, effectiveResistance: 0.25f)
            .Should().BeApproximately(150f, 0.001f);

        CombatFormulas.FinalDamage(100f, crit: false, critMultiplier: 2f, effectiveResistance: 0.25f)
            .Should().BeApproximately(75f, 0.001f);
    }

    [Fact]
    public void DefenseReduction_grows_with_defense_but_never_reaches_1()
    {
        var low = CombatFormulas.DefenseReduction(50f, attackerLevel: 10);
        var high = CombatFormulas.DefenseReduction(5000f, attackerLevel: 10);

        low.Should().BeGreaterThan(0f);
        high.Should().BeGreaterThan(low);
        high.Should().BeLessThan(1f);
    }

    [Fact]
    public void DefenseReduction_decays_against_higher_level_attackers()
    {
        var vsLow = CombatFormulas.DefenseReduction(300f, attackerLevel: 10);
        var vsHigh = CombatFormulas.DefenseReduction(300f, attackerLevel: 100);

        vsHigh.Should().BeLessThan(vsLow);
    }

    [Fact]
    public void BreakDamage_scales_with_level_break_effect_and_toughness()
    {
        var baseline = CombatFormulas.BreakDamage(10, 0f, 60f);
        var withBreakEffect = CombatFormulas.BreakDamage(10, 0.5f, 60f);
        var vsBoss = CombatFormulas.BreakDamage(10, 0f, 300f);

        withBreakEffect.Should().BeApproximately(baseline * 1.5f, 0.01f);
        vsBoss.Should().BeApproximately(baseline * 5f, 0.01f);
    }

    [Fact]
    public void OfflineEfficiency_is_full_for_36_hours()
    {
        CombatFormulas.OfflineEfficiency(TimeSpan.Zero).Should().Be(1f);
        CombatFormulas.OfflineEfficiency(TimeSpan.FromHours(35)).Should().Be(1f);
        CombatFormulas.OfflineEfficiency(TimeSpan.FromHours(36)).Should().Be(1f);
    }

    [Fact]
    public void OfflineEfficiency_decays_5_percent_per_day_after_grace()
    {
        // 36h + 2 full days => 1.0 - 0.10 = 0.90.
        CombatFormulas.OfflineEfficiency(TimeSpan.FromHours(36 + 48))
            .Should().BeApproximately(0.90f, 0.0001f);
    }

    [Fact]
    public void OfflineEfficiency_never_drops_below_1_percent()
    {
        CombatFormulas.OfflineEfficiency(TimeSpan.FromDays(400)).Should().Be(0.01f);
    }
}
