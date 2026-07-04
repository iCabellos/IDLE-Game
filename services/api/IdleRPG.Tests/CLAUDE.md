# CLAUDE.md - IdleRPG.Tests

Proyecto de **tests** del backend .NET (xUnit). Cubre las capas Domain, Application, Infrastructure y los flujos end-to-end (Integration) del API. Es la red de seguridad que valida el principio del plan maestro: **un test roto = no se avanza de fase**.

Ver tambien: `/CLAUDE.md` (indice raiz del monorepo y contexto canonico).

---

## Proposito y posicion en la arquitectura

`IdleRPG.Tests` referencia los **cuatro** proyectos de produccion (ver `IdleRPG.Tests.csproj`):

```
IdleRPG.Domain  <-  IdleRPG.Application  <-  IdleRPG.Infrastructure  <-  IdleRPG.API
                              ^------------------- IdleRPG.Tests -------------------^
```

El proyecto de tests es el unico que puede depender de todas las capas a la vez. **No** relaja la regla de dependencias del codigo de produccion: si un test necesita un tipo de Infrastructure (p.ej. `ItemFactory`, `JwtTokenService`, `AppDbContext`), eso es legitimo porque el test orquesta el sistema completo; pero no introduzcas referencias cruzadas nuevas entre los proyectos de produccion para "facilitar" un test.

Stack del proyecto (versiones exactas, NO cambiar sin motivo):
- `net8.0`, `ImplicitUsings` y `Nullable` habilitados.
- `xunit` 2.4.2 + `xunit.runner.visualstudio` 2.4.5.
- `FluentAssertions` **6.12.1** (API v6: usar `Should().Be(...)`, `BeApproximately`, `ThrowAsync<T>`; NO usar APIs de v7+).
- `Microsoft.AspNetCore.Mvc.Testing` 8.0.10 (`WebApplicationFactory<Program>`).
- `Testcontainers.PostgreSql` y `Testcontainers.Redis` 3.10.0.
- `Microsoft.NET.Test.Sdk` 17.6.0, `coverlet.collector` 6.0.0.

`GlobalUsings.cs` solo declara `global using Xunit;`. El resto de `using` (FluentAssertions, tipos de Domain/Application/Infrastructure) se importan explicitamente por archivo.

---

## Mapa de carpetas y archivos

```
IdleRPG.Tests/
  ApiTestBase.cs                 # Base de integration tests (Testcontainers + WebApplicationFactory)
  GlobalUsings.cs                # global using Xunit;
  SmokeTests.cs                  # [Phase=F0] runner + ConnectionStringHelper (sin contenedores)
  Domain/
    RarityTests.cs               # [Phase=F1] ItemRarity / ItemRarityData (21 tiers, mult, tradeable)
    RiskScoreTests.cs            # [Phase=F1] RiskScore value object + AntiBotRiskLevel thresholds
    SteamIdTests.cs              # [Phase=F1] SteamId value object (17 digitos)
  Application/
    Fakes.cs                     # TODOS los test doubles compartidos (ver abajo)
    GetMeHandlerTests.cs         # [Phase=F1]
    SteamLoginHandlerTests.cs    # [Phase=F1]
    RefreshAndLogoutHandlerTests.cs  # [Phase=F1]
    Items/
      ItemFactoryTests.cs        # [Category=ItemEngine] roll Box-Muller, passive slots
      ItemValidatorTests.cs      # [Category=ItemEngine] ownership Steam + retry/cache, slot, restriction
      SetBonusTests.cs           # [Category=ItemEngine] SetBonusCalculator (2/4 piezas Ironclad)
      StatAggregatorTests.cs     # [Category=ItemEngine] caps, set bonus, passives
      EquipItemHandlerTests.cs   # [Category=ItemEngine] equip/unequip, eviccion 2H, ownership
      InventoryAndCompareTests.cs# [Category=ItemEngine] GetInventory + CompareItems (texto, no numeros crudos)
  Infrastructure/
    JwtTokenServiceTests.cs      # [Phase=F1] claims, expiracion 900s, hash refresh token
  Integration/
    IntegrationCollection.cs     # [CollectionDefinition("Integration", DisableParallelization=true)]
    AuthEndpointsTests.cs        # [Phase=F1][Collection=Integration] flujo login/refresh/logout E2E
    Database/
      SchemaTests.cs             # [Phase=F2][Collection=Integration] tablas, triggers, indices, soft delete, seed
      SetBonusSchemaTests.cs     # [Phase=F3][Collection=Integration] tabla items_set_bonuses + seed idempotente
```

