using System.Diagnostics;
using FluentAssertions;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.GameData;

namespace IdleRPG.Tests.Domain.Combat;

/// <summary>
/// Balance bands: enemy HP is levelled against team damage so that fights at
/// the recommended level are winnable but long enough for every mechanic to
/// show, and content far above the team's level is an actual wall.
/// </summary>
[Trait("Phase", "F4")]
[Trait("Category", "CombatEngine")]
public class CombatBalanceTests
{
    [Theory]
    [InlineData(5)]
    [InlineData(25)]
    [InlineData(50)]
    [InlineData(100)]
    [InlineData(250)]
    public void At_level_team_clears_its_recommended_zone(int level)
    {
        var team = CombatTestTeams.Starter(level);
        var zone = (level - 1) / EnemyCatalog.LevelsPerZone + 1;

        for (var wave = 1; wave <= 10; wave++)
        {
            var result = CombatEngine.Simulate(team, EnemyCatalog.WaveFor(zone, wave), seed: level * 100 + wave);

            result.Victory.Should().BeTrue($"level {level} team should clear zone {zone} wave {wave}");
            result.Ticks.Should().BeLessThan(600, "no single wave should take more than ten idle minutes");
        }
    }

    [Theory]
    [InlineData(25)]
    [InlineData(100)]
    public void Fights_last_enough_turns_for_mechanics_to_matter(int level)
    {
        var team = CombatTestTeams.Starter(level);
        var zone = (level - 1) / EnemyCatalog.LevelsPerZone + 1;

        var totalActions = 0;
        var totalUlts = 0;
        var totalSkills = 0;

        for (var wave = 1; wave <= 10; wave++)
        {
            var result = CombatEngine.Simulate(team, EnemyCatalog.WaveFor(zone, wave), seed: wave);
            totalActions += result.HeroActions;
            totalUlts += result.UltimatesCast;
            totalSkills += result.SkillsCast;
        }

        (totalActions / 10f).Should().BeGreaterThanOrEqualTo(8f,
            "average wave should run at least two full team cycles");
        totalUlts.Should().BeGreaterThanOrEqualTo(5, "ultimates should fire regularly across a zone");
        totalSkills.Should().BeGreaterThanOrEqualTo(10, "skills should be a routine part of the rotation");
    }

    [Theory]
    [InlineData(10)]
    [InlineData(50)]
    public void Zones_far_ahead_are_a_wall(int level)
    {
        var team = CombatTestTeams.Starter(level);
        var wallZone = (level * 2 + 20 - 1) / EnemyCatalog.LevelsPerZone + 1;

        var wins = 0;
        for (var seed = 0; seed < 5; seed++)
        {
            if (CombatEngine.Simulate(team, EnemyCatalog.WaveFor(wallZone, 10), seed).Victory)
            {
                wins++;
            }
        }

        wins.Should().Be(0, $"a level {level} team must not clear the level {EnemyCatalog.ZoneLevel(wallZone)} boss");
    }

    [Fact]
    public void Idle_simulation_progresses_and_eventually_hits_a_wall()
    {
        var team = CombatTestTeams.Starter(20);
        var state = new IdleState { Zone = 4, Wave = 1 }; // recommended zone for level 20

        // Two idle hours: should clear waves, then stall against later zones.
        var report = IdleSimulator.Advance(state, team, ticks: 7200, userSeed: 99);

        report.BattlesWon.Should().BeGreaterThan(5, "an at-level team should farm its zone comfortably");
        state.PendingXp.Should().BeGreaterThan(0);
        (state.Zone > 4 || state.Wave > 1 || state.IsStuck).Should().BeTrue("progress must be persisted");
    }

    [Fact]
    public void Idle_simulation_is_deterministic_regardless_of_slicing()
    {
        var team = CombatTestTeams.Starter(30);

        var oneShot = new IdleState();
        IdleSimulator.Advance(oneShot, team, ticks: 3600, userSeed: 1234);

        var sliced = new IdleState();
        for (var i = 0; i < 60; i++)
        {
            IdleSimulator.Advance(sliced, team, ticks: 60, userSeed: 1234);
        }

        sliced.Zone.Should().Be(oneShot.Zone);
        sliced.Wave.Should().Be(oneShot.Wave);
        sliced.BattleCounter.Should().Be(oneShot.BattleCounter);
        sliced.PendingXp.Should().Be(oneShot.PendingXp);
        sliced.TotalKills.Should().Be(oneShot.TotalKills);
    }

    [Fact]
    public void Benchmark_10k_ticks_simulate_in_under_100ms()
    {
        var team = CombatTestTeams.Starter(60);
        var state = new IdleState { Zone = 12, Wave = 1 };

        // Warm-up (JIT).
        IdleSimulator.Advance(new IdleState { Zone = 12 }, team, ticks: 1000, userSeed: 7);

        var sw = Stopwatch.StartNew();
        IdleSimulator.Advance(state, team, ticks: 10_000, userSeed: 7);
        sw.Stop();

        sw.ElapsedMilliseconds.Should().BeLessThan(100,
            $"10k ticks must simulate in <100ms (took {sw.ElapsedMilliseconds}ms)");
    }
}
