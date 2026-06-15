using FluentAssertions;
using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Application.UseCases.Auth.SteamLogin;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace IdleRPG.Tests.Application;

[Trait("Phase", "F1")]
public class SteamLoginHandlerTests
{
    private const string ValidSteamId = "76561197960287930";

    private static (SteamLoginHandler handler,
        InMemoryRepository<User> users,
        InMemoryRepository<RefreshToken> tokens,
        FakeUnitOfWork uow,
        FakeSteamAuthService steam) BuildSut()
    {
        var users = new InMemoryRepository<User>(u => u.Id);
        var tokens = new InMemoryRepository<RefreshToken>(t => t.Id);
        var uow = new FakeUnitOfWork();
        var steam = new FakeSteamAuthService();
        var jwt = new FakeJwtTokenService();

        var handler = new SteamLoginHandler(
            steam, jwt, users, tokens, uow, NullLogger<SteamLoginHandler>.Instance);

        return (handler, users, tokens, uow, steam);
    }

    [Fact]
    public async Task Invalid_openid_throws_authentication_exception()
    {
        var (handler, _, _, _, steam) = BuildSut();
        steam.SteamIdToReturn = null;

        var act = () => handler.Handle(new SteamLoginCommand("bad"), CancellationToken.None);

        await act.Should().ThrowAsync<AuthenticationException>();
    }

    [Fact]
    public async Task First_login_creates_a_new_user()
    {
        var (handler, users, tokens, uow, steam) = BuildSut();
        steam.SteamIdToReturn = ValidSteamId;
        steam.SummaryToReturn = new SteamPlayerSummary
        {
            SteamId = ValidSteamId,
            PersonaName = "Gabe",
            AvatarUrl = "https://avatar/full.jpg",
        };

        var result = await handler.Handle(new SteamLoginCommand("payload"), CancellationToken.None);

        users.Items.Should().ContainSingle();
        users.Items[0].SteamId.Should().Be(ValidSteamId);
        users.Items[0].Username.Should().Be("Gabe");
        users.Items[0].AccountLevel.Should().Be(1);
        tokens.Items.Should().ContainSingle();
        uow.SaveCount.Should().Be(1);

        result.AccessToken.Should().NotBeNullOrEmpty();
        result.RefreshToken.Should().NotBeNullOrEmpty();
        result.ExpiresIn.Should().Be(900);
        result.User.Username.Should().Be("Gabe");
    }

    [Fact]
    public async Task Returning_user_is_updated_not_duplicated()
    {
        var (handler, users, _, _, steam) = BuildSut();
        users.Items.Add(new User
        {
            Id = Guid.NewGuid(),
            SteamId = ValidSteamId,
            Username = "OldName",
            AccountLevel = 5,
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-10),
        });

        steam.SteamIdToReturn = ValidSteamId;
        steam.SummaryToReturn = new SteamPlayerSummary
        {
            SteamId = ValidSteamId,
            PersonaName = "NewName",
            AvatarUrl = "https://avatar/new.jpg",
        };

        var result = await handler.Handle(new SteamLoginCommand("payload"), CancellationToken.None);

        users.Items.Should().ContainSingle();
        users.Items[0].Username.Should().Be("NewName");
        users.Items[0].AccountLevel.Should().Be(5);
        result.User.AccountLevel.Should().Be(5);
    }

    [Fact]
    public async Task Banned_user_cannot_log_in()
    {
        var (handler, users, _, _, steam) = BuildSut();
        users.Items.Add(new User
        {
            Id = Guid.NewGuid(),
            SteamId = ValidSteamId,
            Username = "Cheater",
            IsBanned = true,
            Status = AccountStatus.Banned,
        });
        steam.SteamIdToReturn = ValidSteamId;

        var act = () => handler.Handle(new SteamLoginCommand("payload"), CancellationToken.None);

        await act.Should().ThrowAsync<AuthenticationException>();
    }

    [Fact]
    public async Task Missing_summary_falls_back_to_generated_username()
    {
        var (handler, users, _, _, steam) = BuildSut();
        steam.SteamIdToReturn = ValidSteamId;
        steam.SummaryToReturn = null;

        await handler.Handle(new SteamLoginCommand("payload"), CancellationToken.None);

        users.Items[0].Username.Should().StartWith("Player_");
    }
}
