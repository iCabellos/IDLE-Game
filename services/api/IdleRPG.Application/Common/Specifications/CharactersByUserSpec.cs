using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>A user's active characters, ordered by team slot.</summary>
public sealed class CharactersByUserSpec : BaseSpecification<Character>
{
    public CharactersByUserSpec(Guid userId)
        : base(c => c.UserId == userId && c.IsActive)
    {
        ApplyOrderBy(c => c.TeamSlot);
    }
}
