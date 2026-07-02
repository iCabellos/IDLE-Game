# CLAUDE.md — IdleRPG.Domain

Ver tambien: /CLAUDE.md (indice raiz del monorepo).

## Proposito

Capa **Domain** de la Clean Architecture del backend .NET (`services/api/`). Contiene el modelo de negocio puro del IDLE RPG: `Entities`, `Enums` canonicos, `ValueObjects`, `GameData` (reglas y datos de balance estaticos), `Interfaces` (abstracciones de persistencia/identidad) y `Specifications`.

Es la base de la regla de dependencias. **Aqui se definen UNA SOLA VEZ los enums y contratos** que se usan en `Application`, `Infrastructure` y `API`.

Estado general: **Implementado** (corresponde a F1–F3 del plan). El proyecto compila con `net8.0`, `ImplicitUsings` y `Nullable` habilitados.

## Regla de dependencias (CRITICA)

`Domain` NO tiene NINGUNA dependencia externa. El `.csproj` no tiene `PackageReference` ni `ProjectReference` y debe seguir asi.

```
Domain  <-  Application (solo Domain)  <-  Infrastructure (Application)  <-  API (Infrastructure)
```

Gotchas / errores comunes a evitar:
- **NO** referenciar EF Core, MediatR, FluentValidation, Npgsql, Redis, Serilog, ASP.NET, ni ningun otro paquete aqui. Si necesitas eso, el codigo va en otra capa.
- Solo se permite la BCL de .NET (`System.*`). Ya se usa `System.Text.Json` (en `RolledItemData`, `SetBonusPayload`) y `System.Linq.Expressions` (en `ISpecification`/`BaseSpecification`); ambos son BCL, estan OK.
- Las entidades NO contienen logica de acceso a datos. La persistencia se configura en `Infrastructure` (EF Core mappings, soft-delete filter, triggers de timestamps).

## Mapa de carpetas y archivos

Namespace raiz: `IdleRPG.Domain`. Cada subcarpeta = sub-namespace (`IdleRPG.Domain.Entities`, etc.). Convencion: un tipo por archivo, nombre de archivo = nombre del tipo.

### `Entities/` — entidades persistidas (todas Implementadas)
Clases POCO con propiedades `{ get; set; }`, `Guid Id`, y propiedades de navegacion nullables al final.
- `User` — jugador identificado por `SteamId`. Campos: `AccountLevel`, `Status` (`AccountStatus`), `AntiBotRiskScore`, `IsBanned`/`BannedAt`/`BanReason`, `CreatedAt`/`UpdatedAt`/`LastLoginAt`, `DeletedAt` (soft delete). Nav: `Characters`.
- `Character` — personaje de un `User`. `Class`/`Role`, `Level` (1–1000), `Experience`, `TeamSlot` (0–3), `IsActive`, `StatsJson` (snapshot serializado de `CharacterStats`). Soft delete. Nav: `User`, `EquippedItems`.
- `Item` — **definicion/plantilla** global de item (no instancia). `Class`/`BaseRarity`/`Slot`, `CharacterRestriction?`, `SetId?`, `BaseStatsJson`, `PassivesJson`, `IsUnique`/`IsSeasonal`, `SteamMarketHashName?`, `IsTradeable`.
- `ItemInstance` — instancia concreta poseida. `ItemId`/`OwnerId`, `SteamInventoryId` (indice unico), `RolledRarity`, `RolledStatsJson` (ver `RolledItemData`), `AcquiredAt`, equipamiento (`EquippedToCharacterId?`/`EquippedSlot?`), `IsListedOnMarket`, `LastSteamValidation?`. Nav: `Item`, `Owner`, `EquippedToCharacter`.
- `RefreshToken` — token de refresco hasheado. Guarda `TokenHash` (SHA-256 hex), nunca el raw. `IsActive` es propiedad calculada (`RevokedAt is null && ExpiresAt > UtcNow`).
- `SetBonus` — bonus de set por umbral (`PiecesRequired`) sobre un `SetId`; payload en `StatBonusesJson` (ver `SetBonusPayload`).
- `AntiBotEvent` — registro de auditoria anti-bot. `EventType` (`BotEventType`), `RiskDelta`, `NewScore`, `ActionTaken` (`AntiBotRiskLevel`), `MetadataJson`. La logica de scoring/decay vive en F6 (Planificado), no aqui.

Notas de persistencia (configuradas en `Infrastructure`, pero relevantes al modelar aqui): todas las entidades llevan `CreatedAt`/`UpdatedAt` (trigger); soft delete global por `DeletedAt == null` (presente en `User`, `Character`). Indices unicos: `users.steam_id`, `item_instances.steam_inventory_id`.

