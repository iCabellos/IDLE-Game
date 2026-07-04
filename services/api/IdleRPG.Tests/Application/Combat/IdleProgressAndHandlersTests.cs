using FluentAssertions;
using IdleRPG.Application.DTOs.Items;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Application.Services;
using IdleRPG.Application.UseCases.Combat.ClaimRewards;
using IdleRPG.Application.UseCases.Combat.GetCombatState;
using IdleRPG.Application.UseCases.Combat.GetZones;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.GameData;

namespace IdleRPG.Tests.Application.Combat;

/// <summary>In-memory idle state store for handler tests.</summary>
public sealed class FakeIdleStateStore : IIdleStateStore
{
    public Dictionary<Guid, IdleState> States { get; } = new();

    public Task<IdleState?> GetAsync(Guid userId, CancellationToken ct = default)
        => Task.FromResult(States.TryGetValue(userId, out var s) ? s : null);

    public Task SaveAsync(Guid userId, IdleState state, CancellationToken ct = default)
    {
        States[userId] = state;
        return Task.CompletedTask;
    }
}

/// <summary>Stats service fake: returns bare class stats for the character.</summary>
public sealed class FakeCharacterStatsService : ICharacterStatsService
{
    public Task<CharacterSummaryDto> RecalculateAndCacheAsync(
        Character character, CancellationToken ct = default)
    {
        var stats = ClassBaseStats.For(character.Class, character.Level);
        return Task.FromResult(new CharacterSummaryDto
        {
            CharacterId = character.Id,
            Name = character.Name,
            Class = character.Class.ToString(),
            Role = character.Role.ToString(),
            Level = character.Level,
            Stats = new Dictionary<string, float>(stats.ToDictionary()),
        });
    }
}

[Trait("Phase", "F4")]
public class IdleProgressAndHandlersTests
{
    private readonly Guid _userId = Guid.NewGuid();
    private readonly FakeCurrentUserService _currentUser;
    private readonly InMemoryRepository<Character> _characters = new(c => c.Id);
    private readonly FakeIdleStateStore _store = new();
    private readonly FakeCacheService _cache = new();
    private readonly FakeUnitOfWork _uow = new();
    private readonly IdleProgressService _progress;

    public IdleProgressAndHandlersTests()
    {
        _currentUser = new FakeCurrentUserService { UserId = _userId };
        _progress = new IdleProgressService(
            _characters, _store, _cache, new FakeCharacterStatsService());
    }

    private GetCombatStateHandler StateHandler() =>
        new(_currentUser, _characters, _progress, _uow);

    [Fact]
    public async Task First_state_call_provisions_the_starter_team()
    {
        var dto = await StateHandler().Handle(new GetCombatStateQuery(), CancellationToken.None);

        _characters.Items.Should().HaveCount(4, "a fresh account gets the starter squad");
        dto.Team.Should().HaveCount(4);
        dto.Team.Select(t => t.Role).Should().Contain(new[] { "Tank", "Healer", "DPS" });
        dto.Zone.Should().Be(1);
        dto.WaveText.Should().Be("1/10");
        _store.States.Should().ContainKey(_userId);
    }

    [Fact]
    public async Task State_exposes_only_readable_statuses()
    {
        var dto = await StateHandler().Handle(new GetCombatStateQuery(), CancellationToken.None);

        new[] { "winning", "danger", "stuck", "rewards_ready", "steam_desynced" }
            .Should().Contain(dto.Status);
        dto.StatusText.Should().NotBeNullOrWhiteSpace();
        dto.EnemyPreview.Enemies.Should().NotBeEmpty();
        dto.EnemyPreview.Weaknesses.Should().NotBeEmpty("weaknesses guide gear choice");
    }

    [Fact]
    public async Task Elapsed_time_advances_the_simulation_and_accrues_rewards()
    {
        await StateHandler().Handle(new GetCombatStateQuery(), CancellationToken.None);

        // Pretend the last simulation happened an hour ago.
        var state = _store.States[_userId];
        state.LastSimulatedAtUnix = DateTimeOffset.UtcNow.AddHours(-1).ToUnixTimeSeconds();

        var dto = await StateHandler().Handle(new GetCombatStateQuery(), CancellationToken.None);

        _store.States[_userId].BattleCounter.Should().BeGreaterThan(0, "an hour idle must fight battles");
        _store.States[_userId].PendingXp.Should().BeGreaterThan(0);
        dto.RewardsReady.Should().BeTrue();
        dto.Status.Should().BeOneOf("rewards_ready", "danger", "stuck");
    }

    [Fact]
    public async Task Claim_applies_xp_levels_up_and_invalidates_stats_cache()
    {
        await StateHandler().Handle(new GetCombatStateQuery(), CancellationToken.None);

        var state = _store.States[_userId];
        state.PendingXp = 10_000; // enough for several level-1 -> N ups
        _cache.Store[$"stats:{_characters.Items[0].Id}"] =
            ClassBaseStats.For(_characters.Items[0].Class, 1);

        var handler = new ClaimRewardsHandler(
            _currentUser, _characters, _progress, _store, _cache, _uow);
        var result = await handler.Handle(new ClaimRewardsCommand(), CancellationToken.None);

        result.ClaimedAnything.Should().BeTrue();
        result.Highlights.Should().Contain(h => h.Contains("advanced to level"));
        _characters.Items.Should().OnlyContain(c => c.Level > 1, "10k XP levels every starter");
        _store.States[_userId].PendingXp.Should().Be(0);
        _cache.Store.Keys.Should().NotContain(
            $"stats:{_characters.Items[0].Id}", "level-ups must invalidate cached stats");
    }

    [Fact]
    public async Task Claim_with_nothing_pending_reports_gracefully()
    {
        await StateHandler().Handle(new GetCombatStateQuery(), CancellationToken.None);
        _store.States[_userId].PendingXp = 0;
        _store.States[_userId].PendingLoot.Clear();
        _store.States[_userId].OverflowLoot = 0;

        var handler = new ClaimRewardsHandler(
            _currentUser, _characters, _progress, _store, _cache, _uow);
        var result = await handler.Handle(new ClaimRewardsCommand(), CancellationToken.None);

        result.ClaimedAnything.Should().BeFalse();
        result.Highlights.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Zones_list_marks_cleared_current_and_locked()
    {
        _store.States[_userId] = new IdleState { Zone = 3, Wave = 4 };

        var handler = new GetZonesHandler(_currentUser, _store);
        var zones = await handler.Handle(new GetZonesQuery(), CancellationToken.None);

        zones.Should().HaveCount(5);
        zones.Single(z => z.Zone == 3).Status.Should().Be("current");
        zones.Where(z => z.Zone < 3).Should().OnlyContain(z => z.Status == "cleared");
        zones.Where(z => z.Zone > 3).Should().OnlyContain(z => z.Status == "locked");
        zones.Should().OnlyContain(z => !string.IsNullOrWhiteSpace(z.Name));
    }

    [Fact]
    public async Task Progress_service_returns_null_without_a_team()
    {
        var result = await _progress.AdvanceAsync(Guid.NewGuid());

        result.Should().BeNull();
    }

    [Fact]
    public void User_seed_is_stable_for_the_same_user()
    {
        var id = Guid.NewGuid();

        IdleProgressService.UserSeed(id).Should().Be(IdleProgressService.UserSeed(id));
        IdleProgressService.UserSeed(id).Should().BeGreaterThanOrEqualTo(0);
    }
}
