using FluentAssertions;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;

namespace IdleRPG.Tests.Domain.Combat;

[Trait("Phase", "F4")]
[Trait("Category", "CombatEngine")]
public class CombatEngineTests
{
    [Fact]
    public void Same_seed_produces_identical_battles()
    {
        var team = CombatTestTeams.Starter(20);
        var enemies = EnemyCatalog.WaveFor(4, 5);

        var a = CombatEngine.Simulate(team, enemies, seed: 42);
        var b = CombatEngine.Simulate(team, enemies, seed: 42);

        a.Should().BeEquivalentTo(b);
    }

    [Fact]
    public void Different_seeds_can_diverge()
    {
        var team = CombatTestTeams.Starter(20);
        var enemies = EnemyCatalog.WaveFor(4, 5);

        var results = Enumerable.Range(0, 10)
            .Select(seed => CombatEngine.Simulate(team, enemies, seed))
            .Select(r => r.DamageDealtByHeroes)
            .Distinct();

        results.Count().Should().BeGreaterThan(1, "crits and aggro rolls should vary by seed");
    }

    [Fact]
    public void Level_appropriate_wave_is_a_victory_with_visible_turn_economy()
    {
        var team = CombatTestTeams.Starter(25);
        var enemies = EnemyCatalog.WaveFor(zone: 5, wave: 5); // zone level 21

        var result = CombatEngine.Simulate(team, enemies, seed: 7);

        result.Victory.Should().BeTrue();
        result.HeroActions.Should().BeGreaterThanOrEqualTo(8,
            "fights must last enough turns for SP / energy / break mechanics to matter");
        result.BasicsCast.Should().BeGreaterThan(0);
        result.SkillsCast.Should().BeGreaterThan(0, "skill points should be spent");
    }

    [Fact]
    public void Boss_fights_charge_and_fire_ultimates()
    {
        var team = CombatTestTeams.Starter(25);
        var boss = EnemyCatalog.WaveFor(zone: 5, wave: 10);

        var result = CombatEngine.Simulate(team, boss, seed: 11);

        result.Victory.Should().BeTrue();
        result.UltimatesCast.Should().BeGreaterThanOrEqualTo(2,
            "a boss fight should be long enough to cycle ultimates");
    }

    [Fact]
    public void Weakness_matching_team_triggers_toughness_breaks()
    {
        var team = CombatTestTeams.Starter(25);

        // Starter team covers Physical/Fire/Lightning/Ice; scan a few waves
        // to find matchups and assert breaks actually fire.
        var totalBreaks = 0;
        for (var wave = 1; wave <= 10; wave++)
        {
            totalBreaks += CombatEngine.Simulate(team, EnemyCatalog.WaveFor(5, wave), seed: wave).BreaksTriggered;
        }

        totalBreaks.Should().BeGreaterThan(0, "weakness break is a core mechanic and must fire in a full zone");
    }

    [Fact]
    public void Hopelessly_overleveled_content_is_a_defeat()
    {
        var team = CombatTestTeams.Starter(10);
        var enemies = EnemyCatalog.WaveFor(zone: 30, wave: 5); // zone level 146

        var result = CombatEngine.Simulate(team, enemies, seed: 3);

        result.Victory.Should().BeFalse("progression walls must exist");
    }

    [Fact]
    public void Healer_keeps_the_team_healthier_than_no_healer()
    {
        int Downs(IReadOnlyList<HeroSpec> team)
        {
            var downs = 0;
            for (var seed = 0; seed < 20; seed++)
            {
                downs += CombatEngine.Simulate(team, EnemyCatalog.WaveFor(6, 9), seed).HeroesDown;
            }

            return downs;
        }

        var withHealer = CombatTestTeams.Starter(28);
        var withoutHealer = new[]
        {
            CombatTestTeams.Hero("Tank", CharacterClass.Warrior, CharacterRole.Tank, 28),
            CombatTestTeams.Hero("Blade", CharacterClass.Berserker, CharacterRole.DPS, 28),
            CombatTestTeams.Hero("Shadow", CharacterClass.Rogue, CharacterRole.DPS, 28),
            CombatTestTeams.Hero("Frost", CharacterClass.Mage, CharacterRole.DPS, 28),
        };

        Downs(withHealer).Should().BeLessThanOrEqualTo(Downs(withoutHealer),
            "a healer should never make survival worse");
    }

    [Fact]
    public void Every_class_kit_is_defined_and_elements_are_spread()
    {
        var kits = Enum.GetValues<CharacterClass>().Select(ClassKits.For).ToList();

        kits.Should().OnlyContain(k => k.UltimateEnergyCost >= 100 && k.UltimateEnergyCost <= 140);
        kits.Select(k => k.DamageType).Distinct().Count().Should().Be(5,
            "all five damage types must be represented across the roster");
    }
}