---

## Convencion de Traits y filtros (IMPORTANTE)

El proyecto usa **dos** esquemas de `[Trait]` en paralelo. Respetalos al anadir tests nuevos:

| Trait | Valores en uso hoy | Para que |
|-------|--------------------|----------|
| `Phase` | `F0`, `F1`, `F2`, `F3` | Tests ligados a un hito del plan maestro (Domain, Auth, DB schema). |
| `Category` | `ItemEngine` | Motor de items de F3 (factory/validator/setbonus/aggregator y use cases de equipo/inventario). |

Notas de la convencion REAL observada (no inventar otras):
- Las pruebas **unitarias** del motor de items usan `[Trait("Category", "ItemEngine")]` y **no** llevan `Phase`. Solo `SetBonusSchemaTests` (test de **schema/DB** de F3) lleva `[Trait("Phase", "F3")]`.
- Las clases de integration tests llevan ademas `[Collection("Integration")]`.

Filtros tipicos con `dotnet test`:

```bash
# Solo una fase
dotnet test --filter "Phase=F1"

# Solo el motor de items
dotnet test --filter "Category=ItemEngine"

# Excluir integration (no requiere Docker): combina ausencia de la collection.
# Los unit tests puros (Domain, Application/Items, Infrastructure/Jwt, SmokeTests)
# NO tocan contenedores; los de Integration/ SI.
dotnet test --filter "Phase=F0|Phase=F2"
```

Al crear un test nuevo:
- Si valida una entidad/contrato de una fase concreta -> `[Trait("Phase", "Fx")]`.
- Si extiende el motor de items -> `[Trait("Category", "ItemEngine")]`.
- Si es de integracion (toca DB/Redis reales) -> hereda `ApiTestBase` y anade `[Collection("Integration")]`.

---

## Integration tests: `ApiTestBase`

`ApiTestBase` (clase abstracta, implementa `IAsyncLifetime`) es la base de **todo** test de integracion. Comportamiento clave a tener en cuenta:

- Levanta contenedores desechables via Testcontainers: `postgres:16-alpine` (db `idlerpg_test`) y `redis:7-alpine`. **Requiere Docker corriendo**; si no, estos tests fallan al iniciar (no es un bug del codigo).
- En `InitializeAsync` setea **variables de entorno de proceso** ANTES de construir el host, porque `Program.cs` lee la configuracion de forma temprana (antes del callback `ConfigureAppConfiguration` del test). Variables: `POSTGRES_URL`, `REDIS_URL`, `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`.
- Como esas env vars son globales de proceso, los integration tests **no pueden correr en paralelo entre si**: por eso existe `IntegrationCollection` con `DisableParallelization = true`. Toda clase de integracion debe declarar `[Collection("Integration")]`.
- Construye `WebApplicationFactory<Program>` con entorno `"Testing"` y aplica migraciones reales (`db.Database.MigrateAsync()`) en el arranque.
- Para sustituir servicios por dobles, sobrescribe `ConfigureTestServices(IServiceCollection)`. Patron observado en `AuthEndpointsTests`: `services.RemoveAll<ISteamAuthService>()` y registrar un `FakeSteamAuthService` para que la verificacion OpenID de Steam sea determinista.
- Expone `Factory` y `Client` (HttpClient); en `DisposeAsync` libera client, factory y ambos contenedores.

`Program` es accesible porque `IdleRPG.API` referencia con un `InternalsVisibleTo`/`public partial class Program` (el patron estandar de minimal hosting + WebApplicationFactory). No cambies la visibilidad de `Program` sin verificar que la factory sigue compilando.

---

## Test doubles compartidos (`Application/Fakes.cs`)

Todos los dobles in-memory viven en un unico archivo `Fakes.cs` (namespace `IdleRPG.Tests.Application`). Reusa estos antes de crear nuevos:

