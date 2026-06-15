using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.DTOs.Items;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.EquipItem;

public sealed class EquipItemHandler : IRequestHandler<EquipItemCommand, CharacterSummaryDto>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<Character> _characters;
    private readonly IRepository<ItemInstance> _instances;
    private readonly IRepository<Item> _items;
    private readonly IItemValidator _validator;
    private readonly ICharacterStatsService _stats;
    private readonly IUnitOfWork _uow;

    public EquipItemHandler(
        ICurrentUserService currentUser,
        IRepository<Character> characters,
        IRepository<ItemInstance> instances,
        IRepository<Item> items,
        IItemValidator validator,
        ICharacterStatsService stats,
        IUnitOfWork uow)
    {
        _currentUser = currentUser;
        _characters = characters;
        _instances = instances;
        _items = items;
        _validator = validator;
        _stats = stats;
        _uow = uow;
    }

    public async Task<CharacterSummaryDto> Handle(EquipItemCommand request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        // 1. Character must exist and belong to the current user.
        var character = await _characters.GetByIdAsync(request.CharacterId, ct)
            ?? throw new NotFoundException($"Character {request.CharacterId} not found.");
        if (character.UserId != userId)
        {
            throw new ForbiddenException("Character does not belong to the current user.");
        }

        // 2. Item instance must exist and be owned by the current user.
        var instance = await _instances.GetByIdAsync(request.ItemInstanceId, ct)
            ?? throw new NotFoundException($"Item instance {request.ItemInstanceId} not found.");
        if (instance.OwnerId != userId)
        {
            throw new ForbiddenException("Item instance does not belong to the current user.");
        }

        var definition = await _items.GetByIdAsync(instance.ItemId, ct)
            ?? throw new NotFoundException($"Item definition {instance.ItemId} not found.");

        // 3. Steam ownership (cached 5 min, retried with backoff).
        var ownership = await _validator.ValidateSteamOwnershipAsync(
            _currentUser.SteamId ?? string.Empty, instance.SteamInventoryId, ct);
        if (!ownership.IsValid)
        {
            throw new DomainValidationException(ownership.Error ?? "Steam ownership check failed.");
        }

        // 4. Slot + class restriction.
        var slotCheck = _validator.ValidateSlotCompatibility(character, definition, request.TargetSlot);
        if (!slotCheck.IsValid)
        {
            throw new DomainValidationException(slotCheck.Error!);
        }

        var restrictionCheck = _validator.ValidateCharacterRestriction(character, definition);
        if (!restrictionCheck.IsValid)
        {
            throw new DomainValidationException(restrictionCheck.Error!);
        }

        // 5. Evict items occupying conflicting slots.
        var equipped = await _instances.GetAllAsync(
            new EquippedItemsByCharacterSpec(character.Id), ct);

        foreach (var occupant in equipped)
        {
            if (occupant.Id == instance.Id)
            {
                continue;
            }

            if (ConflictsWith(request.TargetSlot, occupant.EquippedSlot))
            {
                Unequip(occupant);
            }
        }

        // 6. Equip the requested instance.
        instance.EquippedToCharacterId = character.Id;
        instance.EquippedSlot = request.TargetSlot;
        instance.UpdatedAt = DateTimeOffset.UtcNow;
        _instances.Update(instance);

        await _uow.SaveChangesAsync(ct);

        // 7. Recompute + cache stats, then return the summary.
        return await _stats.RecalculateAndCacheAsync(character, ct);
    }

    /// <summary>
    /// Two-handed weapons conflict with both one-handed slots and vice versa;
    /// otherwise a slot only conflicts with itself.
    /// </summary>
    private static bool ConflictsWith(ItemSlot target, ItemSlot? occupied)
    {
        if (occupied is not { } slot)
        {
            return false;
        }

        if (target == ItemSlot.TwoHand)
        {
            return slot is ItemSlot.MainHand or ItemSlot.OffHand or ItemSlot.TwoHand;
        }

        if (target is ItemSlot.MainHand or ItemSlot.OffHand)
        {
            return slot == target || slot == ItemSlot.TwoHand;
        }

        return slot == target;
    }

    private void Unequip(ItemInstance occupant)
    {
        occupant.EquippedToCharacterId = null;
        occupant.EquippedSlot = null;
        occupant.UpdatedAt = DateTimeOffset.UtcNow;
        _instances.Update(occupant);
    }
}
