using FluentAssertions;
using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.UseCases.Auth.Logout;
using IdleRPG.Application.UseCases.Auth.RefreshToken;
using IdleRPG.Domain.Entities;
using Xunit;

namespace IdleRPG.Tests.Application;

[Trait("Phase", "F1")]
public class RefreshAndLogoutHandlerTests
{
    private static RefreshToken ActiveToken(User user, FakeJwtTokenService jwt, out string raw)
    {
        (raw, var hash) = jwt.CreateRefreshToken();
        return new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            User = user,
            TokenHash = hash,
            CreatedAt = DateTimeOffset.UtcNow,
            ExpiresAt = DateTimeOffset.UtcNow.AddDays(7),
        };
    }

    [Fact]
    public async Task Refresh_with_valid_token_issues_new_access_token()
    {
        var jwt = new FakeJwtTokenService();
        var user = new User { Id = Guid.NewGuid(), SteamId = "76561197960287930" };
        var tokens = new InMemoryRepository<RefreshToken>(t => t.Id);
        var token = ActiveToken(user, jwt, out var raw);
        tokens.Items.Add(token);

        var handler = new RefreshTokenHandler(jwt, tokens);
        var result = await handler.Handle(new RefreshTokenCommand(raw), CancellationToken.None);

        result.AccessToken.Should().Be($"access-for-{user.Id}");
        result.ExpiresIn.Should().Be(900);
    }

    [Fact]
    public async Task Refresh_with_unknown_token_throws()
    {
        var jwt = new FakeJwtTokenService();
        var tokens = new InMemoryRepository<RefreshToken>(t => t.Id);
        var handler = new RefreshTokenHandler(jwt, tokens);

        var act = () => handler.Handle(new RefreshTokenCommand("nope"), CancellationToken.None);

        await act.Should().ThrowAsync<AuthenticationException>();
    }

    [Fact]
    public async Task Refresh_with_revoked_token_throws()
    {
        var jwt = new FakeJwtTokenService();
        var user = new User { Id = Guid.NewGuid(), SteamId = "76561197960287930" };
        var tokens = new InMemoryRepository<RefreshToken>(t => t.Id);
        var token = ActiveToken(user, jwt, out var raw);
        token.RevokedAt = DateTimeOffset.UtcNow;
        tokens.Items.Add(token);

        var handler = new RefreshTokenHandler(jwt, tokens);
        var act = () => handler.Handle(new RefreshTokenCommand(raw), CancellationToken.None);

        await act.Should().ThrowAsync<AuthenticationException>();
    }

    [Fact]
    public async Task Logout_revokes_the_token()
    {
        var jwt = new FakeJwtTokenService();
        var user = new User { Id = Guid.NewGuid(), SteamId = "76561197960287930" };
        var tokens = new InMemoryRepository<RefreshToken>(t => t.Id);
        var uow = new FakeUnitOfWork();
        var token = ActiveToken(user, jwt, out var raw);
        tokens.Items.Add(token);

        var handler = new LogoutHandler(jwt, tokens, uow);
        await handler.Handle(new LogoutCommand(raw), CancellationToken.None);

        token.RevokedAt.Should().NotBeNull();
        token.IsActive.Should().BeFalse();
        uow.SaveCount.Should().Be(1);
    }

    [Fact]
    public async Task Logout_with_unknown_token_is_a_noop()
    {
        var jwt = new FakeJwtTokenService();
        var tokens = new InMemoryRepository<RefreshToken>(t => t.Id);
        var uow = new FakeUnitOfWork();

        var handler = new LogoutHandler(jwt, tokens, uow);
        await handler.Handle(new LogoutCommand("unknown"), CancellationToken.None);

        uow.SaveCount.Should().Be(0);
    }
}
