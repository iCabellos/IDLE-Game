using FluentAssertions;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Loot;
using IdleRPG.Domain.ValueObjects;
using IdleRPG.Tests.Domain.Combat;

namespace IdleRPG.Tests.Domain.Loot;

[Trait("Phase", "F4")]
[Trait("Category", "LootEngine")]
public class LootGeneratorTests
{
    // -----------------------------------------------------------------
    // Archetype catalog coherence: "arquetipos con sentido"
    // -----------------------------------------------------------------

    [Fact]
    public void Every_archetype_has_a_coherent_non_empty_affix_pool()
    {
        foreach (var archetype in Enum.GetValues<ItemArchetype>())
        {
            var info = ArchetypeCatalog.For(archetype);

            info.Prefixes.Should().HaveCountGreaterThanOrEqualTo(3,
                $"{archetype} needs a real prefix pool");
            info.Suffixes.Should().HaveCountGreaterThanOrEqualTo(3,
                $"{archetype} needs a real suffix pool");
            info.DisplayName.Should().NotBeNullOrWhiteSpace();
            info.FlavorWord.Should().NotBeNullOrWhiteSpace();

            // Every affix must reference a real CharacterStats property and
            // carry a descriptive (non-numeric) label.
            var statKeys = CharacterStats.Zero.ToDictionary().Keys.ToHashSet();
            foreach (var affix in info.Prefixes.Concat(info.Suffixes))
            {
                statKeys.Should().Contain(affix.Stat,
                    $"{archetype} affix '{affix.Name}' must map to a CharacterStats property");
                affix.Description.Should().NotBeNullOrWhiteSpace();
                affix.Description.Should().NotMatchRegex(@"\d",
                    "affix descriptions are descriptive text, never numbers (UX rule)");
            }
        }
    }

    [Fact]
    public void Archetype_themes_stay_in_their_lane()
    {
        // The tank archetype must never roll offensive crit, and the
        // treasure archetype must never roll combat stats.
        var juggernaut = ArchetypeCatalog.For(ItemArchetype.Juggernaut);
        juggernaut.Prefixes.Concat(juggernaut.Suffixes)
            .Should().NotContain(a =>
                a.Stat == nameof(CharacterStats.CritRate) ||
                a.Stat == nameof(CharacterStats.CritMultiplier) ||
                a.Stat == nameof(CharacterStats.Attack));

        var fortunate = ArchetypeCatalog.For(ItemArchetype.Fortunate);
        fortunate.Prefixes.Concat(fortunate.Suffixes)
            .Should().OnlyContain(a =>
                a.Stat == nameof(CharacterStats.Luck) ||
                a.Stat == nameof(CharacterStats.DropRate) ||
                a.Stat == nameof(CharacterStats.IdleEfficiency));
    }

    [Fact]
    public void Every_class_has_at_least_one_favored_archetype()
    {
        foreach (var cls in Enum.GetValues<CharacterClass>())
        {
            ArchetypeCatalog.FavoredBy(cls).Should().NotBeEmpty(
                $"{cls} builds need archetypes that serve them");
        }
    }

    // -----------------------------------------------------------------
    // Generation pipeline
    // -----------------------------------------------------------------

    [Theory]
    [InlineData(ItemRarity.Broken, 0)]
    [InlineData(ItemRarity.Common, 0)]
    [InlineData(ItemRarity.Uncommon, 1)]
    [InlineData(ItemRarity.Epic, 2)]
    [InlineData(ItemRarity.Ancient, 3)]
    [InlineData(ItemRarity.Legendary, 4)]
    [InlineData(ItemRarity.Divine, 5)]
    [InlineData(ItemRarity.Transcendent, 6)]
    public void Affix_count_scales_with_rarity_band(ItemRarity rarity, int expected)
    {
        LootGenerator.AffixCountFor(rarity).Should().Be(expected);
    }

    [Fact]
    public void Generated_items_have_names_affixes_and_rolled_modifiers()
    {
        var rng = new Random(7);
        var drop = LootGenerator.Generate(rng, ItemRarity.Legendary, ItemArchetype.Executioner, "MainHand", 40);

        drop.Name.Should().NotBeNullOrWhiteSpace();
        drop.AffixNames.Should().HaveCount(4);
        drop.Modifiers.Should().HaveCount(4);
        drop.AffixDescriptions.Should().HaveCount(4);
        drop.ItemLevel.Should().Be(40);

        // Prefix/suffix caps hold and the name is composed Diablo-style.
        var info = ArchetypeCatalog.For(ItemArchetype.Executioner);
        var prefixes = drop.AffixNames.Count(n => info.Prefixes.Any(p => p.Name == n));
        var suffixes = drop.AffixNames.Count(n => info.Suffixes.Any(s => s.Name == n));
        prefixes.Should().BeLessThanOrEqualTo(LootGenerator.MaxPrefixes);
        suffixes.Should().BeLessThanOrEqualTo(LootGenerator.MaxSuffixes);
        (prefixes + suffixes).Should().Be(4);
        drop.Name.Should().Contain("Blade");
    }

