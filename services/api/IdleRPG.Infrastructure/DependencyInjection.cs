using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Infrastructure.Auth;
using IdleRPG.Infrastructure.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;

namespace IdleRPG.Infrastructure;

/// <summary>Registers Infrastructure-layer services (persistence, auth).</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        // Persistence
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Auth
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddSingleton<IJwtTokenService, JwtTokenService>();

        services.AddHttpClient(nameof(SteamAuthService));
        services.AddScoped<ISteamAuthService, SteamAuthService>();

        return services;
    }
}
