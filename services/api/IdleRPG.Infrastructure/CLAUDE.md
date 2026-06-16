# CLAUDE.md — IdleRPG.Infrastructure

Ver tambien: /CLAUDE.md (indice raiz del monorepo, plan maestro y reglas de oro).

## Proposito

Capa **Infrastructure** de la Clean Architecture .NET 8. Implementa las interfaces declaradas en `IdleRPG.Application` (y algunas en `IdleRPG.Domain`) usando tecnologia concreta: EF Core 8 + PostgreSQL 16 (Npgsql), Redis 7.2 (via `IDistributedCache`/StackExchange.Redis), JWT/Steam OpenID, y el motor de items. Es la unica capa que conoce bases de datos, HTTP externo y caches.

## Regla de dependencias (ESTRICTA)

```
Domain  <-  Application  <-  Infrastructure  <-  API
```

- Este proyecto referencia **solo** `IdleRPG.Application` (ver `IdleRPG.Infrastructure.csproj`). NO referenciar `IdleRPG.API`.
- Las **interfaces** viven en Application/Domain; aqui van **implementaciones**. Si necesitas un nuevo servicio, primero declara su interfaz en `Application.Interfaces.*` (o `Domain.Interfaces`), luego implementala aqui y registrala en `DependencyInjection.cs`.
- No filtrar tipos de EF Core, Npgsql ni Redis hacia Application: expon resultados via las interfaces y DTOs definidos en Application.

## Mapa de archivos

```
IdleRPG.Infrastructure/
├─ DependencyInjection.cs          # AddInfrastructure(): registra TODOS los servicios de esta capa
├─ Configuration/
│  └─ ConnectionStringHelper.cs    # URI estilo .env (postgresql://, redis://) -> formato Npgsql / StackExchange
├─ Persistence/
│  ├─ AppDbContext.cs              # DbContext + naming snake_case automatico
│  ├─ AppDbContextFactory.cs       # IDesignTimeDbContextFactory para `dotnet ef`
│  ├─ Repository.cs                # IRepository<T> generico (+ ApplySpecification)
│  ├─ UnitOfWork.cs                # IUnitOfWork (SaveChanges + transacciones)
│  ├─ Configurations/              # IEntityTypeConfiguration<T> por entidad
│  │   ├─ UserConfiguration.cs
│  │   ├─ CharacterConfiguration.cs
│  │   ├─ ItemConfiguration.cs
│  │   ├─ ItemInstanceConfiguration.cs
│  │   ├─ RefreshTokenConfiguration.cs
│  │   ├─ AntiBotEventConfiguration.cs
│  │   └─ SetBonusConfiguration.cs
│  ├─ Migrations/                  # Migraciones EF Core + snapshot
│  └─ Seed/
│      ├─ DbSeeder.cs              # Orquesta el seed (llamado desde API con SEED_AND_EXIT)
│      ├─ SeedIds.cs              # GUID determinista a partir de un nombre (idempotencia)
│      ├─ ItemSeed.cs             # Catalogo global de items + Ironclad Set
│      └─ SetBonusSeed.cs         # Umbrales de set bonus del Ironclad Set
├─ Caching/
│  └─ RedisCacheService.cs         # ICacheService sobre IDistributedCache (JSON)
├─ Auth/
│  ├─ JwtTokenService.cs           # access token HS256 + refresh token (hash SHA-256)
│  ├─ SteamAuthService.cs          # OpenID 2.0 + GetPlayerSummaries
│  └─ CurrentUserService.cs        # lee identidad del HttpContext
└─ Items/                          # Motor de items (F3)
   ├─ ItemFactory.cs
   ├─ ItemValidator.cs
   ├─ SetBonusCalculator.cs
   ├─ StatAggregator.cs
   └─ SteamInventoryService.cs     # STUB (F5)
```

## Estado por area: Implementado vs Planificado

| Area | Estado |
|------|--------|
| Persistence (DbContext, Configurations, Migrations, Repository, UnitOfWork, soft-delete) | **Implementado** (F2) |
| Seed (ItemSeed, SetBonusSeed, DbSeeder, SeedIds) | **Implementado** (F2) |
| Caching (RedisCacheService) | **Implementado** |
| Auth (JwtTokenService, SteamAuthService, CurrentUserService) | **Implementado** (F1) |
| Motor de items (ItemFactory, ItemValidator, SetBonusCalculator, StatAggregator) | **Implementado** (F3) |
| SteamInventoryService | **Stub** — devuelve siempre `true`. Implementacion real **Planificada (F5)** |
| BackgroundJobs / IdleTickJob / motor de combate | **Planificado (F4)** — NO existe codigo aun (el paquete Hangfire ya esta referenciado en el csproj, pero no hay jobs) |
| Anti-bot engine (risk score en Redis, decay, thresholds) | **Planificado (F6)** — solo existe la entidad `AntiBotEvent` + su `Configuration`; no hay servicio que calcule risk |
| Steam Market / desync reconciliation | **Planificado (F5)** |

