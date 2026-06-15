using FluentAssertions;
using IdleRPG.Infrastructure.Configuration;
using Xunit;

namespace IdleRPG.Tests;

/// <summary>
/// F0 smoke tests: verify the test runner executes and that core
/// infrastructure helpers behave as expected. These do not require
/// external services (PostgreSQL / Redis) so they run anywhere.
/// </summary>
[Trait("Phase", "F0")]
public class SmokeTests
{
    [Fact]
    public void TestRunner_Executes()
    {
        true.Should().BeTrue();
    }

    [Fact]
    public void ConnectionStringHelper_ParsesPostgresUri()
    {
        var result = ConnectionStringHelper.ToNpgsqlConnectionString(
            "postgresql://idlerpg:secret@localhost:5432/idlerpg");

        result.Should().Contain("Host=localhost");
        result.Should().Contain("Port=5432");
        result.Should().Contain("Database=idlerpg");
        result.Should().Contain("Username=idlerpg");
        result.Should().Contain("Password=secret");
    }

    [Fact]
    public void ConnectionStringHelper_PassesThroughNpgsqlKeyValueString()
    {
        const string keyValue = "Host=localhost;Port=5432;Database=idlerpg";

        var result = ConnectionStringHelper.ToNpgsqlConnectionString(keyValue);

        result.Should().Be(keyValue);
    }

    [Fact]
    public void ConnectionStringHelper_ParsesRedisUriWithoutPassword()
    {
        var result = ConnectionStringHelper.ToRedisConnectionString("redis://localhost:6379");

        result.Should().Be("localhost:6379");
    }

    [Fact]
    public void ConnectionStringHelper_ParsesRedisUriWithPassword()
    {
        var result = ConnectionStringHelper.ToRedisConnectionString("redis://:mypass@localhost:6380");

        result.Should().Contain("localhost:6380");
        result.Should().Contain("password=mypass");
    }
}