### `Enums/` — enums canonicos (Implementados)
**Estos enums son la fuente de verdad de todo el codebase. Usar los valores tal cual; no inventar variantes ni reordenar.** Los valores numericos son explicitos y estables (se persisten / serializan).
- `CharacterClass` — `Warrior=1 .. Trickster=10` (10 clases).
- `CharacterRole` — `DPS=1, Tank=2, Healer=3, Support=4, Hybrid=5`.
- `ItemClass` — `Armor=1, Weapon=2, Accessory=3, Relic=4`.
- `ItemSlot` — `Head=1 .. TwoHand=10, Relic1=11, Relic2=12` (Relic1/2 se desbloquean post-Legendary).
- `ItemRarity` — **21 niveles** (`Broken=1 .. OneOfOne=21`). Tiers 1–16 (`Broken..Transcendent`) tienen multiplicador de stats numerico y son tradeable. Tiers 17–21 (`Unique`, `Seasonal`, `Founder`, `EventLimited`, `OneOfOne`) tienen stats **FIXED** (multiplicador `null`) y **NO tradeable**.
- `ItemRarityData` — tabla de referencia `RarityInfo(float? Multiplier, double DropPercent, bool Tradeable)` por tier. API estatica: `Get`, `Multiplier`, `DropPercent`, `IsTradeable`, `HasFixedStats` (true cuando `Multiplier is null`, es decir Unique y superiores). **Acceder a multiplicadores/drop/tradeability SIEMPRE via esta clase**, no hardcodear numeros.
- `AccountStatus` — `Active=1, Warned=2, Restricted=3, Banned=4`. Se serializa a DTO como string en minuscula: `active|warned|restricted|banned`.
- `AntiBotRiskLevel` — `Normal=0 .. PermanentBan=6`, con la accion de enforcement por rango de score documentada en comentarios (0-20 sin accion … 91-100 ban permanente).
- `BotEventType` — 8 tipos (`AbnormalRequestFrequency=1 .. VpnDetected=8`).
- `BotEventTypeData` — diccionario de delta de riesgo por `BotEventType` (`Delta(type)`). Valores tomados del plan (F6).
- `ModifierType` — `Flat=1` (suma plana), `Percent=2` (fraccion, 0.10 = +10%, aplicada multiplicativamente tras los flats).

### `ValueObjects/` — value objects inmutables (Implementados)
`record` / `readonly record struct`. Inmutables; preferir `with` para derivar copias.
- `CharacterStats` (`record`) — snapshot inmutable de stats (primarios, criticos, 5 resistencias, 2 penetraciones, e idle: `IdleEfficiency`/`DropRate`/`Luck`). Constantes de cap: `CritRateCap=0.75`, `CritMultiplierCap=5.0`, `ResistCap=0.90`. Helpers: `Zero`, `ToDictionary()`/`FromDictionary()` (clave = `nameof` de cada propiedad), `ApplyCaps()` (clamp final; `CritMultiplier` se clamp a `[1.5, 5.0]`). El cap real lo impone el `StatAggregator` (en `Application`, F3).
- `SteamId` (`readonly record struct`) — Steam64 validado (17 digitos numericos, rango 7656119...). `Create` (lanza) / `TryCreate` (patron try). Conversion implicita a `string`.
- `RiskScore` (`readonly record struct`) — score anti-bot clamp `[0,100]` (`Min`/`Max`). `Apply(delta)` devuelve nuevo score; `Level` mapea a `AntiBotRiskLevel` por umbrales. Conversion implicita a `int`.
- `RolledItemData` (`record`) — payload por instancia: `Stats` (dict nombre→float) + `Passives`. (De)serializa el `ItemInstance.RolledStatsJson` via `Serialize`/`Parse`; `Parse` tolera la forma legacy (dict de stats plano sin passives). `JsonOptions` con `PropertyNamingPolicy = null` (claves PascalCase tal cual).
- `Passive` (`record`) — habilidad pasiva con nombre + lista de `StatModifier`.
- `StatModifier` (`record`) — `(string Stat, float Value, ModifierType Type = Flat)`. `Stat` debe coincidir con un `nameof` de propiedad de `CharacterStats`.
- `ActiveSetBonus` (`record`) — set bonus activo (piezas equipadas vs requeridas + modifiers/passives).
- `SetBonusPayload` (`record`) — contenido deserializado de `SetBonus.StatBonusesJson` (modifiers + passives); `Serialize`/`Parse`.

