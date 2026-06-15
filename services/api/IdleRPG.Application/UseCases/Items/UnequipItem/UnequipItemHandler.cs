using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Items;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.UnequipItem;

public sealed class UnequipItemHandler : IRequestHandler<UnequipItemCommand, CharacterSummaryDto>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<Character> _characters;
    private readonly IRepository<ItemInstance> _instances;
    private readonly ICharacterStatsService _stats;
    private readonly IUnitOfWork _uow;

    public UnequipItemHandler(
        ICurrentUserService currentUser,
        IRepository<Character> characters,
        IRepository<ItemInstance> instances,
        ICharacterStatsService stats,
        IUnitOfWork uow)
    {
        _currentUser = currentUser;
        _characters = characters;
        _instances = instances;
        _stats = stats;
        _uow = uow;
    }

    public async Task<CharacterSummaryDto> Handle(UnequipItemCommand request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        var character = await _characters.GetByIdAsync(request.CharacterId, ct)
            ?? throw new NotFoundException($"Character {request.CharacterId} not found.");
        if (character.UserId != userId)
        {
            throw new ForbiddenException("Character does not belong to the current user.");
        }

        var instance = await _instances.GetByIdAsync(request.ItemInstanceId, ct)
            ?? throw new NotFoundException($"Item instance {request.ItemInstanceId} not found.");
        if (instance.OwnerId != userId)
        {
            throw new ForbiddenException("Item instance does not belong to the current user.");
        }

        if (instance.EquippedToCharacterId != character.Id)
        {
            throw new DomainValidationException("Item is not equipped to this character.");
        }

        instance.EquippedToCharacterId = null;
        instance.EquippedSlot = null;
        instance.UpdatedAt = DateTimeOffset.UtcNow;
        _instances.Update(instance);

        await _uow.SaveChangesAsync(ct);

        return await _stats.RecalculateAndCacheAsync(character, ct);
    }
}
