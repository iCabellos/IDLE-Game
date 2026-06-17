using IdleRPG.Application.Interfaces.Auth;
using IdleRPG.Application.Interfaces.Caching;
using IdleRPG.Application.Interfaces.Game;
using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Infrastructure.Auth;
using IdleRPG.Infrastructure.Caching;
using IdleRPG.Infrastructure.Game;
using IdleRPG.Infrastructure.Items;
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

        // Caching
        services.AddScoped<ICacheService, RedisCacheService>();

        // Item engine
        services.AddScoped<IItemFactory, ItemFactory>();
        services.AddScoped<IItemValidator, ItemValidator>();
        services.AddScoped<ISetBonusCalculator, SetBonusCalculator>();
        services.AddScoped<IStatAggregator, StatAggregator>();
        services.AddScoped<ISteamInventoryService, SteamInventoryService>();

        // Idle game engine (server-authoritative)
        services.AddScoped<IGameService, GameService>();
        services.AddScoped<IdleTickJob>();

        return services;
    }
}
