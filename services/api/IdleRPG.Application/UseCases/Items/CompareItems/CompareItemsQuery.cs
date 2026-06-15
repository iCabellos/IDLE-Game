using IdleRPG.Application.DTOs.Items;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.CompareItems;

/// <summary>Produces a descriptive (non-numeric-first) comparison of two instances.</summary>
public sealed record CompareItemsQuery(Guid InstanceId1, Guid InstanceId2)
    : IRequest<ItemComparisonDto>;
