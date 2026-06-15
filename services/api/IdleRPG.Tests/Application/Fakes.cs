using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;

namespace IdleRPG.Tests.Application;

/// <summary>In-memory repository that evaluates specification criteria locally.</summary>
public sealed class InMemoryRepository<T> : IRepository<T> where T : class
{
    public List<T> Items { get; } = new();
    private readonly Func<T, Guid> _idSelector;

    public InMemoryRepository(Func<T, Guid> idSelector)
    {
        _idSelector = idSelector;
    }

    public Task<T?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => Task.FromResult(Items.FirstOrDefault(x => _idSelector(x) == id));

    public Task<IReadOnlyList<T>> GetAllAsync(ISpecification<T>? specification = null, CancellationToken ct = default)
    {
        IEnumerable<T> q = Items;
        if (specification?.Criteria is not null)
        {
            q = q.Where(specification.Criteria.Compile());
        }
        return Task.FromResult<IReadOnlyList<T>>(q.ToList());
    }

    public Task<T?> FirstOrDefaultAsync(ISpecification<T> specification, CancellationToken ct = default)
    {
        IEnumerable<T> q = Items;
        if (specification.Criteria is not null)
        {
            q = q.Where(specification.Criteria.Compile());
        }
        return Task.FromResult(q.FirstOrDefault());
    }

    public Task AddAsync(T entity, CancellationToken ct = default)
    {
        Items.Add(entity);
        return Task.CompletedTask;
    }

    public void Update(T entity)
    {
        // In-memory: entity is mutated in place, nothing to do.
    }

    public void Delete(T entity) => Items.Remove(entity);
}

/// <summary>No-op unit of work that records how many times it was saved.</summary>
public sealed class FakeUnitOfWork : IUnitOfWork
{
    public int SaveCount { get; private set; }

    public Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        SaveCount++;
        return Task.FromResult(1);
    }

    public Task BeginTransactionAsync(CancellationToken ct = default) => Task.CompletedTask;
    public Task CommitAsync(CancellationToken ct = default) => Task.CompletedTask;
    public Task RollbackAsync(CancellationToken ct = default) => Task.CompletedTask;
}

/// <summary>Deterministic token service used in handler tests.</summary>
public sealed class FakeJwtTokenService : IJwtTokenService
{
    public int AccessTokenLifetimeSeconds => 900;
    public int RefreshTokenLifetimeDays => 7;

    public string CreateAccessToken(User user) => $"access-for-{user.Id}";

    public (string RawToken, string TokenHash) CreateRefreshToken()
    {
        var raw = Guid.NewGuid().ToString("N");
        return (raw, HashRefreshToken(raw));
    }

    public string HashRefreshToken(string rawToken) => $"hash:{rawToken}";
}

/// <summary>Configurable Steam auth fake.</summary>
public sealed class FakeSteamAuthService : ISteamAuthService
{
    public string? SteamIdToReturn { get; set; }
    public SteamPlayerSummary? SummaryToReturn { get; set; }

    public Task<string?> ValidateOpenIdAsync(string openIdPayload, CancellationToken ct = default)
        => Task.FromResult(SteamIdToReturn);

    public Task<SteamPlayerSummary?> GetPlayerSummaryAsync(string steamId, CancellationToken ct = default)
        => Task.FromResult(SummaryToReturn);
}

/// <summary>Current-user fake.</summary>
public sealed class FakeCurrentUserService : ICurrentUserService
{
    public Guid? UserId { get; set; }
    public string? SteamId { get; set; }
    public bool IsAuthenticated => UserId is not null;
}
