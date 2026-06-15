using IdleRPG.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Persistence;

/// <summary>
/// Generic EF Core repository. Soft-delete is enforced by global query filters
/// on the entity configurations, so queries here never see deleted rows.
/// </summary>
public class Repository<T> : IRepository<T> where T : class
{
    private readonly AppDbContext _db;
    private readonly DbSet<T> _set;

    public Repository(AppDbContext db)
    {
        _db = db;
        _set = db.Set<T>();
    }

    public async Task<T?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _set.FindAsync(new object[] { id }, ct);

    public async Task<IReadOnlyList<T>> GetAllAsync(ISpecification<T>? specification = null, CancellationToken ct = default)
        => await ApplySpecification(specification).ToListAsync(ct);

    public async Task<T?> FirstOrDefaultAsync(ISpecification<T> specification, CancellationToken ct = default)
        => await ApplySpecification(specification).FirstOrDefaultAsync(ct);

    public async Task AddAsync(T entity, CancellationToken ct = default)
        => await _set.AddAsync(entity, ct);

    public void Update(T entity) => _set.Update(entity);

    public void Delete(T entity) => _set.Remove(entity);

    private IQueryable<T> ApplySpecification(ISpecification<T>? spec)
    {
        IQueryable<T> query = _set;

        if (spec is null)
        {
            return query;
        }

        if (spec.Criteria is not null)
        {
            query = query.Where(spec.Criteria);
        }

        query = spec.Includes.Aggregate(query, (current, include) => current.Include(include));

        if (spec.OrderBy is not null)
        {
            query = query.OrderBy(spec.OrderBy);
        }
        else if (spec.OrderByDescending is not null)
        {
            query = query.OrderByDescending(spec.OrderByDescending);
        }

        if (spec.Skip is not null)
        {
            query = query.Skip(spec.Skip.Value);
        }

        if (spec.Take is not null)
        {
            query = query.Take(spec.Take.Value);
        }

        return query;
    }
}
