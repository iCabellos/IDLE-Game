# services/api/IdleRPG.API — Host ASP.NET Core (.NET 8)

Capa de presentación del backend: host web minimal-API que compone `Application` + `Infrastructure` y expone los endpoints HTTP. Es el **startup project** (también para `dotnet ef` y para `WebApplicationFactory<Program>` en tests). Depende de `IdleRPG.Infrastructure` (y transitivamente de `Application`/`Domain`). **Nada referencia a esta capa** salvo `IdleRPG.Tests`.

Ver también: `/CLAUDE.md` (índice raíz) y `services/api/CLAUDE.md` (reglas de la solución, build/test/migraciones).

## Mapa del proyecto

```
IdleRPG.API/
├── Program.cs                       # composición raíz: DI + pipeline (todo el wiring vive aquí)
├── Endpoints/
│   ├── AuthEndpoints.cs             # MapGroup("/auth")
│   └── ItemEndpoints.cs             # MapGroup("/items") .RequireAuthorization()
├── Middleware/
│   ├── GlobalExceptionHandler.cs    # IExceptionHandler -> ProblemDetails consistente
│   └── HangfireDashboardAuthFilter.cs  # basic-auth del dashboard /hangfire
├── Properties/launchSettings.json
├── appsettings.json                 # logging/Serilog/CORS
├── appsettings.Development.json      # valores dev (secretos dummy — NO usar en prod)
└── Dockerfile                       # multi-stage sdk:8.0 -> aspnet:8.0, EXPOSE 5000
```

## Patrón de endpoints (minimal API, NO controllers)

- Cada grupo es una clase estática con un método de extensión `MapXEndpoints(this IEndpointRouteBuilder)` que se registra en `Program.cs` (`app.MapAuthEndpoints(); app.MapItemEndpoints();`).
- Un endpoint **solo** resuelve `ISender` (MediatR) y hace `sender.Send(new XCommand(...), ct)`. **Cero lógica de negocio aquí** — vive en los handlers de `Application`.
- Los `record` de request (p. ej. `SteamLoginRequest`, `EquipItemRequest`) se declaran junto al endpoint que los usa.
- Auth por endpoint: `.AllowAnonymous()` o `.RequireAuthorization()` (o a nivel de grupo). `/items/*` es un grupo autenticado completo.
- Para añadir un endpoint nuevo: crea su Command/Query+Handler en `Application`, y aquí solo el mapeo. Si es una feature nueva, crea `XEndpoints.cs` y llama a `app.MapXEndpoints()` en `Program.cs`.

### Contratos actuales (implementados)

`/auth` (tag "Auth"):
| Método | Ruta | Auth | Use case |
|---|---|---|---|
| POST | `/auth/steam/login` | anon | `SteamLoginCommand(OpenIdPayload)` → access+refresh+`UserDto` |
| POST | `/auth/refresh` | anon | `RefreshTokenCommand(RefreshToken)` → access nuevo |
| DELETE | `/auth/logout` | bearer | `LogoutCommand(RefreshToken)` → 204 |
| GET | `/auth/me` | bearer | `GetMeQuery()` → `UserDto` |

`/items` (tag "Items", grupo `RequireAuthorization()`):
| Método | Ruta | Use case |
|---|---|---|
| GET | `/items/inventory?page&size&rarity&slot` | `GetInventoryQuery` (paginado, filtros `ItemRarity?`/`ItemSlot?`) |
| POST | `/items/equip` | `EquipItemCommand(CharacterId, ItemInstanceId, TargetSlot)` |
| POST | `/items/unequip` | `UnequipItemCommand(CharacterId, ItemInstanceId)` |
| GET | `/items/compare/{id1:guid}/{id2:guid}` | `CompareItemsQuery` — devuelve **texto descriptivo, NO números** |

## Program.cs — orden del pipeline (no reordenar a la ligera)

Registro (DI): connection strings (URI→nativo vía `ConnectionStringHelper`) → Serilog (consola + `logs/api-.txt` diario) → `AddDbContext<AppDbContext>` (Npgsql) → `AddStackExchangeRedisCache` (instancia `idlerpg:`) → `AddApplication()` + `AddInfrastructure()` → JWT Bearer **HS256** (clave simétrica `JWT_SECRET`, `ClockSkew` 30s) → `AddAuthorization` → Hangfire (storage PostgreSQL) + `AddHangfireServer` → CORS `flutter-app` (dev = AllowAnyOrigin; prod = `AllowedOrigins`) → health checks (`postgres` + `redis`) → Swagger con Bearer → `AddExceptionHandler<GlobalExceptionHandler>` + `AddProblemDetails` → rate limiter.

