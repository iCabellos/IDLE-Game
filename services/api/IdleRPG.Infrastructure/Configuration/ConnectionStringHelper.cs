using Npgsql;

namespace IdleRPG.Infrastructure.Configuration;

/// <summary>
/// Converts the URI-style connection strings used in .env files
/// (postgresql://user:pass@host:port/db, redis://host:port) into the
/// formats expected by Npgsql and StackExchange.Redis.
/// </summary>
public static class ConnectionStringHelper
{
    public static string ToNpgsqlConnectionString(string postgresUrl)
    {
        if (!postgresUrl.Contains("://"))
        {
            // Already in Npgsql key-value format.
            return postgresUrl;
        }

        var uri = new Uri(postgresUrl);
        var userInfo = uri.UserInfo.Split(':', 2);

        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = uri.Host,
            Port = uri.Port > 0 ? uri.Port : 5432,
            Database = uri.AbsolutePath.TrimStart('/'),
            Username = userInfo.Length > 0 ? Uri.UnescapeDataString(userInfo[0]) : null,
            Password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : null
        };

        return builder.ConnectionString;
    }

    public static string ToRedisConnectionString(string redisUrl)
    {
        if (!redisUrl.Contains("://"))
        {
            // Already in StackExchange.Redis format.
            return redisUrl;
        }

        var uri = new Uri(redisUrl);
        var hostAndPort = $"{uri.Host}:{(uri.Port > 0 ? uri.Port : 6379)}";

        if (string.IsNullOrEmpty(uri.UserInfo))
        {
            return hostAndPort;
        }

        var userInfo = uri.UserInfo.Split(':', 2);
        var password = userInfo.Length > 1 ? userInfo[1] : userInfo[0];

        return $"{hostAndPort},password={Uri.UnescapeDataString(password)}";
    }
}
