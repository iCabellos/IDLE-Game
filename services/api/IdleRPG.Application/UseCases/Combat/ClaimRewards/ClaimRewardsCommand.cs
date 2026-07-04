using IdleRPG.Application.DTOs.Combat;
using MediatR;

namespace IdleRPG.Application.UseCases.Combat.ClaimRewards;

/// <summary>
/// Claims pending idle rewards: experience is applied to the active team
/// (levelling characters up through the XP curve). Item drops remain
/// "awaiting Steam sync" until the Steam integration (F5) materialises them.
/// </summary>
public sealed record ClaimRewardsCommand : IRequest<ClaimRewardsResultDto>;
