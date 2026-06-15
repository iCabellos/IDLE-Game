using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Auth.GetMe;

public sealed class GetMeHandler : IRequestHandler<GetMeQuery, UserDto>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<User> _users;

    public GetMeHandler(ICurrentUserService currentUser, IRepository<User> users)
    {
        _currentUser = currentUser;
        _users = users;
    }

    public async Task<UserDto> Handle(GetMeQuery request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        var user = await _users.GetByIdAsync(userId, ct)
                   ?? throw new AuthenticationException("User not found.");

        return new UserDto
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
}
