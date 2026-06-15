using IdleRPG.Application.DTOs.Auth;
using MediatR;

namespace IdleRPG.Application.UseCases.Auth.GetMe;

/// <summary>Returns the profile of the currently-authenticated user.</summary>
public record GetMeQuery : IRequest<UserDto>;
