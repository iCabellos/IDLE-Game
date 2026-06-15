using IdleRPG.Application.DTOs.Items;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.UnequipItem;

/// <summary>Removes an equipped item instance from its character.</summary>
public sealed record UnequipItemCommand(Guid CharacterId, Guid ItemInstanceId)
    : IRequest<CharacterSummaryDto>;
