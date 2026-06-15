using System.Text.Json;
using System.Text.RegularExpressions;
using IdleRPG.Application.DTOs.Auth;
using IdleRPG.Application.Interfaces.Auth;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace IdleRPG.Infrastructure.Auth;

/// <summary>
/// Validates Steam OpenID 2.0 callbacks against steamcommunity.com and fetches
/// player profiles from the Steam Web API.
/// </summary>
public sealed partial class SteamAuthService : ISteamAuthService
{
    private const string OpenIdEndpoint = "https://steamcommunity.com/openid/login";
    private const string PlayerSummariesEndpoint =
        "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/";

    private static readonly Regex ClaimedIdRegex = SteamIdRegex();

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly string? _apiKey;
    private readonly ILogger<SteamAuthService> _logger;

    public SteamAuthService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<SteamAuthService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _apiKey = configuration["STEAM_API_KEY"];
        _logger = logger;
    }

    public async Task<string?> ValidateOpenIdAsync(string openIdPayload, CancellationToken ct = default)
    {
        // Parse the callback query string and flip mode to check_authentication.
        var parameters = ParseQuery(openIdPayload);

        if (!parameters.TryGetValue("openid.claimed_id", out var claimedId))
        {
            _logger.LogWarning("OpenID payload missing openid.claimed_id");
            return null;
        }

        parameters["openid.mode"] = "check_authentication";

        var client = _httpClientFactory.CreateClient(nameof(SteamAuthService));
        using var content = new FormUrlEncodedContent(parameters);

        HttpResponseMessage response;
        try
        {
            response = await client.PostAsync(OpenIdEndpoint, content, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Steam OpenID verification request failed");
            return null;
        }

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("Steam OpenID returned {Status}", response.StatusCode);
            return null;
        }

        var body = await response.Content.ReadAsStringAsync(ct);
        if (!body.Contains("is_valid:true", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning("Steam OpenID validation returned not valid");
            return null;
        }

        var match = ClaimedIdRegex.Match(claimedId);
        return match.Success ? match.Groups[1].Value : null;
    }

    public async Task<SteamPlayerSummary?> GetPlayerSummaryAsync(string steamId, CancellationToken ct = default)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            _logger.LogWarning("STEAM_API_KEY not configured; skipping player summary fetch");
            return null;
        }

        var client = _httpClientFactory.CreateClient(nameof(SteamAuthService));
        var url = $"{PlayerSummariesEndpoint}?key={_apiKey}&steamids={steamId}";

        try
        {
            var json = await client.GetStringAsync(url, ct);
            using var doc = JsonDocument.Parse(json);

            var players = doc.RootElement
                .GetProperty("response")
                .GetProperty("players");

            if (players.GetArrayLength() == 0)
            {
                return null;
            }

            var p = players[0];
            return new SteamPlayerSummary
            {
                SteamId = steamId,
                PersonaName = p.TryGetProperty("personaname", out var n) ? n.GetString() ?? string.Empty : string.Empty,
                AvatarUrl = p.TryGetProperty("avatarfull", out var a) ? a.GetString() ?? string.Empty : string.Empty,
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch Steam player summary for {SteamId}", steamId);
            return null;
        }
    }

    private static Dictionary<string, string> ParseQuery(string payload)
    {
        var result = new Dictionary<string, string>();
        var trimmed = payload.TrimStart('?');

        foreach (var pair in trimmed.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var idx = pair.IndexOf('=');
            if (idx <= 0)
            {
                continue;
            }

            var key = Uri.UnescapeDataString(pair[..idx]);
            var value = Uri.UnescapeDataString(pair[(idx + 1)..]);
            result[key] = value;
        }

        return result;
    }

    [GeneratedRegex(@"https?://steamcommunity\.com/openid/id/(\d{17})")]
    private static partial Regex SteamIdRegex();
}