- `InMemoryRepository<T> : IRepository<T>` — implementacion en memoria que **compila y evalua** `ISpecification<T>.Criteria` localmente (`Criteria.Compile()`). Constructor recibe un `Func<T,Guid>` selector de id.
- `FakeUnitOfWork : IUnitOfWork` — no-op que cuenta `SaveCount` (se afirma en handler tests para verificar que se persistio una vez, o cero en no-ops).
- `FakeJwtTokenService : IJwtTokenService` — tokens deterministas (`access-for-{id}`, hash `hash:{raw}`), lifetimes 900s / 7d.
- `FakeSteamAuthService : ISteamAuthService` — configurable via `SteamIdToReturn` y `SummaryToReturn`.
- `FakeCurrentUserService : ICurrentUserService` — setea `UserId` / `SteamId`; `IsAuthenticated` deriva de `UserId`.
- `FakeCacheService : ICacheService` — diccionario en memoria; se inspecciona `Store` para verificar claves de cache (p.ej. `stats:{characterId}`, `steam:owns:{steamId}:{assetId}`).
- `FakeSteamInventoryService : ISteamInventoryService` — `Owns` (bool), `Behavior` (delegate para simular fallos transitorios) y `Calls` (contador, usado para verificar cache hits y reintentos).

---

## Que esta cubierto HOY (Implementado) vs Planificado

### Implementado (con tests verdes)
- **F0**: `SmokeTests` — runner + parsing de connection strings (`ConnectionStringHelper`).
- **F1 Domain**:
  - `ItemRarity` / `ItemRarityData`: 21 tiers (Broken=1 .. OneOfOne=21), multiplicadores (Broken 0.30, Common 0.70, Legendary 4.00, Transcendent 16.0), tiers fijos no tradeables (Unique/Seasonal/Founder/EventLimited/OneOfOne con `Multiplier == null`, `HasFixedStats == true`, `IsTradeable == false`), drop percent decreciente.
  - `RiskScore` (clamp 0-100, `Apply(delta)`, mapeo a `AntiBotRiskLevel`: Normal/SilentMonitor/VisibleWarning/GameplayRestrict/MarketRestrict/TempSuspension/PermanentBan).
  - `SteamId` (validacion 17 digitos, `TryCreate`, trim).
- **F1 Auth (Application + Infrastructure)**: `GetMeHandler`, `SteamLoginHandler` (alta de usuario, returning user, baneado, fallback `Player_*`), `RefreshTokenHandler`, `LogoutHandler`, `JwtTokenService` (claims `sub`/`steam`/`name`, expiracion 900s, hash refresh determinista).
- **F1 Integration**: `AuthEndpointsTests` (E2E login -> /auth/me -> refresh -> logout contra Postgres/Redis reales).
- **F2 Integration (DB schema)**: `SchemaTests` — existencia de tablas (`users`, `characters`, `items`, `item_instances`, `refresh_tokens`, `anti_bot_events`), triggers `trg_*_updated_at`, indice unico `item_instances.steam_inventory_id`, CHECK de risk score `BETWEEN 0 AND 100`, soft delete (`DeletedAt` filter + `IgnoreQueryFilters`), seeder de catalogo (>=20 items, set Ironclad de 4 piezas restringido a Warrior, `SteamMarketHashName` no vacio) e idempotencia.
- **F3 Motor de items (Category=ItemEngine)**:
  - `ItemFactory`: roll dentro del rango `baseStat * RarityMult * [0.85, 1.15]` (Box-Muller con clamp), passive slots por rareza (`ItemRules.PassiveSlots`), rarezas fijas no se rollean, cap por tamano del pool, set de ownership/identidad, throw si falta la definicion.
  - `ItemValidator`: ownership Steam con cache (`steam:owns:{steamId}:{assetId}`) y reintentos (3 intentos, backoff inyectable), compatibilidad de slot, restriccion de clase.
  - `SetBonusCalculator`: thresholds 2/4 piezas del set Ironclad, piezas sueltas ignoradas.
  - `StatAggregator`: base por clase/nivel, suma flat de items, % de set bonus sumado, passives, caps (`CritRate<=0.75`, `CritMultiplier<=5.0` con floor 1.5, resistencias `<=0.90`).
  - Use cases `EquipItemHandler`/`UnequipItemHandler` (eviccion de slot, 2H expulsa MainHand+OffHand y viceversa, ownership/forbidden/notfound), `GetInventoryHandler` (filtros por rareza/slot, paginacion, solo items del caller), `CompareItemsHandler` (devuelve **texto** descriptivo como "Better for crits", no numeros crudos — coherente con la regla UX).
- **F3 Integration (DB)**: `SetBonusSchemaTests` — tabla `items_set_bonuses`, seed de 2 bonuses Ironclad (passive "Unbreakable" en 4-piezas), unicidad de threshold por set, idempotencia.

