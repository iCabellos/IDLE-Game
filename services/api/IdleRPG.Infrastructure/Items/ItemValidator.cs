using IdleRPG.Application.Common;
using IdleRPG.Application.Interfaces.Caching;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;

namespace IdleRPG.Infrastructure.Items;

/// <summary>
/// Validates item ownership against Steam (with retry + Redis caching) and the
/// static equip rules (slot compatibility, class restriction).
/// </summary>
public sealed class ItemValidator : IItemValidator
{
    private static readonly TimeSpan OwnershipCacheTtl = TimeSpan.FromMinutes(5);
    private const int MaxAttempts = 3;

    private readonly ISteamInventoryService _steam;
    private readonly ICacheService _cache;
    private readonly Func<int, TimeSpan> _backoff;

    public ItemValidator(ISteamInventoryService steam, ICacheService cache)
        : this(steam, cache, attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)))
    {
    }

    /// <summary>Test-friendly constructor allowing the retry backoff to be overridden.</summary>
    public ItemValidator(ISteamInventoryService steam, ICacheService cache, Func<int, TimeSpan> backoff)
    {
        _steam = steam;
        _cache = cache;
        _backoff = backoff;
    }

    public async Task<ValidationResult> ValidateSteamOwnershipAsync(
        string steamId, string steamInventoryId, CancellationToken ct = default)
    {
        var cacheKey = $"steam:owns:{steamId}:{steamInventoryId}";

        var cached = await _cache.GetAsync<bool?>(cacheKey, ct);
        if (cached is { } cachedOwns)
        {
            return cachedOwns
                ? ValidationResult.Success()
                : ValidationResult.Fail("Steam ownership could not be verified.");
        }

        Exception? lastError = null;
        for (var attempt = 0; attempt < MaxAttempts; attempt++)
        {
            try
            {
                var owns = await _steam.OwnsAssetAsync(steamId, steamInventoryId, ct);
                await _cache.SetAsync(cacheKey, owns, OwnershipCacheTtl, ct);
                return owns
                    ? ValidationResult.Success()
                    : ValidationResult.Fail("Steam ownership could not be verified.");
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                lastError = ex;
                if (attempt < MaxAttempts - 1)
                {
                    // Exponential backoff: 1s, 2s, 4s.
                    await Task.Delay(_backoff(attempt), ct);
                }
            }
        }

        return ValidationResult.Fail(
            $"Steam ownership check failed after {MaxAttempts} attempts: {lastError?.Message}");
    }

    public ValidationResult ValidateSlotCompatibility(Character character, Item item, ItemSlot slot)
    {
        if (item.Slot != slot)
        {
            return ValidationResult.Fail(
                $"Item '{item.Name}' fits the {item.Slot} slot, not {slot}.");
        }

        return ValidationResult.Success();
    }

    public ValidationResult ValidateCharacterRestriction(Character character, Item item)
    {
        if (item.CharacterRestriction is { } required && required != character.Class)
        {
            return ValidationResult.Fail(
                $"Item '{item.Name}' is restricted to the {required} class.");
        }

        return ValidationResult.Success();
    }
}
