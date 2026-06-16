# CLAUDE.md - IdleRPG.Application

Capa **Application** del backend (Clean Architecture, CQRS con MediatR). Orquesta los casos de uso del juego apoyandose solo en abstracciones de `IdleRPG.Domain`. No conoce EF Core, Redis, HTTP ni Steam de forma concreta: todo eso entra por interfaces que implementa `IdleRPG.Infrastructure`.

Ver tambien: `/CLAUDE.md` (plan maestro, fases F0..F9, stack, enums y formulas canonicas).

---

## Proposito y regla de dependencias

- Regla ESTRICTA: `Domain <- Application <- Infrastructure <- API`. Este proyecto **solo** referencia `IdleRPG.Domain` (ver `IdleRPG.Application.csproj`). NUNCA agregar referencia a `Infrastructure`, `API`, EF Core, Npgsql, StackExchange.Redis, Serilog, Hangfire ni HTTP clients aqui.
- Toda dependencia externa se expresa como **interface** (en `Interfaces/` de este proyecto, o ya definida en `Domain.Interfaces`). La implementacion vive en `Infrastructure`.
- Paquetes permitidos (ya en el `.csproj`, versiones fijas del plan): `MediatR 12.4.1`, `FluentValidation 11.10.0` (+ `DependencyInjectionExtensions`), `Microsoft.Extensions.Logging.Abstractions 8.0.2`, `Microsoft.Extensions.DependencyInjection.Abstractions 8.0.2`. `net8.0`, `ImplicitUsings` y `Nullable` activados. No introducir paquetes nuevos sin justificarlo contra el plan.

---

## Patron CQRS (convencion observada)

Cada caso de uso vive en `UseCases/<Feature>/<Nombre>/` y consta de hasta 3 archivos:

- `<Nombre>Command.cs` o `<Nombre>Query.cs`: `record` que implementa `IRequest<TResponse>` de MediatR. Convencion: **Command** muta estado, **Query** solo lee. El tipo de retorno (`TResponse`) es siempre un DTO de `DTOs/` (o `MediatR.Unit` para comandos sin retorno, p.ej. `LogoutCommand : IRequest<Unit>`).
- `<Nombre>Handler.cs`: `sealed class ... : IRequestHandler<TRequest, TResponse>`. Inyecta dependencias por constructor (repositorios e interfaces de servicio). El `CancellationToken` se llama `ct`.
- `<Nombre>Validator.cs` (opcional): `sealed class ... : AbstractValidator<TRequest>` de FluentValidation. Solo validacion de forma/entrada (no nulos, enum valido). Las reglas de **dominio** (ownership, slots, clase) van en el handler via `IItemValidator`, no aqui.

Flujo de un request: `API` envia el `Command/Query` por `IMediator` -> `ValidationBehavior` corre todos los validators registrados -> si hay fallos lanza `FluentValidation.ValidationException` (la API la mapea a 400) -> si pasa, ejecuta el `Handler`.

### Registro DI (`DependencyInjection.cs`)
`AddApplication()` registra por reflexion (usando `AssemblyMarker`):
- `AddMediatR(...RegisterServicesFromAssembly)` (todos los handlers).
- `AddValidatorsFromAssembly` (todos los `AbstractValidator`).
- `IPipelineBehavior<,>` -> `ValidationBehavior<,>` (transient).
- `ICharacterStatsService` -> `CharacterStatsService` (scoped).

Al agregar un handler o validator nuevo NO hace falta tocar DI (se descubren por assembly). Si agregas un **servicio** propio de Application (como `CharacterStatsService`), registralo a mano aqui.

---

## Mapa de carpetas

```
Common/
  Behaviors/ValidationBehavior.cs   Pipeline MediatR que corre FluentValidation antes del handler.
  Exceptions/                       AuthenticationException, ForbiddenException, NotFoundException,
                                    DomainValidationException (todas sealed, message-only).
  Specifications/                   Specs concretas (heredan Domain.Specifications.BaseSpecification<T>).
  ValidationResult.cs               record (IsValid, Error?) con Success()/Fail(); lo usa IItemValidator.
DTOs/
  Auth/   LoginResultDto, RefreshResultDto, SteamPlayerSummary, UserDto.
  Items/  InventoryItemDto, PagedResult<T>, CharacterSummaryDto, ItemComparisonDto.
Interfaces/
  Auth/    IJwtTokenService, ISteamAuthService.
  Caching/ ICacheService.
  Items/   IItemFactory, IItemValidator, ISetBonusCalculator, IStatAggregator,
           ICharacterStatsService, ISteamInventoryService.
Services/
  CharacterStatsService.cs          Unica impl. de servicio que vive en Application.
UseCases/
  Auth/  SteamLogin, RefreshToken, Logout, GetMe.
  Items/ EquipItem, UnequipItem, GetInventory, CompareItems.
AssemblyMarker.cs                   Marker para descubrir el assembly en DI.
DependencyInjection.cs              AddApplication().
```

