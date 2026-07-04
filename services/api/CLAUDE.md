# services/api — Backend .NET (IdleRPG.sln)

Solucion .NET 8 LTS del backend de IDLE-RPG. Implementa Clean Architecture estricta con CQRS (MediatR), persistencia EF Core 8 sobre PostgreSQL 16 (Npgsql) y cache Redis 7.2 (StackExchange.Redis). Estado: **F0-F4 implementadas** (monorepo+infra, Domain+Auth Steam JWT, DB schema/migraciones/seed, motor de items, combate/idle engine estilo HSR). F5-F9 mayormente **planificadas**.

Ver tambien: `/CLAUDE.md` (indice raiz del monorepo, plan maestro y reglas de oro de fases).

## Mapa de la solucion

`IdleRPG.sln` agrupa 5 proyectos (`net8.0`, `Nullable` + `ImplicitUsings` habilitados en todos):

| Proyecto | SDK | Rol | Referencias salientes |
|---|---|---|---|
| `IdleRPG.Domain` | `Microsoft.NET.Sdk` | Entidades, enums, value objects, GameData, interfaces de repos/specs. **Cero dependencias externas** (ni siquiera NuGet). | ninguna |
| `IdleRPG.Application` | `Microsoft.NET.Sdk` | Use cases CQRS (Command/Query + Handler + Validator), DTOs por feature, interfaces de servicios, pipeline behaviors. | solo `Domain` |
| `IdleRPG.Infrastructure` | `Microsoft.NET.Sdk` | Implementaciones: EF Core `AppDbContext`, repos, auth Steam/JWT, Redis, motor de items, migraciones, seed. | `Application` |
| `IdleRPG.API` | `Microsoft.NET.Sdk.Web` | Host ASP.NET Core: `Program.cs`, minimal-API endpoints, middleware, Hangfire dashboard, Swagger, health checks, rate limiting. | `Infrastructure` |
| `IdleRPG.Tests` | `Microsoft.NET.Sdk` (xUnit) | Tests unitarios + integracion (Testcontainers). | los 4 anteriores |

## REGLA DE DEPENDENCIAS (estricta — no violar)

```
Domain  <-  Application  <-  Infrastructure  <-  API
```

- Cada flecha es la UNICA direccion de referencia permitida. `Domain` no puede referenciar nada; `Application` solo `Domain`; etc. Esto esta forzado por los `<ProjectReference>` de cada `.csproj`.
- **No agregar NuGet a `Domain`.** Si necesitas una abstraccion externa, define una **interface en `Domain` o `Application`** y su implementacion va en `Infrastructure` (patron usado en todo el repo: `IRepository<>`, `IUnitOfWork`, `ICurrentUserService` viven en `Domain/Interfaces`; `IJwtTokenService`, `ISteamAuthService`, `ICacheService`, `IItemFactory`, etc. en `Application/Interfaces`).
- Los handlers de `Application` NUNCA tocan EF Core/Redis directamente: usan `IRepository<T>`, `IUnitOfWork`, `ICacheService` y demas interfaces. El acceso concreto es responsabilidad de `Infrastructure`.

## Wiring de DI

- `IdleRPG.Application/DependencyInjection.cs` → `AddApplication()`: registra MediatR (escaneo de assembly via `AssemblyMarker`), todos los `AbstractValidator` (`AddValidatorsFromAssembly`), el `ValidationBehavior<,>` como `IPipelineBehavior<,>`, y `ICharacterStatsService`.
- `IdleRPG.Infrastructure/DependencyInjection.cs` → `AddInfrastructure()`: registra `IRepository<>`/`IUnitOfWork`, auth (`CurrentUserService`, `JwtTokenService` singleton, `SteamAuthService` + `HttpClient`), `RedisCacheService`, y el motor de items (`ItemFactory`, `ItemValidator`, `SetBonusCalculator`, `StatAggregator`, `SteamInventoryService`).
- `Program.cs` llama `AddApplication()` + `AddInfrastructure()` y ademas configura DbContext, Redis cache, JWT bearer (HS256), Hangfire, CORS (`flutter-app`), health checks, Swagger y rate limiting. Al **añadir un nuevo servicio**, registralo en el `DependencyInjection.cs` de su capa, no en `Program.cs`.

## Convencion CQRS (obligatoria)

Cada use case vive en `Application/UseCases/<Feature>/<Action>/` con estos archivos:
- `<Action>Command.cs` o `<Action>Query.cs` — `record` que implementa `IRequest<TResponse>`.
- `<Action>Handler.cs` — implementa `IRequestHandler<,>`.
- `<Action>Validator.cs` — `AbstractValidator<TCommand>` (FluentValidation), ejecutado automaticamente por `ValidationBehavior` en el pipeline antes del handler. Solo para comandos que requieren validacion.