## Convenciones observadas (seguir tal cual)

- **Servicios `sealed`** con dependencias por constructor. Varios servicios de `Items/` ofrecen un **constructor adicional "test-friendly"** (RNG sembrado, backoff inyectable, tabla en memoria); preservalo al editar.
- **DI**: todo servicio nuevo se registra en `DependencyInjection.AddInfrastructure`. Scoped por defecto; `JwtTokenService` es **Singleton**; `HttpClient` con nombre (`nameof(SteamAuthService)`) via `AddHttpClient`.
- **Naming de BD: snake_case automatico.** `AppDbContext.ApplySnakeCaseNaming` reescribe tablas, columnas, claves, FKs e indices a snake_case. En las Configurations escribe nombres en PascalCase normales; el helper los convierte. Solo fija nombres explicitos cuando quieras un identificador concreto (p.ej. `idx_item_instances_steam`, `risk_score`).
- **Configurations**: una clase `IEntityTypeConfiguration<T>` `sealed` por entidad en `Persistence/Configurations`. Se descubren automaticamente via `ApplyConfigurationsFromAssembly` en `OnModelCreating` — NO hay que registrarlas a mano.
- **Soft delete**: cada entidad con `DeletedAt` declara `builder.HasQueryFilter(x => x.DeletedAt == null)`. El `Repository<T>` y todas las queries heredan el filtro automaticamente; para incluir borrados usa `IgnoreQueryFilters()` explicitamente.
- **Timestamps**: `created_at`/`updated_at` con `HasDefaultValueSql("now()")`. (Aun no hay trigger de `updated_at` en BD; el codigo de aplicacion setea `UpdatedAt` manualmente, p.ej. `ItemFactory`).
- **Enums a BD**: se persisten como `smallint` (`HasColumnType("smallint")`) con `HasDefaultValue` al valor canonico (`AccountStatus.Active`, `AntiBotRiskLevel.Normal`). Respeta los valores numericos definidos UNA VEZ en Domain; no inventar variantes.
- **JSON en BD**: columnas `jsonb` con default `'{}'` (`RolledStatsJson`, `MetadataJson`, `StatBonusesJson`). El (de)serializado se hace con `System.Text.Json` y los value objects de Domain (`RolledItemData`, `SetBonusPayload`, `StatModifier`, `Passive`).
- **Indices unicos clave**: `users.steam_id` (UserConfiguration) y `item_instances.steam_inventory_id` (`idx_item_instances_steam`). No romper estas restricciones.
- **Check constraints**: definidos en las Configurations via `ToTable(t => t.HasCheckConstraint(...))` (p.ej. `account_level >= 1`, `risk_score BETWEEN 0 AND 100`, `pieces_required >= 1`).

## Caching y esquema de keys (Redis)

`RedisCacheService` implementa `ICacheService` (Get/Set/Remove) serializando con JSON sobre `IDistributedCache`. El prefijo de instancia `idlerpg:` lo aplica el provider configurado en API.

Keys usadas/planeadas (esquema canonico de F4):
- `steam:owns:{steamId}:{itemId}` — **en uso** en `ItemValidator` (TTL 5 min, cachea bool de ownership).
- `idle:state:{userId}`, `idle:session:{userId}`, `stats:{characterId}` (TTL 1h, invalidar en equip), `steam:inventory:{steamId}`, `antibot:score:{userId}` (TTL 24h, decay -1 cada 6h), `ratelimit:{ip}`, `desynced:{userId}:{itemId}` — **planificadas** (F4/F5/F6), aun no consumidas desde esta capa.

Al implementar nuevas features respeta exactamente estos nombres de key; no inventar variantes.

## Motor de items (F3) — formulas y caps

- **`ItemFactory.RollStat(baseStat, mult)`**: Box-Muller. `roll = clamp(1 + normal*0.15, 0.85, 1.15)`; resultado `baseStat * mult * roll`. Rarezas con stats FIJOS (`Unique` y superiores, via `ItemRarityData.HasFixedStats`) se copian verbatim, sin roll.
- **Passive slots por rareza**: delegado a `ItemRules.PassiveSlots(rarity)` (Domain). Recordatorio canonico: Broken–Superior:0, Epic–Mythic:1, Ancient–Relic:2, Legendary–Ascended:3, Divine–Celestial:4, Primordial+:5. Los passives se eligen sin reemplazo del pool de la definicion.
- **`StatAggregator.Aggregate`** — orden estricto: (1) base de clase escalada por nivel (`ClassBaseStats.For`), (2) stats aditivos de items + sus passives, (3/4) set bonuses (modifiers y passives), aplicando los **porcentajes acumulados de forma multiplicativa al final**, (5) `ApplyCaps()`. Caps canonicos (en Domain `CharacterStats.ApplyCaps`): CritRate <= 0.75, CritMultiplier <= 5.0, Resistencias <= 0.90.
- **`ItemValidator`**: `ValidateSteamOwnershipAsync` consulta cache -> `ISteamInventoryService` con retry (3 intentos, backoff exponencial 1s/2s/4s) y cachea el resultado. `ValidateSlotCompatibility` y `ValidateCharacterRestriction` aplican reglas estaticas de equip.
- **`SetBonusCalculator`**: agrupa piezas equipadas por `Item.SetId`, y por cada umbral `PiecesRequired <= count` emite un `ActiveSetBonus`. Carga los umbrales una vez y los cachea durante su vida (tabla de referencia pequena).
- **`SteamInventoryService`**: STUB que devuelve `true` siempre. La verificacion real contra el inventario Steam es de **F5** — no asumas que valida ownership de verdad.

