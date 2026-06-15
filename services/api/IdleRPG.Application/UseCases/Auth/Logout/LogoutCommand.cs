using MediatR;

namespace IdleRPG.Application.UseCases.Auth.Logout;

/// <summary>Revokes the supplied refresh token, ending the session.</summary>
public record LogoutCommand(string RefreshToken) : IRequest<Unit>;
