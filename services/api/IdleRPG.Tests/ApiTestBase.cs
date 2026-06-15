using IdleRPG.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Testcontainers.PostgreSql;
using Testcontainers.Redis;
using Xunit;

namespace IdleRPG.Tests;

/// <summary>
/// Base class for all integration tests. Spins up disposable PostgreSQL
/// and Redis containers via Testcontainers and exposes a
/// <see cref="WebApplicationFactory{TEntryPoint}"/> wired to use them.
/// </summary>
public abstract class ApiTestBase : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgresContainer = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .WithDatabase("idlerpg_test")
        .WithUsername("idlerpg")
        .WithPassword("secret")
        .Build();

    private readonly RedisContainer _redisContainer = new RedisBuilder()
        .WithImage("redis:7-alpine")
        .Build();

    protected WebApplicationFactory<Program> Factory { get; private set; } = default!;

    protected HttpClient Client { get; private set; } = default!;

    /// <summary>Override to replace registered services with test doubles.</summary>
    protected virtual void ConfigureTestServices(IServiceCollection services)
    {
    }

    public async Task InitializeAsync()
    {
        await Task.WhenAll(_postgresContainer.StartAsync(), _redisContainer.StartAsync());

        // Minimal hosting reads configuration eagerly inside Program.cs (before the
        // test's ConfigureAppConfiguration callback runs), so the connection strings
        // and secrets must be present as environment variables when the host builds.
        Environment.SetEnvironmentVariable("POSTGRES_URL", _postgresContainer.GetConnectionString());
        Environment.SetEnvironmentVariable("REDIS_URL", _redisContainer.GetConnectionString());
        Environment.SetEnvironmentVariable("JWT_SECRET", "integration-tests-symmetric-secret-key-32bytes!");
        Environment.SetEnvironmentVariable("JWT_ISSUER", "idlerpg");
        Environment.SetEnvironmentVariable("JWT_AUDIENCE", "idlerpg-client");

        Factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.UseEnvironment("Testing");

                builder.ConfigureTestServices(ConfigureTestServices);
            });

        Client = Factory.CreateClient();

        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        Client.Dispose();
        await Factory.DisposeAsync();
        await _postgresContainer.DisposeAsync();
        await _redisContainer.DisposeAsync();
    }
}
