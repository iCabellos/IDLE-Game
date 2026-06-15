using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Infrastructure.Items;

/// <summary>
/// Computes a character's effective <see cref="CharacterStats"/> in the order
/// defined by the design: base class stats, additive item stats, set-bonus
/// modifiers, passives (flat then percent), and finally gameplay caps.
/// </summary>
public sealed class StatAggregator : IStatAggregator
{
    public CharacterStats Aggregate(
        Character character,
        IEnumerable<ItemInstance> equipped,
        IEnumerable<Item> definitions,
        IEnumerable<ActiveSetBonus> bonuses)
    {
        // 1. Base class stats scaled by level.
        var totals = new Dictionary<string, float>(
            ClassBaseStats.For(character.Class, character.Level).ToDictionary());

        // Percentage modifiers are accumulated and applied multiplicatively last.
        var percentByStat = new Dictionary<string, float>();

        // 2. Additive rolled stats from each equipped item, plus its passives.
        foreach (var instance in equipped)
        {
            var rolled = RolledItemData.Parse(instance.RolledStatsJson);
            AddFlat(totals, rolled.Stats);
            ApplyModifiersFromPassives(rolled.Passives, totals, percentByStat);
        }

        // 3 & 4. Set bonuses: modifiers then their passives.
        foreach (var bonus in bonuses)
        {
            ApplyModifiers(bonus.Modifiers, totals, percentByStat);
            ApplyModifiersFromPassives(bonus.Passives, totals, percentByStat);
        }

        // Apply accumulated percentages multiplicatively.
        foreach (var (stat, pct) in percentByStat)
        {
            if (totals.TryGetValue(stat, out var current))
            {
                totals[stat] = current * (1f + pct);
            }
        }

        // 5. Caps.
        return CharacterStats.FromDictionary(totals).ApplyCaps();
    }

    private static void AddFlat(
        Dictionary<string, float> totals, IReadOnlyDictionary<string, float> stats)
    {
        foreach (var (stat, value) in stats)
        {
            totals[stat] = totals.GetValueOrDefault(stat) + value;
        }
    }

    private static void ApplyModifiers(
        IEnumerable<StatModifier> modifiers,
        Dictionary<string, float> totals,
        Dictionary<string, float> percentByStat)
    {
        foreach (var mod in modifiers)
        {
            if (mod.Type == ModifierType.Percent)
            {
                percentByStat[mod.Stat] = percentByStat.GetValueOrDefault(mod.Stat) + mod.Value;
            }
            else
            {
                totals[mod.Stat] = totals.GetValueOrDefault(mod.Stat) + mod.Value;
            }
        }
    }

    private static void ApplyModifiersFromPassives(
        IEnumerable<Passive> passives,
        Dictionary<string, float> totals,
        Dictionary<string, float> percentByStat)
    {
        foreach (var passive in passives)
        {
            ApplyModifiers(passive.Modifiers, totals, percentByStat);
        }
    }
}
