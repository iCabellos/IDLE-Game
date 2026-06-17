using System.Text.Json;
using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.Interfaces.Game;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Infrastructure.Persistence;
using IdleRPG.Infrastructure.Persistence.Seed;
using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Game;

/// <summary>
/// Server-authoritative idle game. State lives in <c>game_runs</c>; combat
/// advances by REAL elapsed time (1 tick/second) so it is consistent whether
/// driven by a client read or by the 24/7 Hangfire tick job.
/// </summary>
public sealed class GameService : IGameService
{
    private const double TickIntervalSeconds = 3.0; // slower, clearer turns
    private const int MaxCatchUpTicks = 400; // cap a single advance (~20 min)

    private static readonly Guid PreviewUserId = SeedIds.From("user:preview");
    private static readonly JsonSerializerOptions Json = new();

    private readonly IRepository<GameRun> _runs;
    private readonly IRepository<Character> _characters;
    private readonly IUnitOfWork _uow;
    private readonly AppDbContext _db;

    public GameService(
        IRepository<GameRun> runs,
        IRepository<Character> characters,
        IUnitOfWork uow,
        AppDbContext db)
    {
        _runs = runs;
        _characters = characters;
        _uow = uow;
        _db = db;
    }

    public Task<GameSnapshot> GetPreviewStateAsync(CancellationToken ct = default)
        => GetStateAsync(PreviewUserId, ct);

    public async Task<GameSnapshot> GetStateAsync(Guid userId, CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var run = await _runs.FirstOrDefaultAsync(new GameRunByUserSpec(userId), ct);

        if (run is null)
        {
            try
            {
                run = await CreateRunAsync(userId, now, ct);
            }
            catch (DbUpdateException)
            {
                // Lost a creation race with a concurrent request; drop the
                // failed insert and read the run the winner committed.
                _db.ChangeTracker.Clear();
                run = await _runs.FirstOrDefaultAsync(new GameRunByUserSpec(userId), ct)
                      ?? throw new InvalidOperationException("Game run missing after creation race.");
            }
        }
        else if (Advance(run, now))
        {
            _runs.Update(run);
            await _uow.SaveChangesAsync(ct);
        }

        return IdleEngine.ToSnapshot(Deserialize(run.StateJson));
    }

    public async Task TickAllAsync(CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow;
        var runs = await _runs.GetAllAsync(null, ct);
        var changed = false;

        foreach (var run in runs)
        {
            if (Advance(run, now))
            {
                _runs.Update(run);
                changed = true;
            }
        }

        if (changed)
        {
            await _uow.SaveChangesAsync(ct);
        }
    }

    // -- helpers ------------------------------------------------------------

    private async Task<GameRun> CreateRunAsync(Guid userId, DateTimeOffset now, CancellationToken ct)
    {
        var characters = await _characters.GetAllAsync(new CharactersByUserSpec(userId), ct);

        var heroes = characters.Count > 0
            ? characters
                .Take(3)
                .Select(c => (c.Id.ToString(), c.Name, ArchetypeFor(c.Class), c.Level))
                .ToList()
            : DefaultHeroes();

        var state = IdleEngine.Start(heroes);

        var run = new GameRun
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            LevelIndex = state.LevelIndex,
            PhaseIndex = state.PhaseIndex,
            WaveIndex = state.WaveIndex,
            TickCount = state.Tick,
            StateJson = Serialize(state),
            CreatedAt = now,
            UpdatedAt = now,
        };

        await _runs.AddAsync(run, ct);
        await _uow.SaveChangesAsync(ct);
        return run;
    }

    /// <summary>Advances a run by elapsed real time. Returns true if it changed.</summary>
    private static bool Advance(GameRun run, DateTimeOffset now)
    {
        var rawTicks = (int)Math.Floor((now - run.UpdatedAt).TotalSeconds / TickIntervalSeconds);
        if (rawTicks <= 0)
        {
            return false;
        }

        var ticks = Math.Min(rawTicks, MaxCatchUpTicks);
        var state = Deserialize(run.StateJson);
        var rng = new Random();

        for (var i = 0; i < ticks; i++)
        {
            IdleEngine.Step(state, rng);
        }

        run.LevelIndex = state.LevelIndex;
        run.PhaseIndex = state.PhaseIndex;
        run.WaveIndex = state.WaveIndex;
        run.TickCount = state.Tick;
        run.StateJson = Serialize(state);
        run.UpdatedAt = rawTicks > MaxCatchUpTicks
            ? now
            : run.UpdatedAt.AddSeconds(ticks * TickIntervalSeconds);
        return true;
    }

    private static string ArchetypeFor(CharacterClass c) => c switch
    {
        CharacterClass.Warrior or CharacterClass.Paladin => "defense",
        CharacterClass.Mage or CharacterClass.Elementalist or CharacterClass.Necromancer => "magic",
        CharacterClass.Rogue or CharacterClass.Trickster => "critDamage",
        CharacterClass.Cleric => "support",
        CharacterClass.Ranger => "physical",
        CharacterClass.Berserker => "fury",
        _ => "physical",
    };

    private static List<(string, string, string, int)> DefaultHeroes() => new()
    {
        ("h_knight", "Sir Cinder", "defense", 1),
        ("h_mage", "Lyra Vex", "magic", 1),
        ("h_ranger", "Fenn Wilde", "physical", 1),
    };

    private static string Serialize(GameState state) => JsonSerializer.Serialize(state, Json);

    private static GameState Deserialize(string json) =>
        string.IsNullOrWhiteSpace(json) || json == "{}"
            ? new GameState()
            : JsonSerializer.Deserialize<GameState>(json, Json) ?? new GameState();
}
