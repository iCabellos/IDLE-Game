using System.IdentityModel.Tokens.Jwt;
using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Infrastructure.Auth;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace IdleRPG.Tests.Infrastructure;

[Trait("Phase", "F1")]
public class JwtTokenServiceTests
{
    private static JwtTokenService BuildService()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["JWT_SECRET"] = "super-secret-test-key-that-is-long-enough-32b",
                ["JWT_ISSUER"] = "idlerpg",
                ["JWT_AUDIENCE"] = "idlerpg-client",
            })
            .Build();
        return new JwtTokenService(config);
    }

    [Fact]
    public void Access_token_contains_expected_claims()
    {
        var service = BuildService();
        var user = new User
        {
            Id = Guid.NewGuid(),
            SteamId = "76561197960287930",
            Username = "Gabe",
        };

        var token = service.CreateAccessToken(user);
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        jwt.Subject.Should().Be(user.Id.ToString());
        jwt.Claims.Should().Contain(c => c.Type == "steam" && c.Value == user.SteamId);
        jwt.Claims.Should().Contain(c => c.Type == "name" && c.Value == "Gabe");
        jwt.Issuer.Should().Be("idlerpg");
    }

    [Fact]
    public void Access_token_expires_in_15_minutes()
    {
        var service = BuildService();
        service.AccessTokenLifetimeSeconds.Should().Be(900);

        var token = service.CreateAccessToken(new User { Id = Guid.NewGuid(), SteamId = "1", Username = "x" });
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        (jwt.ValidTo - jwt.ValidFrom).TotalSeconds.Should().BeApproximately(900, 5);
    }

    [Fact]
    public void Refresh_token_hash_is_deterministic_and_distinct_from_raw()
    {
        var service = BuildService();
        var (raw, hash) = service.CreateRefreshToken();

        raw.Should().NotBe(hash);
        service.HashRefreshToken(raw).Should().Be(hash);
    }

    [Fact]
    public void Missing_secret_throws()
    {
        var config = new ConfigurationBuilder().Build();
        var act = () => new JwtTokenService(config);
        act.Should().Throw<InvalidOperationException>();
    }
}
