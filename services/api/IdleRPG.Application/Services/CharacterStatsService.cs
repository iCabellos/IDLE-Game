using System.Globalization;
using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.DTOs.Items;
using IdleRPG.Application.Interfaces.Caching;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Application.Services;

/// <inheritdoc cref="ICharacterStatsService" />
public sealed class CharacterStatsService : ICharacterStatsService
{
    private static readonly TimeSpan StatsCacheTtl = TimeSpan.FromHours(1);

    private readonly IRepository<ItemInstance> _instances;
    private readonly ISetBonusCalculator _setBonusCalculator;
    private readonly IStatAggregator _aggregator;
    private readonly ICacheService _cache;

    public CharacterStatsService(
        IRepository<ItemInstance> instances,
        ISetBonusCalculator setBonusCalculator,
        IStatAggregator aggregator,
        ICacheService cache)
    {
        _instances = instances;
        _setBonusCalculator = setBonusCalculator;
        _aggregator = aggregator;
        _cache = cache;
    }

    public async Task<CharacterSummaryDto> RecalculateAndCacheAsync(
        Character character, CancellationToken ct = default)
    {
        var equipped = await _instances.GetAllAsync(
            new EquippedItemsByCharacterSpec(character.Id), ct);

        var definitions = equipped
            .Where(i => i.Item is not null)
            .Select(i => i.Item!)
            .ToList();

        var bonuses = _setBonusCalculator.CalculateActiveBonuses(equipped, definitions);
        var stats = _aggregator.Aggregate(character, equipped, definitions, bonuses);

        await _cache.SetAsync($"stats:{character.Id}", stats, StatsCacheTtl, ct);

        return new CharacterSummaryDto
        {
            CharacterId = character.Id,
            Name = character.Name,
            Class = character.Class.ToString(),
            Role = character.Role.ToString(),
            Level = character.Level,
            Stats = new Dictionary<string, float>(stats.ToDictionary()),
            ActiveSetBonuses = bonuses.Select(Describe).ToList(),
        };
    }

    private static string Describe(ActiveSetBonus bonus)
    {
        var parts = new List<string>();

        foreach (var mod in bonus.Modifiers)
        {
            parts.Add(mod.Type == ModifierType.Percent
                ? $"+{(mod.Value * 100f).ToString("0.#", CultureInfo.InvariantCulture)}% {mod.Stat}"
                : $"+{mod.Value.ToString("0.#", CultureInfo.InvariantCulture)} {mod.Stat}");
        }

        parts.AddRange(bonus.Passives.Select(p => p.Name));

        var detail = parts.Count > 0 ? $": {string.Join(", ", parts)}" : string.Empty;
        return $"{bonus.PiecesRequired}-piece{detail}";
    }
}
