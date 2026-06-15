using IdleRPG.Application.DTOs.Items;
using IdleRPG.Domain.Entities;

namespace IdleRPG.Application.Interfaces.Items;

/// <summary>
/// Recomputes a character's effective stats from its equipped loadout, caches
/// the result (Redis key <c>stats:{characterId}</c>, 1h TTL) and projects a
/// human-readable summary.
/// </summary>
public interface ICharacterStatsService
{
    Task<CharacterSummaryDto> RecalculateAndCacheAsync(Character character, CancellationToken ct = default);
}