---

## Use cases implementados (estado real)

Todos **Implementados** (F1 Auth, F3 motor de items). El motor de combate/idle (F4) y el resto NO existen aun.

### Auth (F1)
- `SteamLogin` (`SteamLoginCommand(string OpenIdPayload)` -> `LoginResultDto`): valida OpenID 2.0 via `ISteamAuthService.ValidateOpenIdAsync`, hace upsert del `User` (`UserBySteamIdSpec`), rechaza baneados (`IsBanned`/`AccountStatus.Banned`), emite access JWT + refresh token (hash SHA-256 persistido), guarda con `IUnitOfWork`. Tiene validator (payload no vacio).
- `RefreshToken` (`RefreshTokenCommand(string RefreshToken)` -> `RefreshResultDto`): hashea el token, busca por `RefreshTokenByHashSpec`, valida `IsActive` + `User != null`, emite nuevo access token. Tiene validator.
- `Logout` (`LogoutCommand(string RefreshToken)` -> `Unit`): revoca el refresh token (`RevokedAt = now`). Sin validator (tolera token vacio: no-op).
- `GetMe` (`GetMeQuery` -> `UserDto`): lee `ICurrentUserService.UserId` y devuelve el perfil.

### Items (F3)
- `EquipItem` (`EquipItemCommand(Guid CharacterId, Guid ItemInstanceId, ItemSlot TargetSlot)` -> `CharacterSummaryDto`): pipeline de validaciones en orden -> personaje del user, instancia del user, definicion existe, **Steam ownership** (`IItemValidator.ValidateSteamOwnershipAsync`), compatibilidad de slot, restriccion de clase; luego desaloja ocupantes en slots en conflicto (logica `ConflictsWith`: `TwoHand` choca con `MainHand`/`OffHand`/`TwoHand`), equipa, guarda y recalcula stats. Tiene validator.
- `UnequipItem` (`UnequipItemCommand(Guid CharacterId, Guid ItemInstanceId)` -> `CharacterSummaryDto`): valida ownership y que la instancia este equipada en ese personaje, la libera, guarda y recalcula stats. Tiene validator.
- `GetInventory` (`GetInventoryQuery(int Page=1, int Size=20, ItemRarity? Rarity=null, ItemSlot? Slot=null)` -> `PagedResult<InventoryItemDto>`): lista del owner (`ItemInstancesByOwnerSpec`), filtra por rarezas/slot, pagina (clamp Size a [1,100]). `IsTradeable` se deriva de `ItemRarityData.IsTradeable`.
- `CompareItems` (`CompareItemsQuery(Guid InstanceId1, Guid InstanceId2)` -> `ItemComparisonDto`): compara dos instancias del user.

#### REGLA CRITICA: CompareItems devuelve TEXTO DESCRIPTIVO, NUNCA numeros crudos
`ItemComparisonDto = { Guid? BetterItem, IReadOnlyList<string> Improvements }`. El handler calcula internamente un score y deltas porcentuales, pero **solo expone strings descriptivos** (p.ej. `"Attack +23%"`, `"Better for crits"`, `"Adds {stat}"`, `"Marginally better overall"`, `"The two items are roughly equivalent."`). Esto materializa la regla UX del plan: el usuario nunca ve stats absolutos. Al editar este handler o el DTO, **no** anadir campos numericos de stats absolutos al DTO de salida.

---

## Interfaces (contratos clave; impl. en Infrastructure)

- `Interfaces/Auth/IJwtTokenService`: `CreateAccessToken(User)` (claims sub/steam/name, 15 min), `CreateRefreshToken() -> (RawToken, TokenHash)`, `HashRefreshToken(raw)` (SHA-256), `AccessTokenLifetimeSeconds` (900), `RefreshTokenLifetimeDays` (7).
- `Interfaces/Auth/ISteamAuthService`: `ValidateOpenIdAsync(payload)` -> Steam64 id o null; `GetPlayerSummaryAsync(steamId)` -> `SteamPlayerSummary?`.
- `Interfaces/Caching/ICacheService`: `GetAsync<T>/SetAsync<T>(ttl)/RemoveAsync`. Wrapper tipado sobre Redis.
- `Interfaces/Items/IItemValidator`: `ValidateSteamOwnershipAsync(steamId, steamInventoryId)`, `ValidateSlotCompatibility`, `ValidateCharacterRestriction` -> todos `ValidationResult`.
- `Interfaces/Items/ICharacterStatsService` (impl. en `Services/`): `RecalculateAndCacheAsync(Character)` -> `CharacterSummaryDto`. Cachea `CharacterStats` en Redis key `stats:{characterId}` con TTL 1h.
- `Interfaces/Items/IItemFactory`, `ISetBonusCalculator`, `IStatAggregator`: motor F3 (Box-Muller, set bonuses, caps). Implementados en Infrastructure.
- `Interfaces/Items/ISteamInventoryService`: `OwnsAssetAsync(...)`. **Planificado (F5)**: la doc del propio archivo dice "full implementation arrives in F5"; hoy el backing real es stub.

