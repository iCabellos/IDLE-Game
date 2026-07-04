using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Combat;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Combat.GetCombatState;

public sealed class GetCombatStateHandler : IRequestHandler<GetCombatStateQuery, CombatStateDto>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<Character> _characters;
    private readonly IIdleProgressService _progress;
    private readonly IUnitOfWork _uow;

    public GetCombatStateHandler(
        ICurrentUserService currentUser,
        IRepository<Character> characters,
        IIdleProgressService progress,
        IUnitOfWork uow)
    {
        _currentUser = currentUser;
        _characters = characters;
        _progress = progress;
        _uow = uow;
    }

    public async Task<CombatStateDto> Handle(GetCombatStateQuery request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        var progress = await _progress.AdvanceAsync(userId, ct);

        if (progress is null)
        {
            await ProvisionStarterTeamAsync(userId, ct);
            progress = await _progress.AdvanceAsync(userId, ct)
                ?? throw new DomainValidationException("Failed to provision the starter team.");
        }

        var (state, team) = progress;

        return new CombatStateDto
        {
            ZoneName = EnemyCatalog.ZoneName(state.Zone),
            Zone = state.Zone,
            WaveText = $"{state.Wave}/10",
            BossWave = state.Wave == 10,
            Status = CombatText.Status(state),
            StatusText = CombatText.StatusText(state),
            RewardsReady = CombatText.HasRewards(state),
            RewardSummary = CombatText.RewardSummary(state),
            Team = team.Select(ToDto).ToList(),
            EnemyPreview = CombatText.EnemyPreview(state),
            RecentLoot = state.PendingLoot
                .AsEnumerable()
                .Reverse()
                .Take(8)
                .Select(CombatText.ToDto)
                .ToList(),
        };
    }

    private static TeamMemberDto ToDto(HeroSpec hero) => new()
    {
        CharacterId = hero.CharacterId,
        Name = hero.Name,
        Class = hero.Class.ToString(),
        Role = hero.Role.ToString(),
        Level = hero.Level,
        Element = ClassKits.For(hero.Class).DamageType.ToString(),
    };

    /// <summary>
    /// First contact with the idle engine: a fresh account gets the canonical
    /// starter squad (tank / dps / healer / dps) so the game plays instantly.
    /// </summary>
    private async Task ProvisionStarterTeamAsync(Guid userId, CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;
        var starters = new (string Name, CharacterClass Class, CharacterRole Role, int Slot)[]
        {
            ("Vanguard", CharacterClass.Warrior, CharacterRole.Tank, 0),
            ("Ember", CharacterClass.Berserker, CharacterRole.DPS, 1),
            ("Lumen", CharacterClass.Cleric, CharacterRole.Healer, 2),
            ("Frostweaver", CharacterClass.Mage, CharacterRole.DPS, 3),
        };

        foreach (var (name, cls, role, slot) in starters)
        {
            await _characters.AddAsync(new Character
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Name = name,
                Class = cls,
                Role = role,
                Level = 1,
                TeamSlot = slot,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now,
            }, ct);
        }

        await _uow.SaveChangesAsync(ct);
    }
}
