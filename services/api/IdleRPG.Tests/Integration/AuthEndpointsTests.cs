using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Tests.Application;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Xunit;

namespace IdleRPG.Tests.Integration;

/// <summary>
/// End-to-end auth flow against real PostgreSQL/Redis containers, with the
/// Steam service replaced by a fake so OpenID verification is deterministic.
/// </summary>
[Trait("Phase", "F1")]
[Collection("Integration")]
public class AuthEndpointsTests : ApiTestBase
{
    private const string SteamId = "76561197960287930";

    private readonly FakeSteamAuthService _steam = new()
    {
        SteamIdToReturn = SteamId,
        SummaryToReturn = new SteamPlayerSummary
        {
            SteamId = SteamId,
            PersonaName = "IntegrationTester",
            AvatarUrl = "https://avatar/full.jpg",
        },
    };

    protected override void ConfigureTestServices(IServiceCollection services)
    {
        services.RemoveAll<ISteamAuthService>();
        services.AddScoped<ISteamAuthService>(_ => _steam);
    }

    [Fact]
    public async Task Get_me_without_token_returns_401()
    {
        var response = await Client.GetAsync("/auth/me");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Steam_login_with_empty_payload_returns_400()
    {
        var response = await Client.PostAsJsonAsync("/auth/steam/login",
            new { openIdPayload = "" });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Refresh_with_invalid_token_returns_401()
    {
        var response = await Client.PostAsJsonAsync("/auth/refresh",
            new { refreshToken = "definitely-not-valid" });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Full_login_flow_issues_usable_tokens()
    {
        // 1. Login.
        var loginResponse = await Client.PostAsJsonAsync("/auth/steam/login",
            new { openIdPayload = "openid.claimed_id=https://steamcommunity.com/openid/id/" + SteamId });
        loginResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var login = await loginResponse.Content.ReadFromJsonAsync<LoginResultDto>();
        login.Should().NotBeNull();
        login!.AccessToken.Should().NotBeNullOrEmpty();
        login.RefreshToken.Should().NotBeNullOrEmpty();
        login.User.Username.Should().Be("IntegrationTester");

        // 2. Use the access token on /auth/me.
        using var meRequest = new HttpRequestMessage(HttpMethod.Get, "/auth/me");
        meRequest.Headers.Authorization = new("Bearer", login.AccessToken);
        var meResponse = await Client.SendAsync(meRequest);
        meResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var me = await meResponse.Content.ReadFromJsonAsync<UserDto>();
        me!.SteamId.Should().Be(SteamId);

        // 3. Refresh the access token.
        var refreshResponse = await Client.PostAsJsonAsync("/auth/refresh",
            new { refreshToken = login.RefreshToken });
        refreshResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var refreshed = await refreshResponse.Content.ReadFromJsonAsync<RefreshResultDto>();
        refreshed!.AccessToken.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task Logout_revokes_refresh_token()
    {
        // Login first.
        var loginResponse = await Client.PostAsJsonAsync("/auth/steam/login",
            new { openIdPayload = "openid.claimed_id=https://steamcommunity.com/openid/id/" + SteamId });
        var login = await loginResponse.Content.ReadFromJsonAsync<LoginResultDto>();

        // Logout (requires auth).
        using var logoutRequest = new HttpRequestMessage(HttpMethod.Delete, "/auth/logout")
        {
            Content = JsonContent.Create(new { refreshToken = login!.RefreshToken }),
        };
        logoutRequest.Headers.Authorization = new("Bearer", login.AccessToken);
        var logoutResponse = await Client.SendAsync(logoutRequest);
        logoutResponse.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // The refresh token should now be rejected.
        var refreshResponse = await Client.PostAsJsonAsync("/auth/refresh",
            new { refreshToken = login.RefreshToken });
        refreshResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }
}
