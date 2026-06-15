using IdleRPG.Application.DTOs.Auth;
using MediatR;

namespace IdleRPG.Application.UseCases.Auth.RefreshToken;

/// <summary>Exchanges a valid refresh token for a fresh access token.</summary>
public record RefreshTokenCommand(string RefreshToken) : IRequest<RefreshResultDto>;