Interfaces consumidas desde `IdleRPG.Domain.Interfaces` (no estan en este proyecto): `ICurrentUserService` (`UserId`, `SteamId`, `IsAuthenticated`), `IRepository<T>` (`GetByIdAsync`, `GetAllAsync(spec?)`, `FirstOrDefaultAsync(spec)`, `AddAsync`, `Update`, `Delete`; honra soft-delete), `IUnitOfWork` (`SaveChangesAsync`, `Begin/Commit/Rollback`). Specs heredan de `Domain.Specifications.BaseSpecification<T>` (`AddInclude`, `ApplyOrderBy[Descending]`).

---

## Excepciones y manejo de errores

Los handlers lanzan excepciones de `Common/Exceptions/`; la **API** las mapea a HTTP (no manejes status codes aqui):
- `AuthenticationException` (login/token invalido, no autenticado) -> 401.
- `ForbiddenException` (recurso de otro user) -> 403.
- `NotFoundException` (entidad inexistente) -> 404.
- `DomainValidationException` (regla de dominio: slot, clase, ownership Steam) -> 400/422.
- `FluentValidation.ValidationException` (la lanza `ValidationBehavior`) -> 400.

Patron recurrente de autorizacion en handlers: `if (_currentUser.UserId is not { } userId) throw new AuthenticationException(...)`, y luego verificar que la entidad pertenece a `userId` (`OwnerId`/`UserId`).

---

## Convenciones de codigo observadas

- Clases `sealed`; handlers/validators `sealed class`; commands/queries y DTOs como `record`.
- `CancellationToken` siempre `ct`; pasarlo a todas las llamadas async.
- Namespaces file-scoped que reflejan la carpeta (`IdleRPG.Application.UseCases.Items.EquipItem`).
- DTOs con `init` y defaults seguros (`= string.Empty`, `Array.Empty<T>()`); enums se serializan a string en DTOs (p.ej. `Rarity`, `Slot`, `AccountStatus` como `"active|warned|restricted|banned"`).
- Alias `using TokenEntity = IdleRPG.Domain.Entities.RefreshToken;` en handlers de Auth para evitar choque con el namespace `UseCases.Auth.RefreshToken`.
- Formateo numerico con `CultureInfo.InvariantCulture` (importante en strings descriptivos de comparacion y set bonuses).
- Specs concretas en `Common/Specifications/` encapsulan los `Include`/orden; no escribir predicados LINQ crudos en los handlers, crear/usar una Spec.

---

## Comandos (desde la raiz del repo)

- Build de toda la solucion .NET: `make build` o `dotnet build` (este proyecto se compila como parte de la solucion en `services/api`).
- Tests: `make test-all`; filtrados por fase/categoria: `dotnet test --filter Category=...` / `--filter Phase=...`. Los tests de esta capa cubren handlers y validators (con dobles de las interfaces).
- Migraciones / DB (`make db-migrate`, `make db-reset`): **no aplican aqui** (Application no toca EF Core; vive en Infrastructure/API).
- `make dev`, `make clean`, Docker: ver `/CLAUDE.md`.

---

## Gotchas

- No filtrar in-memory lo que deberia ser una Spec/consulta: hoy `GetInventory` trae todo del owner y filtra/pagina en memoria. Si crece, mover filtros a una Spec, pero manteniendo la abstraccion `IRepository`.
- `CompareItems` y `CharacterStatsService.Describe` calculan numeros pero **emiten solo texto/porcentajes descriptivos** hacia el cliente. No filtrar stats absolutos al DTO de salida (regla UX).
- `CharacterSummaryDto.Stats` es `IReadOnlyDictionary<string,float>` con numeros: es uso interno/backend; el frontend NO debe renderizar esos numeros crudos (ver regla UX en `/CLAUDE.md`).
- Steam ownership en `EquipItem` depende de `ISteamInventoryService`, cuyo backing real es **F5 (planificado)**; hoy puede comportarse como stub. No asumir validacion Steam end-to-end real todavia.
- Al anadir un Command/Query nuevo: crear los 3 archivos en su carpeta, usar DTO de `DTOs/`, lanzar las excepciones de `Common/Exceptions/`; DI los recoge solo (handlers/validators). Solo registra manualmente servicios nuevos en `DependencyInjection.cs`.
- No tragar la `ValidationException` de FluentValidation en los handlers: el `ValidationBehavior` ya corre antes; la API la mapea.