    [Fact]
    public void Affixes_never_repeat_on_one_item()
    {
        for (var seed = 0; seed < 50; seed++)
        {
            var drop = LootGenerator.Generate(
                new Random(seed), ItemRarity.Transcendent, ItemArchetype.Oracle, "Amulet", 60);

            drop.AffixNames.Should().OnlyHaveUniqueItems();
        }
    }

    [Fact]
    public void Generation_is_deterministic_for_a_seed()
    {
        var a = LootGenerator.Generate(new Random(99), ItemRarity.Mythic, ItemArchetype.Breaker, "TwoHand", 25);
        var b = LootGenerator.Generate(new Random(99), ItemRarity.Mythic, ItemArchetype.Breaker, "TwoHand", 25);

        a.Should().BeEquivalentTo(b);
    }

    [Fact]
    public void White_items_carry_no_affixes_but_still_have_archetype_names()
    {
        var drop = LootGenerator.Generate(new Random(3), ItemRarity.Common, ItemArchetype.Juggernaut, "Chest", 10);

        drop.AffixNames.Should().BeEmpty();
        drop.Modifiers.Should().BeEmpty();
        drop.Name.Should().Be("Colossus Cuirass");
    }

    [Fact]
    public void Smart_loot_favors_the_teams_archetypes()
    {
        // All-caster team: Stormcaller (Mage/Elementalist favored) should
        // dominate the rolls over, say, Executioner.
        var team = new[]
        {
            CombatTestTeams.Hero("A", CharacterClass.Mage, CharacterRole.DPS, 30),
            CombatTestTeams.Hero("B", CharacterClass.Elementalist, CharacterRole.DPS, 30),
        };

        var rng = new Random(1234);
        var counts = new Dictionary<ItemArchetype, int>();
        for (var i = 0; i < 2000; i++)
        {
            var archetype = LootGenerator.RollArchetype(rng, team);
            counts[archetype] = counts.GetValueOrDefault(archetype) + 1;
        }

        // Mage favors Stormcaller; Elementalist favors Stormcaller + Breaker.
        var favoredShare = counts.GetValueOrDefault(ItemArchetype.Stormcaller)
            + counts.GetValueOrDefault(ItemArchetype.Breaker);
        favoredShare.Should().BeGreaterThan(1300, "~70% of drops roll a team-favored archetype");
        counts.GetValueOrDefault(ItemArchetype.Stormcaller).Should().BeGreaterThan(
            counts.GetValueOrDefault(ItemArchetype.Executioner),
            "caster teams should see far more caster loot than physical loot");
        counts.Keys.Count.Should().BeGreaterThan(2, "the 30% wild roll keeps other archetypes reachable");
    }

    [Fact]
    public void Flat_affix_values_scale_with_item_level()
    {
        static float MaxAttack(int level)
        {
            var best = 0f;
            for (var seed = 0; seed < 40; seed++)
            {
                var drop = LootGenerator.Generate(
                    new Random(seed), ItemRarity.Legendary, ItemArchetype.Executioner, "MainHand", level);
                foreach (var mod in drop.Modifiers)
                {
                    if (mod.Stat == nameof(CharacterStats.Attack) && mod.Type == ModifierType.Flat)
                    {
                        best = MathF.Max(best, mod.Value);
                    }
                }
            }

            return best;
        }

        MaxAttack(200).Should().BeGreaterThan(MaxAttack(10) * 5f,
            "endgame drops must dwarf early ones, ARPG-style");
    }

    // -----------------------------------------------------------------
    // Idle integration
    // -----------------------------------------------------------------

    [Fact]
    public void Idle_farming_accumulates_named_loot()
    {
        var team = CombatTestTeams.Starter(30);
        var state = new IdleState { Zone = 6, Wave = 1 };

        IdleSimulator.Advance(state, team, ticks: 14_400, userSeed: 42); // 4h farm

        state.PendingLoot.Should().NotBeEmpty("hours of farming must drop loot");
        state.PendingLoot.Should().OnlyContain(d => !string.IsNullOrWhiteSpace(d.Name));
        state.PendingLoot.Count.Should().BeLessThanOrEqualTo(IdleSimulator.MaxPendingLoot);
    }

    [Fact]
    public void Pending_loot_is_capped_and_overflow_is_tallied()
    {
        var team = CombatTestTeams.Starter(30);
        var state = new IdleState { Zone = 6, Wave = 1 };

        // Pre-fill to the cap; further drops must overflow, not grow the list.
        for (var i = 0; i < IdleSimulator.MaxPendingLoot; i++)
        {
            state.PendingLoot.Add(LootGenerator.Generate(
                new Random(i), ItemRarity.Common, ItemArchetype.Fortunate, "Ring", 1));
        }

        var report = IdleSimulator.Advance(state, team, ticks: 14_400, userSeed: 42);

        state.PendingLoot.Should().HaveCount(IdleSimulator.MaxPendingLoot);
        if (report.DropsRolled > 0)
        {
            state.OverflowLoot.Should().Be(report.DropsRolled);
        }
    }
}
