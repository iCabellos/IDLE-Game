using System.Text;
using System.Threading.RateLimiting;
using Hangfire;
using Hangfire.Dashboard;
using Hangfire.PostgreSql;
using IdleRPG.API.Endpoints;
using IdleRPG.API.Middleware;
using IdleRPG.Application;
using IdleRPG.Infrastructure;
using IdleRPG.Infrastructure.Configuration;
using IdleRPG.Infrastructure.Idle;
using IdleRPG.Infrastructure.Persistence;
using IdleRPG.Infrastructure.Persistence.Seed;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// ---------------------------------------------------------------------
// Connection strings (env vars use the postgresql:// / redis:// URI form
// from .env.local; Npgsql and StackExchange.Redis need their own formats)
// ---------------------------------------------------------------------
var postgresUrl = builder.Configuration["POSTGRES_URL"]
    ?? throw new InvalidOperationException("POSTGRES_URL is not configured.");
var redisUrl = builder.Configuration["REDIS_URL"]
    ?? throw new InvalidOperationException("REDIS_URL is not configured.");

var npgsqlConnectionString = ConnectionStringHelper.ToNpgsqlConnectionString(postgresUrl);
var redisConnectionString = ConnectionStringHelper.ToRedisConnectionString(redisUrl);

// ---------------------------------------------------------------------
// Serilog: console + rolling daily file under /logs
// ---------------------------------------------------------------------
builder.Host.UseSerilog((context, _, loggerConfig) => loggerConfig
    .ReadFrom.Configuration(context.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(
        path: Path.Combine(builder.Environment.ContentRootPath, "logs", "api-.txt"),
        rollingInterval: RollingInterval.Day,
        shared: true));

// ---------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(npgsqlConnectionString));

// ---------------------------------------------------------------------
// Redis cache
// ---------------------------------------------------------------------
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = redisConnectionString;
    options.InstanceName = "idlerpg:";
});

// ---------------------------------------------------------------------
// Application + Infrastructure layers (MediatR, validators, repositories,
// auth services)
// ---------------------------------------------------------------------
builder.Services.AddApplication();
builder.Services.AddInfrastructure();

// ---------------------------------------------------------------------
// JWT authentication (HS256 using the symmetric JWT_SECRET)
// ---------------------------------------------------------------------
var jwtSecret = builder.Configuration["JWT_SECRET"]
    ?? throw new InvalidOperationException("JWT_SECRET is not configured.");
var jwtIssuer = builder.Configuration["JWT_ISSUER"] ?? "idlerpg";
var jwtAudience = builder.Configuration["JWT_AUDIENCE"] ?? "idlerpg-client";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
        };
    });

builder.Services.AddAuthorization();

// ---------------------------------------------------------------------
// Hangfire
// ---------------------------------------------------------------------
builder.Services.AddHangfire(config => config
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UsePostgreSqlStorage(c => c.UseNpgsqlConnection(npgsqlConnectionString)));

builder.Services.AddHangfireServer();

// ---------------------------------------------------------------------
// CORS
// ---------------------------------------------------------------------
builder.Services.AddCors(options =>
{
    options.AddPolicy("flutter-app", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        }
        else
        {
            var allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>()
                ?? Array.Empty<string>();

            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod();
        }
    });
});

// ---------------------------------------------------------------------
// Health checks
// ---------------------------------------------------------------------
builder.Services.AddHealthChecks()
    .AddNpgSql(npgsqlConnectionString, name: "postgres")
    .AddRedis(redisConnectionString, name: "redis");

// ---------------------------------------------------------------------
// Swagger with Bearer auth
// ---------------------------------------------------------------------
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "IdleRPG API",
        Version = "v1",
        Description = "Idle RPG + Steam Market backend API"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter 'Bearer {token}'"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// ---------------------------------------------------------------------
// Global exception handling
// ---------------------------------------------------------------------
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// ---------------------------------------------------------------------
// Rate limiting: 100 req/min per IP, 500 req/min per authenticated user
// ---------------------------------------------------------------------
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var isAuthenticated = httpContext.User.Identity?.IsAuthenticated == true;

        var partitionKey = isAuthenticated
            ? $"user:{httpContext.User.FindFirst("sub")?.Value ?? httpContext.User.Identity!.Name}"
            : $"ip:{httpContext.Connection.RemoteIpAddress}";

        var permitLimit = isAuthenticated ? 500 : 100;

        return RateLimitPartition.GetFixedWindowLimiter(partitionKey, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = permitLimit,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
});

var app = builder.Build();

// ---------------------------------------------------------------------
// Middleware pipeline
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
// Apply migrations + seed development data. SEED_AND_EXIT runs the same
// migrate+seed step from the CLI (used by `make db-reset`) and then exits.
// ---------------------------------------------------------------------
var seedAndExit = builder.Configuration.GetValue<bool>("SEED_AND_EXIT");

if (app.Environment.IsDevelopment() || seedAndExit)
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
    await DbSeeder.SeedAsync(app.Services);
}

if (seedAndExit)
{
    Log.Information("SEED_AND_EXIT set — database migrated and seeded, exiting.");
    return;
}

app.UseExceptionHandler();

app.UseSerilogRequestLogging();

app.UseCors("flutter-app");

app.UseAuthentication();
app.UseAuthorization();

app.UseRateLimiter();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "IdleRPG API v1");
    });
}

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var status = report.Status == HealthStatus.Healthy ? "healthy" : "unhealthy";
        await context.Response.WriteAsync($"{{\"status\":\"{status}\"}}");
    }
});

// ---------------------------------------------------------------------
// API endpoints
// ---------------------------------------------------------------------
app.MapAuthEndpoints();
app.MapItemEndpoints();
app.MapCombatEndpoints();

// ---------------------------------------------------------------------
// Recurring jobs: the idle tick advances every active team each minute
// (one pass = the 60 elapsed 1-second ticks since the previous pass).
// Resolved via DI (IRecurringJobManager) — the static RecurringJob API
// needs JobStorage.Current, which is not set under the test host.
// ---------------------------------------------------------------------
using (var jobScope = app.Services.CreateScope())
{
    jobScope.ServiceProvider.GetRequiredService<IRecurringJobManager>().AddOrUpdate<IdleTickJob>(
        IdleTickJob.JobId,
        job => job.RunAsync(CancellationToken.None),
        IdleTickJob.CronEveryMinute);
}

var hangfireUser = builder.Configuration["HANGFIRE_DASHBOARD_USER"];
var hangfirePass = builder.Configuration["HANGFIRE_DASHBOARD_PASS"];

app.UseHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = !string.IsNullOrEmpty(hangfireUser) && !string.IsNullOrEmpty(hangfirePass)
        ? new[] { new HangfireDashboardAuthFilter(hangfireUser, hangfirePass) }
        : Array.Empty<IDashboardAuthorizationFilter>()
});

app.Run();

// Exposed for IdleRPG.Tests / WebApplicationFactory<Program>.
public partial class Program
{
}
