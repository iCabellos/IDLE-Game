using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Persistence;

/// <summary>
/// EF Core database context for IdleRPG. Soft-delete query filters are applied
/// in the individual entity configurations.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Character> Characters => Set<Character>();
    public DbSet<Item> Items => Set<Item>();
    public DbSet<ItemInstance> ItemInstances => Set<ItemInstance>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
