using Microsoft.Extensions.DependencyInjection;

namespace IdleRPG.Infrastructure.Persistence.Seed;

/// <summary>Entry point for development seed data.</summary>
public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        using var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await ItemSeed.SeedAsync(context, ct);
        await SetBonusSeed.SeedAsync(context, ct);
    }
}
