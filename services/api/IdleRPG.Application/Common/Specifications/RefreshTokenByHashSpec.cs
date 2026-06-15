using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>Finds a refresh token by its SHA-256 hash, including the owning user.</summary>
public sealed class RefreshTokenByHashSpec : BaseSpecification<RefreshToken>
{
    public RefreshTokenByHashSpec(string tokenHash)
        : base(t => t.TokenHash == tokenHash)
    {
        AddInclude(t => t.User!);
    }
}