### Planificado (aun SIN tests aqui, no inventar cobertura)
- **F4 Combat/Idle engine**: **Implementado** — `Domain/Combat/` (`CombatFormulasTests`, `CombatEngineTests`, `CombatBalanceTests` con bands de duracion/muros y el benchmark **10k ticks < 100ms**) y `Application/Combat/IdleProgressAndHandlersTests` (starter team, claim con level-ups e invalidacion de `stats:{id}`, zonas). Traits: `[Trait("Phase","F4")]` y `[Trait("Category","CombatEngine")]`.
- **F5 Steam**: solo existe `FakeSteamInventoryService`/`FakeSteamAuthService`; el `SteamInventoryService` real es stub, sin tests de integracion contra el bridge.
- **F6 Anti-bot**: cubierto SOLO a nivel Domain (`RiskScore` + `AntiBotRiskLevel`). Sin tests del scoring en Redis (TTL 24h, decay -1/6h) ni de las acciones por threshold.
- **F7 Flutter, F8 Widget Android, F9 Meta**: fuera de este proyecto (tests Flutter viven en `apps/mobile`, ejecutados via `make test-flutter`).

---

## Comandos (desde la raiz del repo)

```bash
make test-all        # test-api (+ test-flutter si flutter esta instalado)
make test-api        # cd services/api && dotnet test  (TODA la suite .NET)
```

Directamente con dotnet (desde `services/api/`):

```bash
dotnet test                                  # toda la solucion
dotnet test --filter "Phase=F1"              # por fase
dotnet test --filter "Category=ItemEngine"   # motor de items
dotnet test IdleRPG.Tests/IdleRPG.Tests.csproj
```

Migraciones / DB (relevante para integration tests que dependen del schema):

```bash
make db-migrate   # dotnet ef database update (proj Infrastructure, startup API)
make db-reset     # drop + migrate + seed
```

---

## Gotchas y errores comunes

- **Docker obligatorio para Integration**: cualquier test que herede `ApiTestBase` arranca contenedores Postgres/Redis. Si Docker no esta disponible, fallaran en `InitializeAsync` — no es regresion de logica. Para iterar rapido en logica de dominio/handlers, filtra a unit tests (`Domain`, `Application/Items`, `Infrastructure`, `SmokeTests`).
- **No paralelizar integration**: usan env vars globales de proceso. Siempre `[Collection("Integration")]`. No crees una segunda collection que corra en paralelo con esta.
- **FluentAssertions v6**: el proyecto fija 6.12.1. Usa la API de v6 (no `.Should().BeXxx()` exclusivos de v7). Para floats usar `BeApproximately(expected, tolerancia)` (los stats son `float` y el roll es estocastico).
- **Determinismo del roll**: `ItemFactory` recibe un `Random` inyectable; los tests usan semillas fijas (`new Random(12345)`, `new Random((int)rarity*7+1)`). Manten esa inyeccion: no introduzcas `Random` estatico/no-determinista en produccion o romperas estos tests.
- **Backoff inyectable en `ItemValidator`**: los tests construyen el validator con `_ => TimeSpan.Zero` para que los reintentos no duerman. Si cambias la firma de retry/backoff, actualiza `BuildValidator`/`Harness.BuildEquip`.
- **Caps duros**: los tests afirman valores exactos de los caps (`CharacterStats.CritRateCap == 0.75`, `CritMultiplierCap == 5.0`, `ResistCap == 0.90`). No los conviertas en configurables sin actualizar `StatAggregatorTests`.
- **Regla UX en compare**: `CompareItemsHandler` devuelve descripciones de texto (p.ej. "Better for crits"), nunca numeros crudos. Si extiendes la comparacion, manten esa salida textual (los tests la verifican literalmente).
- **Schema afirmado por nombre**: `SchemaTests`/`SetBonusSchemaTests` consultan `information_schema` y `pg_trigger` por nombres exactos de tabla/trigger (`users`, `item_instances`, `items_set_bonuses`, `trg_users_updated_at`, ...). Si renombras tablas o triggers en una migracion, actualiza estos tests en el mismo commit.
- **Filosofia de fase**: cada fase asume la anterior commiteada y con tests verdes. Antes de "feat: phase-N complete", `make test-all` debe pasar. Un test roto bloquea el avance — arregla la causa raiz, no marques `[Fact(Skip=...)]` salvo justificacion explicita.
