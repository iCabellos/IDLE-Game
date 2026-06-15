using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Domain.Interfaces;
using MediatR;
using TokenEntity = IdleRPG.Domain.Entities.RefreshToken;

namespace IdleRPG.Application.UseCases.Auth.RefreshToken;

public sealed class RefreshTokenHandler : IRequestHandler<RefreshTokenCommand, RefreshResultDto>
{
    private readonly IJwtTokenService _jwt;
    private readonly IRepository<TokenEntity> _refreshTokens;

    public RefreshTokenHandler(IJwtTokenService jwt, IRepository<TokenEntity> refreshTokens)
    {
        _jwt = jwt;
        _refreshTokens = refreshTokens;
    }

    public async Task<RefreshResultDto> Handle(RefreshTokenCommand request, CancellationToken ct)
    {
        var hash = _jwt.HashRefreshToken(request.RefreshToken);
        var token = await _refreshTokens.FirstOrDefaultAsync(new RefreshTokenByHashSpec(hash), ct);

        if (token is null || !token.IsActive || token.User is null)
        {
            throw new AuthenticationException("Invalid or expired refresh token.");
        }

        var accessToken = _jwt.CreateAccessToken(token.User);

        return new RefreshResultDto
        {
            AccessToken = accessToken,
            ExpiresIn = _jwt.AccessTokenLifetimeSeconds,
        };
    }
}