## Seed

- `DbSeeder.SeedAsync` orquesta `ItemSeed` + `SetBonusSeed`. Se ejecuta one-shot desde la API con `SEED_AND_EXIT=true` (ver `make db-seed`).
- **Idempotente**: los ids se generan con `SeedIds.From("nombre")` (MD5 determinista). Solo inserta lo que falta.
- `ItemSeed`: 2 items early-game (Broken..Rare) por cada slot equipable (Head, Chest, Legs, Feet, Hands, MainHand, OffHand, Ring, Amulet) = ~18 items, **mas** las 4 piezas del **Ironclad Set** (Warrior, `ItemClass.Armor`, rareza Superior, `CharacterRestriction = Warrior`, `SetId = IroncladSetId`).
- `SetBonusSeed`: umbrales del Ironclad — 2-piece `+10% Defense`; 4-piece `+25% Defense` + passive `Unbreakable` (`+15% MaxHp`).
- Si anades items/sets nuevos, usa `SeedIds.From(...)` para mantener idempotencia y deriva `IsTradeable` de `ItemRarityData.IsTradeable(rarity)`.

## Conexiones (`ConnectionStringHelper`)

Convierte URIs estilo `.env` a los formatos nativos:
- `postgresql://user:pass@host:port/db` -> `NpgsqlConnectionStringBuilder`.
- `redis://host:port` (con password opcional) -> formato `host:port,password=...` de StackExchange.Redis.
- Si la cadena ya viene en formato key-value (sin `://`), se devuelve tal cual.

`AppDbContextFactory` (design-time) lee `POSTGRES_URL` del entorno (fallback `postgresql://idlerpg:secret@localhost:5432/idlerpg`).

## Comandos (desde la raiz del repo, via Makefile)

```bash
make db-migrate   # dotnet ef database update (--project IdleRPG.Infrastructure --startup-project IdleRPG.API)
make db-seed      # SEED_AND_EXIT=true dotnet run --project IdleRPG.API  (seed one-shot)
make db-reset     # drop --force -> db-migrate -> db-seed
make test-all     # debe pasar antes de cada commit "feat: phase-N complete"
```

Tests de esta capa: `dotnet test` (filtros por `Category`/`Phase`).

### Anadir una migracion

Las migraciones viven en este proyecto pero el startup project es la API (necesita la configuracion de DI y la cadena de conexion):

```bash
cd services/api
dotnet ef migrations add <NombrePascalCase> \
  --project IdleRPG.Infrastructure --startup-project IdleRPG.API \
  --output-dir Persistence/Migrations
make db-migrate    # aplicar
```

Pasos: (1) crea/edita la entidad en Domain, (2) crea/actualiza su `IEntityTypeConfiguration` aqui (se auto-descubre), (3) genera la migracion, (4) revisa el SQL generado (nombres en snake_case, indices, defaults `now()`, `jsonb`), (5) aplica con `make db-migrate`. Commitea siempre la migracion **y** el `AppDbContextModelSnapshot.cs` actualizado.

## Gotchas / errores comunes

- No registres Configurations manualmente: se descubren con `ApplyConfigurationsFromAssembly`. Pero un servicio nuevo **si** hay que registrarlo en `DependencyInjection`.
- El naming snake_case es automatico: si fijas un `HasColumnName`/`HasDatabaseName` en PascalCase, igualmente se convertira; para forzar un nombre exacto usa ya el snake_case (como `risk_score`, `idx_*`).
- Soft delete: las queries via `Repository<T>` NUNCA ven filas con `DeletedAt != null`. Para borrar de verdad o leer borrados, usa `IgnoreQueryFilters()` conscientemente.
- `SteamInventoryService` es un stub que valida `true` siempre: ownership "verde" en local no implica verificacion real hasta F5. No construyas logica que asuma validacion estricta todavia.
- `dotnet ef` necesita `--startup-project IdleRPG.API`; ejecutarlo solo sobre Infrastructure falla por falta de configuracion.
- Hangfire esta en el csproj pero **no hay jobs** todavia: no asumas que existe scheduling. IdleTickJob/anti-bot son F4/F6.
- Mantener la regla de oro: no saltar fases, `make test-all` verde, commits `feat: phase-N complete`.
