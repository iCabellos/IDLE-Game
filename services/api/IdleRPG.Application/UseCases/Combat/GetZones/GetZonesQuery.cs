using IdleRPG.Application.DTOs.Combat;
using MediatR;

namespace IdleRPG.Application.UseCases.Combat.GetZones;

/// <summary>Lists zones around the user's current progression point.</summary>
public sealed record GetZonesQuery : IRequest<IReadOnlyList<ZoneDto>>;
