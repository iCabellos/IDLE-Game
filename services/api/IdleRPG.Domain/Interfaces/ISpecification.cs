using System.Linq.Expressions;

namespace IdleRPG.Domain.Interfaces;

/// <summary>
/// Minimal specification used to express repository query filters,
/// includes, ordering and paging without leaking EF Core into Domain.
/// </summary>
public interface ISpecification<T>
{
    Expression<Func<T, bool>>? Criteria { get; }

    IReadOnlyList<Expression<Func<T, object>>> Includes { get; }

    Expression<Func<T, object>>? OrderBy { get; }

    Expression<Func<T, object>>? OrderByDescending { get; }

    int? Skip { get; }

    int? Take { get; }
}
