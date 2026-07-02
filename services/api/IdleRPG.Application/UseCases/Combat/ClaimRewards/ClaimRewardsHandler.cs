using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Combat;
using IdleRPG.Application.Interfaces.Caching;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Combat.ClaimRewards;

public sealed class ClaimRewardsHandler : IRequestHandler<ClaimRewardsCommand, ClaimRewardsResultDto>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<Character> _characters;
    private readonly IIdleProgressService _progress;
    private readonly IIdleStateStore _stateStore;
    private readonly ICacheService _cache;
    private readonly IUnitOfWork _uow;

    public ClaimRewardsHandler(
        ICurrentUserService currentUser,
        IRepository<Character> characters,
        IIdleProgressService progress,
        IIdleStateStore stateStore,
        ICacheService cache,
        IUnitOfWork uow)
    {
        _currentUser = currentUser;
        _characters = characters;
        _progress = progress;
        _stateStore = stateStore;
        _cache = cache;
        _uow = uow;
    }

    public async Task<ClaimRewardsResultDto> Handle(ClaimRewardsCommand request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        // Bring the simulation up to date so nothing earned is left behind.
        var progress = await _progress.AdvanceAsync(userId, ct)
            ?? throw new NotFoundException("No active team. Fetch /combat/state first.");

        var (state, team) = progress;

        var highlights = new List<string>();

        if (state.PendingXp > 0)
        {
            var perMember = state.PendingXp / team.Count;

            foreach (var hero in team)
            {
                var character = await _characters.GetByIdAsync(hero.CharacterId, ct);
                if (character is null)
                {
                    continue;
                }

                var before = character.Level;
                (character.Level, character.Experience) =
                    XpCurve.Apply(character.Level, character.Experience, perMember);
                character.UpdatedAt = DateTimeOffset.UtcNow;
                _characters.Update(character);

                if (character.Level > before)
                {
                    highlights.Add($"{character.Name} advanced to level {character.Level}!");
                    // Level changed => cached aggregated stats are stale.
                    await _cache.RemoveAsync($"stats:{character.Id}", ct);
                }
            }

            if (highlights.Count == 0)
            {
                highlights.Add("Experience claimed — the team grows stronger.");
            }

            state.PendingXp = 0;
            await _uow.SaveChangesAsync(ct);
        }

        var drops = state.PendingDrops.Values.Sum();
        if (drops > 0)
        {
            highlights.Add(drops == 1
                ? "1 item is awaiting Steam sync (available once the market link goes live)."
                : $"{drops} items are awaiting Steam sync (available once the market link goes live).");
        }

        var claimed = highlights.Count > 0;
        if (!claimed)
        {
            highlights.Add("Nothing to claim yet — check back soon.");
        }

        await _stateStore.SaveAsync(userId, state, ct);

        // Reload the team so levels in the response reflect the claim.
        var refreshed = await _progress.AdvanceAsync(userId, ct);

        return new ClaimRewardsResultDto
        {
            ClaimedAnything = claimed,
            Highlights = highlights,
            Team = (refreshed?.Team ?? team).Select(h => new TeamMemberDto
            {
                CharacterId = h.CharacterId,
                Name = h.Name,
                Class = h.Class.ToString(),
                Role = h.Role.ToString(),
                Level = h.Level,
                Element = ClassKits.For(h.Class).DamageType.ToString(),
            }).ToList(),
        };
    }
}