### `GameData/` — datos de balance estaticos (Implementados)
- `ClassBaseStats` — base stats por clase escalados linealmente con el nivel (growth por nivel × level). Secundarios (crit, idle, etc.) usan baselines compartidos. API: `For(CharacterClass, level)`. Clase desconocida cae a `Warrior`; `level` se clampa a min 1.
- `ItemRules` — reglas estaticas de items. `PassiveSlots(rarity)`: Broken–Superior=0, Epic–Mythic=1, Ancient–Relic=2, Legendary–Ascended=3, Divine–Celestial=4, Primordial+=5.

### `Interfaces/` — abstracciones (Implementadas)
Contratos consumidos por `Application` e implementados por `Infrastructure`.
- `IRepository<T> where T : class` — `GetByIdAsync`, `GetAllAsync(spec?)`, `FirstOrDefaultAsync(spec)`, `AddAsync`, `Update`, `Delete`. Las implementaciones deben respetar el filtro de soft-delete.
- `IUnitOfWork` — `SaveChangesAsync`, `BeginTransactionAsync`, `CommitAsync`, `RollbackAsync`.
- `ICurrentUserService` — `UserId?`, `SteamId?`, `IsAuthenticated` (identidad del request actual).
- `ISpecification<T>` — `Criteria`, `Includes`, `OrderBy`/`OrderByDescending`, `Skip`/`Take`. Usa `System.Linq.Expressions` (BCL) para no filtrar EF Core a esta capa.

### `Specifications/` — soporte de specs (Implementado)
- `BaseSpecification<T> : ISpecification<T>` — clase base abstracta. Las specs concretas fijan `Criteria` en su constructor y usan los helpers protegidos `AddInclude`, `ApplyOrderBy`, `ApplyOrderByDescending`, `ApplyPaging(skip, take)`.

## Convenciones de codigo observadas
- Un tipo publico por archivo; nombre de archivo = nombre del tipo; namespace = `IdleRPG.Domain.<Carpeta>` (file-scoped namespaces).
- Entities = clases POCO mutables con navegacion nullable; ValueObjects = `record`/`readonly record struct` inmutables.
- XML doc comments `/// <summary>` en tipos y miembros no triviales (mantener este estilo al agregar).
- Enums con valores numericos explicitos (nunca implicitos, porque se persisten/serializan).
- Datos de balance/tablas como `static class` con un `IReadOnlyDictionary` privado y metodos de acceso publicos (ver `ItemRarityData`, `BotEventTypeData`, `ClassBaseStats`).
- Claves de stat = `nameof(...)` de propiedades de `CharacterStats`; no usar literales sueltos.

## Build / Test (para esta capa)
Desde la raiz del repo (`Makefile` y comandos):
- `make build` — build de toda la solucion.
- `make test-all` — debe pasar siempre antes de commitear (`feat: phase-N complete`).
- Build aislado de la capa: `dotnet build services/api/IdleRPG.Domain/IdleRPG.Domain.csproj`.
- Tests del dominio (proyecto `IdleRPG.Tests`, carpeta `Domain/`, p.ej. `SteamIdTests`, `RarityTests`, `RiskScoreTests`): `dotnet test services/api/IdleRPG.sln`. Los tests usan traits xUnit: filtrar por fase con `dotnet test --filter "Phase=F1"` o por categoria con `--filter "Category=ItemEngine"`.
- Este proyecto NO tiene migraciones; `make db-migrate`/`db-reset` operan sobre `Infrastructure`/`API`.

## Pendiente / Planificado (no esta aqui todavia)
El plan menciona piezas que NO viven (aun) en Domain o que dependen de fases posteriores:
- **F4 (Combat/Idle engine)** — **Implementado** en `Combat/` (`CombatEngine` por turnos estilo HSR con action value/skill points/energía/toughness break, `IdleSimulator`, `IdleState`, `CombatFormulas`, specs `HeroSpec`/`EnemySpec`) y `GameData/` (`ClassKits`, `EnemyCatalog`, `XpCurve`). `CharacterStats` incorpora `Speed` y `BreakEffect`; enums nuevos `DamageType` y `EnemyArchetype`.
- **F6 (Anti-bot)** — Implementado SOLO el modelo: `AntiBotEvent`, `BotEventType`/`BotEventTypeData`, `AntiBotRiskLevel`, `RiskScore`. El scoring en Redis, decay (-1 cada 6h, TTL 24h) y enforcement son Planificados (fuera de Domain).
- **F5 (Steam)** — esqueleto/stub en `Infrastructure`; en Domain solo viven `SteamId`, `Item.SteamMarketHashName`/`IsTradeable`, `ItemInstance.SteamInventoryId`/`LastSteamValidation`.
- Marcar siempre como "Implementado" vs "Planificado (Fase Fx)" cualquier referencia a estas areas al editar codigo o docs aqui.
