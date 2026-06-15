using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Domain.Interfaces;
using MediatR;
using TokenEntity = IdleRPG.Domain.Entities.RefreshToken;

namespace IdleRPG.Application.UseCases.Auth.Logout;

public sealed class LogoutHandler : IRequestHandler<LogoutCommand, Unit>
{
    private readonly IJwtTokenService _jwt;
    private readonly IRepository<TokenEntity> _refreshTokens;
    private readonly IUnitOfWork _uow;

    public LogoutHandler(IJwtTokenService jwt, IRepository<TokenEntity> refreshTokens, IUnitOfWork uow)
    {
        _jwt = jwt;
        _refreshTokens = refreshTokens;
        _uow = uow;
    }

    public async Task<Unit> Handle(LogoutCommand request, CancellationToken ct)
    {
        if (!string.IsNullOrEmpty(request.RefreshToken))
        {
            var hash = _jwt.HashRefreshToken(request.RefreshToken);
            var token = await _refreshTokens.FirstOrDefaultAsync(new RefreshTokenByHashSpec(hash), ct);

            if (token is not null && token.RevokedAt is null)
            {
                token.RevokedAt = DateTimeOffset.UtcNow;
                _refreshTokens.Update(token);
                await _uow.SaveChangesAsync(ct);
            }
        }

        return Unit.Value;
    }
}
