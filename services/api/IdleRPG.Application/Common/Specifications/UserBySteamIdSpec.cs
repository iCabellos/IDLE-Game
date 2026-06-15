using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>Finds a (non-deleted) user by their Steam64 id.</summary>
public sealed class UserBySteamIdSpec : BaseSpecification<User>
{
    public UserBySteamIdSpec(string steamId)
        : base(u => u.SteamId == steamId)
    {
    }
}
