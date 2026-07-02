using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.Interfaces.Caching;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Application.Services;

/// <inheritdoc cref="IIdleProgressService" />
public sealed class IdleProgressService : IIdleProgressService
{
    /// <summary>Offline simulation is capped at 7 days of wall-clock time.</summary>
    public static readonly TimeSpan MaxOfflineWindow = TimeSpan.FromDays(7);

    private readonly IRepository<Character> _characters;
    private readonly IIdleStateStore _stateStore;
    private readonly ICacheService _cache;
    private readonly ICharacterStatsService _statsService;

    public IdleProgressService(
        IRepository<Character> characters,
        IIdleStateStore stateStore,
        ICacheService cache,
        ICharacterStatsService statsService)
    {
        _characters = characters;
        _stateStore = stateStore;
        _cache = cache;
        _statsService = statsService;
    }

    public async Task<IdleProgress?> AdvanceAsync(Guid userId, CancellationToken ct = default)
    {
        var team = await BuildTeamAsync(userId, ct);
        if (team.Count == 0)
        {
            return null;
        }

        var state = await _stateStore.GetAsync(userId, ct) ?? new IdleState();

        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        if (state.LastSimulatedAtUnix > 0 && now > state.LastSimulatedAtUnix)
        {
            var elapsed = TimeSpan.FromSeconds(now - state.LastSimulatedAtUnix);
            if (elapsed > MaxOfflineWindow)
            {
                elapsed = MaxOfflineWindow;
            }

            var ticks = (int)(elapsed.TotalSeconds * CombatFormulas.OfflineEfficiency(elapsed));
            if (ticks > 0)
            {
                IdleSimulator.Advance(state, team, ticks, UserSeed(userId));
            }
        }

        state.LastSimulatedAtUnix = now;
        await _stateStore.SaveAsync(userId, state, ct);

        return new IdleProgress(state, team);
    }

    private async Task<IReadOnlyList<HeroSpec>> BuildTeamAsync(Guid userId, CancellationToken ct)
    {
        var members = await _characters.GetAllAsync(new ActiveTeamByUserSpec(userId), ct);

        var team = new List<HeroSpec>(4);
        foreach (var character in members.Take(4))
        {
            team.Add(new HeroSpec
            {
                CharacterId = character.Id,
                Name = character.Name,
                Class = character.Class,
                Role = character.Role,
                Level = character.Level,
                Stats = await ResolveStatsAsync(character, ct),
            });
        }

        return team;
    }

    /// <summary>Reads the aggregated stats from cache (stats:{id}), rebuilding on miss.</summary>
    private async Task<CharacterStats> ResolveStatsAsync(Character character, CancellationToken ct)
    {
        var cached = await _cache.GetAsync<CharacterStats>($"stats:{character.Id}", ct);
        if (cached is not null)
        {
            return cached;
        }

        var summary = await _statsService.RecalculateAndCacheAsync(character, ct);
        return CharacterStats.FromDictionary(
            summary.Stats.ToDictionary(kv => kv.Key, kv => kv.Value));
    }

    /// <summary>Stable per-user RNG seed derived from the user id bytes.</summary>
    public static int UserSeed(Guid userId) => BitConverter.ToInt32(userId.ToByteArray(), 0) & 0x7FFFFFFF;
}
