using IdleRPG.Application.DTOs.Items;
using IdleRPG.Domain.Enums;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.EquipItem;

/// <summary>Equips an owned item instance to a character in a target slot.</summary>
public sealed record EquipItemCommand(Guid CharacterId, Guid ItemInstanceId, ItemSlot TargetSlot)
    : IRequest<CharacterSummaryDto>;
