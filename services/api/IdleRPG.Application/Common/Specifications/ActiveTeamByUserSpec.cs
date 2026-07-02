using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>The active battle team of a user, ordered by team slot.</summary>
public sealed class ActiveTeamByUserSpec : BaseSpecification<Character>
{
    public ActiveTeamByUserSpec(Guid userId)
        : base(c => c.UserId == userId && c.IsActive)
    {
        ApplyOrderBy(c => c.TeamSlot);
    }
}
