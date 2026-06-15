using System.Text;
using Hangfire.Dashboard;

namespace IdleRPG.API.Middleware;

/// <summary>
/// Protects the Hangfire dashboard with HTTP Basic Authentication using
/// the HANGFIRE_DASHBOARD_USER / HANGFIRE_DASHBOARD_PASS credentials.
/// </summary>
public class HangfireDashboardAuthFilter : IDashboardAuthorizationFilter
{
    private readonly string _username;
    private readonly string _password;

    public HangfireDashboardAuthFilter(string username, string password)
    {
        _username = username;
        _password = password;
    }

    public bool Authorize(DashboardContext context)
    {
        var httpContext = context.GetHttpContext();
        var header = httpContext.Request.Headers["Authorization"].ToString();

        if (string.IsNullOrEmpty(header) || !header.StartsWith("Basic ", StringComparison.OrdinalIgnoreCase))
        {
            Challenge(httpContext);
            return false;
        }

        try
        {
            var encoded = header["Basic ".Length..].Trim();
            var decoded = Encoding.UTF8.GetString(Convert.FromBase64String(encoded));
            var separatorIndex = decoded.IndexOf(':');

            if (separatorIndex < 0)
            {
                Challenge(httpContext);
                return false;
            }

            var username = decoded[..separatorIndex];
            var password = decoded[(separatorIndex + 1)..];

            if (username == _username && password == _password)
            {
                return true;
            }
        }
        catch (FormatException)
        {
            // Falls through to challenge below.
        }

        Challenge(httpContext);
        return false;
    }

    private static void Challenge(HttpContext httpContext)
    {
        httpContext.Response.Headers.WWWAuthenticate = "Basic realm=\"Hangfire Dashboard\"";
        httpContext.Response.StatusCode = StatusCodes.Status401Unauthorized;
    }
}
