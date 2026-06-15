using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Domain.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace IdleRPG.Infrastructure.Auth;

/// <summary>
/// Issues HS256-signed JWT access tokens using the symmetric JWT_SECRET, plus
/// random refresh tokens stored as SHA-256 hashes.
/// </summary>
public sealed class JwtTokenService : IJwtTokenService
{
    private readonly byte[] _signingKey;
    private readonly string _issuer;
    private readonly string _audience;

    public JwtTokenService(IConfiguration configuration)
    {
        var secret = configuration["JWT_SECRET"]
                     ?? throw new InvalidOperationException("JWT_SECRET is not configured.");
        _signingKey = Encoding.UTF8.GetBytes(secret);
        _issuer = configuration["JWT_ISSUER"] ?? "idlerpg";
        _audience = configuration["JWT_AUDIENCE"] ?? "idlerpg-client";
    }

    public int AccessTokenLifetimeSeconds => 900;       // 15 minutes
    public int RefreshTokenLifetimeDays => 7;

    public string CreateAccessToken(User user)
    {
        var now = DateTime.UtcNow;
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(_signingKey), SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim("steam", user.SteamId),
            new Claim("name", user.Username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            notBefore: now,
            expires: now.AddSeconds(AccessTokenLifetimeSeconds),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public (string RawToken, string TokenHash) CreateRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        var raw = Convert.ToBase64String(bytes)
            .Replace("+", "-").Replace("/", "_").TrimEnd('=');
        return (raw, HashRefreshToken(raw));
    }

    public string HashRefreshToken(string rawToken)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
