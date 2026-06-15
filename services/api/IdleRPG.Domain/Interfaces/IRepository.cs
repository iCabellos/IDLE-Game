namespace IdleRPG.Domain.Interfaces;

/// <summary>
/// Generic repository abstraction. Implementations honour the soft-delete
/// filter (rows with a non-null DeletedAt are excluded).
/// </summary>
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<IReadOnlyList<T>> GetAllAsync(ISpecification<T>? specification = null, CancellationToken ct = default);

    Task<T?> FirstOrDefaultAsync(ISpecification<T> specification, CancellationToken ct = default);

    Task AddAsync(T entity, CancellationToken ct = default);

    void Update(T entity);

    void Delete(T entity);
}
