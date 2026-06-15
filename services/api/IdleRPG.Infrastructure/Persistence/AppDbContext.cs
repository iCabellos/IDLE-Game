using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Persistence;

/// <summary>
/// EF Core database context for IdleRPG. Entity sets and configurations
/// are added in later phases (F1/F2).
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