Ejemplos vivos: `Auth/SteamLogin`, `Auth/RefreshToken`, `Auth/Logout`, `Auth/GetMe`, `Items/EquipItem`, `Items/UnequipItem`, `Items/GetInventory`, `Items/CompareItems`. DTOs agrupados por feature en `Application/DTOs/<Feature>/`.

Endpoints (minimal API, no controllers) en `IdleRPG.API/Endpoints/`:
- `AuthEndpoints` (`/auth`): `POST /auth/steam/login` (anon), `POST /auth/refresh` (anon), `DELETE /auth/logout` (auth), `GET /auth/me` (auth).
- `ItemEndpoints` (`/items`, grupo con `RequireAuthorization()`): `GET /items/inventory`, `POST /items/equip`, `POST /items/unequip`, `GET /items/compare/{id1}/{id2}`.
- Los endpoints solo hacen `sender.Send(...)`; toda la logica va en handlers. Los `record` Request se declaran junto al endpoint.

## Persistencia y schema

- `Infrastructure/Persistence/AppDbContext.cs`: `DbSet`s para `User`, `Character`, `Item`, `ItemInstance`, `RefreshToken`, `AntiBotEvent`, `SetBonus`. **Aplica snake_case automaticamente** a tablas/columnas/keys/indices (`ApplySnakeCaseNaming`) para igualar el schema de referencia (`steam_id`, `account_level`, ...). No nombres columnas a mano salvo excepcion.
- Configuraciones por entidad en `Persistence/Configurations/*Configuration.cs` (`IEntityTypeConfiguration<>`, cargadas via `ApplyConfigurationsFromAssembly`). Aqui van soft-delete filters (`DeletedAt == null`), indices unicos (`users.steam_id`, `item_instances.steam_inventory_id`) y timestamps `created_at`/`updated_at`.
- Migraciones existentes en `Persistence/Migrations/`: `InitialSchema` y `AddSetBonuses`. Snapshot en `AppDbContextModelSnapshot.cs`.
- Seed en `Persistence/Seed/`: `DbSeeder`, `ItemSeed`, `SetBonusSeed`, `SeedIds` (ids deterministas). Se ejecuta en Development y con `SEED_AND_EXIT=true`.
- `AppDbContextFactory` (`IDesignTimeDbContextFactory`) permite a `dotnet ef` construir el contexto en design-time leyendo `POSTGRES_URL` del entorno (fallback local).

## Comandos (desde `services/api/`)

```bash
# Build / test
dotnet build -c Release                 # == make build (desde raiz)
dotnet test                             # toda la suite == make test-api

# Filtrar tests por Trait
dotnet test --filter "Phase=F1"         # traits: F0, F1, F2, F3
dotnet test --filter "Category=ItemEngine"

# Migraciones EF Core (SIEMPRE con estos dos flags)
dotnet ef migrations add <Nombre> --project IdleRPG.Infrastructure --startup-project IdleRPG.API
dotnet ef database update              --project IdleRPG.Infrastructure --startup-project IdleRPG.API   # == make db-migrate
dotnet ef database drop --force        --project IdleRPG.Infrastructure --startup-project IdleRPG.API

# Seed one-shot (migra + seed y sale)
SEED_AND_EXIT=true dotnet run --project IdleRPG.API   # == make db-seed
```

Atajos desde la raiz del monorepo: `make build | test-api | test-all | db-migrate | db-reset | db-seed | clean`. `db-reset` = drop + migrate + seed. La infra local (postgres/redis/pgadmin) sube con `make dev` (docker compose en `infra/docker/docker-compose.yml`).

`make migrations add` no existe: añade migraciones con el comando `dotnet ef migrations add` de arriba.

## Variables de entorno / configuracion

Las connection strings se pasan en **forma URI** (asi viven en `.env.local` / `.env.example` de la raiz) y `Program.cs` las convierte con `Infrastructure/Configuration/ConnectionStringHelper`:
- `ToNpgsqlConnectionString`: `postgresql://user:pass@host:port/db` → formato Npgsql key-value.
- `ToRedisConnectionString`: `redis://host:port` → formato StackExchange.Redis (`host:port[,password=...]`). Ambas son idempotentes si ya reciben el formato nativo.

Vars requeridas (faltar `POSTGRES_URL`, `REDIS_URL` o `JWT_SECRET` lanza `InvalidOperationException` al arrancar):
- `POSTGRES_URL`, `REDIS_URL` — conexiones.
- `JWT_SECRET` (min 32 chars), `JWT_ISSUER` (def `idlerpg`), `JWT_AUDIENCE` (def `idlerpg-client`) — HS256 simetrico.
- `HANGFIRE_DASHBOARD_USER` / `HANGFIRE_DASHBOARD_PASS` — basic-auth del dashboard `/hangfire`; si faltan, el dashboard queda **sin proteccion**.
- `STEAM_API_KEY`, `STEAM_APP_ID`, `STEAM_PUBLISHER_KEY`, `STEAM_WEBHOOK_SECRET` — usados a partir de F5 (ver `.env.example`).
- `SEED_AND_EXIT` — bool; si true, migra+seed y termina el proceso.

