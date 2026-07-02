using IdleRPG.Application.DTOs.Combat;
using MediatR;

namespace IdleRPG.Application.UseCases.Combat.GetCombatState;

/// <summary>
/// Returns the readable idle-combat state for the current user, advancing
/// the simulation by the elapsed wall-clock time first. Provisions the
/// starter team on first call so a fresh account is immediately playable.
/// </summary>
public sealed record GetCombatStateQuery : IRequest<CombatStateDto>;
