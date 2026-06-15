using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.Common.Specifications;
using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.Interfaces;
using MediatR;
using Microsoft.Extensions.Logging;
using TokenEntity = IdleRPG.Domain.Entities.RefreshToken;

namespace IdleRPG.Application.UseCases.Auth.SteamLogin;

public sealed class SteamLoginHandler : IRequestHandler<SteamLoginCommand, LoginResultDto>
{
    private readonly ISteamAuthService _steam;
    private readonly IJwtTokenService _jwt;
    private readonly IRepository<User> _users;
    private readonly IRepository<TokenEntity> _refreshTokens;
    private readonly IUnitOfWork _uow;
    private readonly ILogger<SteamLoginHandler> _logger;

    public SteamLoginHandler(
        ISteamAuthService steam,
        IJwtTokenService jwt,
        IRepository<User> users,
        IRepository<TokenEntity> refreshTokens,
        IUnitOfWork uow,
        ILogger<SteamLoginHandler> logger)
    {
        _steam = steam;
        _jwt = jwt;
        _users = users;
        _refreshTokens = refreshTokens;
        _uow = uow;
        _logger = logger;
    }

    public async Task<LoginResultDto> Handle(SteamLoginCommand request, CancellationToken ct)
    {
        // 1. Verify the OpenID 2.0 signature against steamcommunity.com.
        var steamId = await _steam.ValidateOpenIdAsync(request.OpenIdPayload, ct);
        if (string.IsNullOrEmpty(steamId))
        {
            throw new AuthenticationException("Steam OpenID validation failed.");
        }

        // 2. Fetch the player's public profile (persona name + avatar).
        var summary = await _steam.GetPlayerSummaryAsync(steamId, ct);

        // 3. Upsert the user.
        var user = await _users.FirstOrDefaultAsync(new UserBySteamIdSpec(steamId), ct);
        var now = DateTimeOffset.UtcNow;

        if (user is null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                SteamId = steamId,
                Username = summary?.PersonaName ?? $"Player_{steamId[^4..]}",
                AvatarUrl = summary?.AvatarUrl ?? string.Empty,
                AccountLevel = 1,
                Status = AccountStatus.Active,
                CreatedAt = now,
                LastLoginAt = now,
            };
            await _users.AddAsync(user, ct);
            _logger.LogInformation("Registered new user for Steam id {SteamId}", steamId);
        }
        else
        {
            if (summary is not null)
            {
                user.Username = summary.PersonaName;
                user.AvatarUrl = summary.AvatarUrl;
            }
            user.LastLoginAt = now;
            _users.Update(user);
        }

        if (user.IsBanned || user.Status == AccountStatus.Banned)
        {
            throw new AuthenticationException("This account is banned.");
        }

        // 4. Issue tokens.
        var accessToken = _jwt.CreateAccessToken(user);
        var (rawRefresh, refreshHash) = _jwt.CreateRefreshToken();

        var refreshToken = new TokenEntity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = refreshHash,
            CreatedAt = now,
            ExpiresAt = now.AddDays(_jwt.RefreshTokenLifetimeDays),
        };
        await _refreshTokens.AddAsync(refreshToken, ct);

        await _uow.SaveChangesAsync(ct);

        return new LoginResultDto
        {
            AccessToken = accessToken,
            RefreshToken = rawRefresh,
            ExpiresIn = _jwt.AccessTokenLifetimeSeconds,
            User = ToDto(user),
        };
    }

    private static UserDto ToDto(User user) => new()
    {
        Id = user.Id,
        SteamId = user.SteamId,
        Username = user.Username,
        AvatarUrl = user.AvatarUrl,
        AccountLevel = user.AccountLevel,
        AccountStatus = user.Status.ToString().ToLowerInvariant(),
        CreatedAt = user.CreatedAt,
        LastLoginAt = user.LastLoginAt,
    };
}
