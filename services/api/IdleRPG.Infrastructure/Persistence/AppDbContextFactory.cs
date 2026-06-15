using IdleRPG.Infrastructure.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace IdleRPG.Infrastructure.Persistence;

/// <summary>
/// Design-time factory used by `dotnet ef` for migrations. Reads POSTGRES_URL
/// from the environment, falling back to a local default.
/// </summary>
public sealed class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var postgresUrl = Environment.GetEnvironmentVariable("POSTGRES_URL")
            ?? "postgresql://idlerpg:secret@localhost:5432/idlerpg";

        var connectionString = ConnectionStringHelper.ToNpgsqlConnectionString(postgresUrl);

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(connectionString)
            .Options;

        return new AppDbContext(options);
    }
}