Pipeline (orden de ejecución):
1. **Arranque dev**: si `IsDevelopment()` o `SEED_AND_EXIT` → `db.Database.MigrateAsync()` + `DbSeeder.SeedAsync(...)`. Si `SEED_AND_EXIT` → loggea y **termina el proceso** (lo usa `make db-seed`/`db-reset`).
2. `UseExceptionHandler()` → `UseSerilogRequestLogging()` → `UseCors("flutter-app")` → `UseAuthentication()` → `UseAuthorization()` → `UseRateLimiter()`.
3. Swagger UI solo en Development (`/swagger`).
4. `MapHealthChecks("/health")` → escribe `{"status":"healthy"}` (200) / `unhealthy`.
5. `MapAuthEndpoints()` + `MapItemEndpoints()`.
6. `UseHangfireDashboard("/hangfire", ...)` con basic-auth si hay credenciales; **si faltan, el dashboard queda SIN protección**.

`public partial class Program {}` al final: lo necesita `WebApplicationFactory<Program>` en `IdleRPG.Tests`.

## Manejo de errores → ProblemDetails (`GlobalExceptionHandler`)

Mapeo de excepciones de `Application.Common.Exceptions` a HTTP (todas se loggean como **warning**, salvo el default que es **error**):

| Excepción | Status | Title |
|---|---|---|
| `FluentValidation.ValidationException` | 400 | "Validation failed" (+ `errors` por propiedad) |
| `AuthenticationException` | 401 | "Authentication failed" |
| `NotFoundException` | 404 | "Not found" |
| `ForbiddenException` | 403 | "Forbidden" |
| `DomainValidationException` | 400 | "Operation rejected" |
| (cualquier otra) | 500 | "An unexpected error occurred" (detalle genérico) |

Para devolver un error de negocio desde un handler, **lanza una de estas excepciones** — no construyas `IResult` de error en el endpoint.

## Rate limiting

`FixedWindowRateLimiter` global, ventana 1 min, rechazo **429**:
- Autenticado → partición `user:{sub}`, **500 req/min**.
- Anónimo → partición `ip:{RemoteIpAddress}`, **100 req/min**.

(El plan F6 añadirá `AntiBotMiddleware` por encima de esto; aún NO implementado.)

## Cómo ejecutar

```bash
# Requiere postgres+redis arriba (make dev) y .env.local con POSTGRES_URL/REDIS_URL/JWT_SECRET
cd services/api && dotnet run --project IdleRPG.API     # http://localhost:5000
# Salud y docs:
curl http://localhost:5000/health        # {"status":"healthy"}
#       http://localhost:5000/swagger     (solo Development)
#       http://localhost:5000/hangfire    (basic-auth si hay credenciales)
```

Vía Docker: `docker compose -f infra/docker/docker-compose.yml up --build` (servicio `api`, puerto 5000). El `Dockerfile` es multi-stage `sdk:8.0`→`aspnet:8.0`.

## Variables de entorno

Falla al arrancar (`InvalidOperationException`) si faltan `POSTGRES_URL`, `REDIS_URL` o `JWT_SECRET`. Defaults: `JWT_ISSUER=idlerpg`, `JWT_AUDIENCE=idlerpg-client`. Steam (`STEAM_*`) y Hangfire dashboard (`HANGFIRE_DASHBOARD_USER/PASS`) opcionales — ver `.env.example`. Lista completa y conversión URI→nativo en `services/api/CLAUDE.md`.

## Endpoints planificados (aún NO implementados)

Del plan maestro, faltan estos grupos (no asumir que existen):
- `CombatEndpoints` (`/combat`): **implementados** `/state` (avanza sim + estado legible), `/claim` (aplica XP pendiente) y `/zones`; quedan `/reconnect`, `/zone/{id}/enter`, `/history` para iteraciones futuras.
- `SteamEndpoints` (`/steam`): `/inventory`, `/sync`, `/sync/status`, `/market/price/{hash}`, `/webhook` — **F5**.
- `AdminEndpoints` (`/admin/antibot/*`, `[RequireRole("admin")]`) y `AntiBotMiddleware` — **F6**.
- `MetaEndpoints` (`/meta/*`) — **F9**.
- `ProgressHub` SignalR (`/ws/progress`) para push en tiempo real — **F4/F7**.

## Gotchas

- No metas lógica en endpoints; si te ves escribiendo `if/else` de negocio, va en un handler de `Application`.
- Errores de negocio = excepción tipada (ver tabla), no `Results.BadRequest(...)` ad-hoc.
- Swagger y el seed automático solo corren en `Development`; en otros entornos las migraciones deben aplicarse con `make db-migrate`.
- El dashboard `/hangfire` sin `HANGFIRE_DASHBOARD_USER/PASS` queda abierto: define ambos fuera de dev.
- Hangfire se aloja **in-process** en la API por ahora; el `services/worker` dedicado llegará en F4.