`appsettings.json` solo lleva logging/Serilog/CORS. `appsettings.Development.json` lleva valores dev de las vars de arriba (secretos dummy, NO usar en prod). El orden de precedencia normal de .NET aplica (env vars > appsettings).

## Motor de items (F3, implementado en Infrastructure/Items)

- `ItemFactory.RollStat(baseStat, mult)`: Box-Muller, roll normal clamp `[0.85, 1.15]`, devuelve `baseStat * mult * roll`. Rarezas con stats fijos (`Unique`+) se copian verbatim (`ItemRarityData.HasFixedStats`). Multiplicador via `ItemRarityData.Multiplier`. Passive slots por rareza via `ItemRules.PassiveSlots`. Tiene constructor con `Random` inyectable para tests deterministas.
- `StatAggregator`: caps `CritRate<=0.75`, `CritMultiplier<=5.0`, resistencias `<=0.90`.
- `SetBonusCalculator`, `ItemValidator` completan el motor. Enums/formulas canonicas viven en `Domain/Enums` y `Domain/GameData` (`ItemRarityData`, `ItemRules`, `ClassBaseStats`) — definidos UNA vez, no duplicar variantes.

## Tests

- Unitarios en `Tests/Domain`, `Tests/Application`, `Tests/Infrastructure`. Fakes en `Application/Fakes.cs`.
- Integracion en `Tests/Integration` (+ `Database`): levantan PostgreSQL 16 + Redis 7 via **Testcontainers** (`ApiTestBase` → `WebApplicationFactory<Program>`). Marcadas `[Collection("Integration")]` con `DisableParallelization = true` porque comparten env vars de proceso. **Requieren Docker corriendo.**
- `Program` es `public partial class` precisamente para que `WebApplicationFactory<Program>` lo use desde Tests.
- Traits: `[Trait("Phase","F0|F1|F2|F3")]` o `[Trait("Category","ItemEngine")]`. Usalos al añadir tests para que los filtros sigan funcionando.

## Servicios hermanos (stubs planificados)

- `services/worker/` — Hangfire background jobs (`IdleTickJob`, `SteamSyncJob`). **Solo README**; se implementa en F4/F5. (Hangfire ya esta cableado en la API como host temporal.)
- `services/steam-bridge/` — wrapper Steamworks nativo. **Solo README**; F5.
- `Infrastructure/Items/SteamInventoryService` es un **stub F5**: `OwnsAssetAsync` siempre devuelve `true` para que el flujo de equip sea ejercitable. La validacion real de ownership contra Steam llega en F5.

## Gotchas

- No saltarse la regla de dependencias: si un `using` te obliga a referenciar una capa interior hacia afuera, el diseño esta mal; introduce una interface.
- Migraciones SIEMPRE con `--project IdleRPG.Infrastructure --startup-project IdleRPG.API`; sin el startup-project, `dotnet ef` no resuelve la configuracion.
- Tests de integracion fallan sin Docker (Testcontainers).
- Connection strings en URI: si pegas un string Npgsql crudo tambien funciona (el helper lo detecta por ausencia de `://`).
- Commits por fase: `feat: phase-N complete`; cada fase asume la anterior commiteada con `make test-all` verde.

## Estado por fase (este directorio)

- **Implementado**: F0 (infra/monorepo), F1 (Domain + Auth Steam/JWT: endpoints `/auth/*`, JWT HS256, refresh tokens), F2 (schema EF + migraciones + seed), F3 (motor de items: `ItemFactory`/`ItemValidator`/`SetBonusCalculator`/`StatAggregator` + endpoints `/items/*`).
- **Parcial / esqueleto**: F5 Steam (`SteamInventoryService` stub; vars STEAM en `.env`). F6 Anti-bot (solo entidad `AntiBotEvent` + enums `AntiBotRiskLevel`/`BotEventType` en Domain; `RiskScore` value object).
- **Implementado (F4)**: motor de combate por turnos estilo HSR en `Domain/Combat` (`CombatEngine`, `IdleSimulator`, `CombatFormulas`), `ClassKits`/`EnemyCatalog`/`XpCurve` en `Domain/GameData`, `IdleProgressService` (Application), `RedisIdleStateStore` + `IdleTickJob` Hangfire (Infrastructure, recurring cada 60s) y endpoints `/combat/state|claim|zones` (grupo autenticado). Redis keys en uso: `idle:state:{userId}`, `stats:{characterId}`.
- **Planificado (NO implementado)**: F8 widget Android, F9 meta. El `services/worker` y `services/steam-bridge` reales (Hangfire sigue hosteado in-process en la API).
