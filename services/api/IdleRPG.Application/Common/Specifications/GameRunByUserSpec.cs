using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>The single idle-combat run owned by a user.</summary>
public sealed class GameRunByUserSpec : BaseSpecification<GameRun>
{
    public GameRunByUserSpec(Guid userId)
        : base(r => r.UserId == userId)
    {
    }
}
