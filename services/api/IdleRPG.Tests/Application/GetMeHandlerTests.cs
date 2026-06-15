using FluentAssertions;
using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.UseCases.Auth.GetMe;
using IdleRPG.Domain.Entities;
using Xunit;

namespace IdleRPG.Tests.Application;

[Trait("Phase", "F1")]
public class GetMeHandlerTests
{
    [Fact]
    public async Task Returns_the_current_user_profile()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            SteamId = "76561197960287930",
            Username = "Gabe",
            AccountLevel = 3,
        };
        var users = new InMemoryRepository<User>(u => u.Id);
        users.Items.Add(user);
        var current = new FakeCurrentUserService { UserId = user.Id };

        var handler = new GetMeHandler(current, users);
        var result = await handler.Handle(new GetMeQuery(), CancellationToken.None);

        result.Id.Should().Be(user.Id);
        result.Username.Should().Be("Gabe");
        result.AccountLevel.Should().Be(3);
        result.AccountStatus.Should().Be("active");
    }

    [Fact]
    public async Task Throws_when_not_authenticated()
    {
        var users = new InMemoryRepository<User>(u => u.Id);
        var current = new FakeCurrentUserService { UserId = null };

        var handler = new GetMeHandler(current, users);
        var act = () => handler.Handle(new GetMeQuery(), CancellationToken.None);

        await act.Should().ThrowAsync<AuthenticationException>();
    }

    [Fact]
    public async Task Throws_when_user_no_longer_exists()
    {
        var users = new InMemoryRepository<User>(u => u.Id);
        var current = new FakeCurrentUserService { UserId = Guid.NewGuid() };

        var handler = new GetMeHandler(current, users);
        var act = () => handler.Handle(new GetMeQuery(), CancellationToken.None);

        await act.Should().ThrowAsync<AuthenticationException>();
    }
}
