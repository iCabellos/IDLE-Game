using System.Threading.RateLimiting;
using FluentValidation;
using FluentValidation.AspNetCore;
using Hangfire;
using Hangfire.Dashboard;
using Hangfire.PostgreSql;
using IdleRPG.API.Middleware;
using IdleRPG.Application;
using IdleRPG.Infrastructure.Configuration;
using IdleRPG.Infrastructure.Persistence;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
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
// MediatR
// ---------------------------------------------------------------------
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(AssemblyMarker).Assembly));

// ---------------------------------------------------------------------
// FluentValidation
// ---------------------------------------------------------------------
builder.Services.AddValidatorsFromAssembly(typeof(AssemblyMarker).Assembly);
builder.Services.AddFluentValidationAutoValidation();

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
app.UseExceptionHandler();

app.UseSerilogRequestLogging();

app.UseCors("flutter-app");

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
