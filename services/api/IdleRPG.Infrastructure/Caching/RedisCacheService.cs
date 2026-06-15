using System.Text.Json;
using IdleRPG.Application.Interfaces.Caching;
using Microsoft.Extensions.Caching.Distributed;

namespace IdleRPG.Infrastructure.Caching;

/// <summary>
/// <see cref="ICacheService"/> backed by the distributed (Redis) cache. Values
/// are JSON-serialized; the configured instance prefix (idlerpg:) is applied by
/// the underlying provider.
/// </summary>
public sealed class RedisCacheService : ICacheService
{
    private readonly IDistributedCache _cache;

    public RedisCacheService(IDistributedCache cache)
    {
        _cache = cache;
    }

    public async Task<T?> GetAsync<T>(string key, CancellationToken ct = default)
    {
        var bytes = await _cache.GetAsync(key, ct);
        if (bytes is null || bytes.Length == 0)
        {
            return default;
        }

        return JsonSerializer.Deserialize<T>(bytes);
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken ct = default)
    {
        var bytes = JsonSerializer.SerializeToUtf8Bytes(value);
        var options = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = ttl,
        };
        await _cache.SetAsync(key, bytes, options, ct);
    }

    public Task RemoveAsync(string key, CancellationToken ct = default) =>
        _cache.RemoveAsync(key, ct);
}
