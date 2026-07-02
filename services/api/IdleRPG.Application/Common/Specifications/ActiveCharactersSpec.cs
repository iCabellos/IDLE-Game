using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>All active characters across all users (used by the idle tick job).</summary>
public sealed class ActiveCharactersSpec : BaseSpecification<Character>
{
    public ActiveCharactersSpec()
        : base(c => c.IsActive)
    {
    }
}
