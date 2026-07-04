# IDLE RPG + Steam Market — CLAUDE.md (raíz del monorepo)

Idle RPG con integración Steam. El inventario del juego **son** items del inventario de Steam del jugador (validados contra Steam y comerciables en el Steam Market). El combate y la progresión son *idle*: avanzan solos (online y offline) y el jugador gestiona equipo/equipo de personajes.

Este archivo es el contexto general para cualquier agente que trabaje en el repo. Cada subsistema tiene además su propio `CLAUDE.md` con el detalle local (ver índice abajo).

> **Documento canónico de diseño:** *Idle RPG + Steam Market — Implementation Plan v2.0 (Claude Code Edition)* (11 fases F0–F9 + QA/Release). Define enums, contratos de API, fórmulas y estructura **exactos**. Cuando el código y este doc difieran, manda lo que está en el código (este CLAUDE.md anota las divergencias reales).

## Índice de CLAUDE.md por directorio

| Directorio | Qué cubre |
|---|---|
| `/CLAUDE.md` (este) | Visión global, stack, arquitectura, estado por fase, reglas transversales, comandos, CI/CD. |
| `services/api/CLAUDE.md` | Solución .NET (`IdleRPG.sln`): Clean Architecture, regla de dependencias, build/test, migraciones EF, connection strings. |
| `services/api/IdleRPG.Domain/CLAUDE.md` | Capa Domain: entidades, enums canónicos, value objects, GameData, interfaces. Sin dependencias externas. |
| `services/api/IdleRPG.Application/CLAUDE.md` | Capa Application: CQRS/MediatR, DTOs, validators, behaviors, interfaces de servicios. |
| `services/api/IdleRPG.Infrastructure/CLAUDE.md` | Capa Infrastructure: EF Core/persistencia, migraciones, seed, Redis, auth Steam/JWT, motor de items. |
| `services/api/IdleRPG.API/CLAUDE.md` | Host ASP.NET Core: `Program.cs`, endpoints minimal-API, middleware, errores, rate limiting. |
| `services/api/IdleRPG.Tests/CLAUDE.md` | xUnit + Testcontainers: estructura, traits/categorías, cobertura mínima por fase. |
| `apps/mobile/CLAUDE.md` | App Flutter (BLoC + go_router): design tokens, regla "sin números crudos", estado del preview F7. |
| `infra/docker/CLAUDE.md` | Docker Compose: postgres/redis/api/pgadmin, healthchecks, cómo levantar el stack. |

## Estructura del monorepo

```
idle-rpg/  (repo: github.com/iCabellos/IDLE-Game)
├── apps/
│   ├── mobile/          # Flutter (Android + iOS + web + desktop) — cliente
│   ├── desktop/         # Flutter Desktop (placeholder)
│   └── widget/          # Android home-screen widget (Kotlin + Glance) — F8, pendiente
├── services/
│   ├── api/             # .NET 8 — Clean Architecture (Domain/Application/Infrastructure/API + Tests)
│   ├── worker/          # Hangfire background jobs — F4, solo README
│   └── steam-bridge/    # wrapper Steamworks — F5, solo README
├── packages/shared/     # DTOs compartidos (placeholder)
├── infra/docker/        # docker-compose.yml (postgres, redis, api, pgadmin)
├── docs/
├── Makefile             # dev | test-all | build | db-migrate | db-reset | db-seed | clean
├── .env.example         # plantilla de variables (copiar a .env.local)
└── .github/workflows/   # ci.yml + ios-build.yml
```

## Stack — versiones

El plan maestro fija versiones "exactas", pero **el repo ya usa versiones más nuevas** en varios paquetes. Usa lo que hay instalado (no degrades a las del PDF):

| Capa | Tecnología | PDF dice | Repo real |
|---|---|---|---|
| Frontend | Flutter SDK | 3.22+ | `>=3.22.0` (CI usa 3.22.0; el workflow iOS usa 3.44.2) |
| State | flutter_bloc | 8.1.6 | **^9.1.1** |
| Router | go_router | 14.x | **^17.3.0** |
| HTTP | dio | 5.x | ^5.4.0 |
| Cache local | hive_flutter | 1.1 | ^1.1.0 (+ flutter_secure_storage ^10) |
| DI | get_it / injectable | 7.7 / 2.4 | **^9.2 / ^3.0** |
| Codegen | freezed | — | **^3.2.5** (API distinta de freezed 2.x) |
| Backend | .NET | 8.0 LTS | net8.0 ✔ |
| ORM | EF Core | 8.x | 8.x ✔ |
| Mediator / Validation | MediatR / FluentValidation | 12 / 11 | ✔ |
| Jobs | Hangfire | 1.8.x | 1.8.x (PostgreSQL storage) ✔ |
| DB / Cache | PostgreSQL 16 / Redis 7.2 | ✔ | ✔ |
| Logging | Serilog | 4.x | ✔ |

## Arquitectura

- **Backend** — Clean Architecture estricta: `Domain ← Application ← Infrastructure ← API`. CQRS con MediatR (Command/Query + Handler + Validator); validación vía `ValidationBehavior` en el pipeline. `Domain` sin dependencias externas; abstracciones como interfaces, implementaciones en `Infrastructure`. Detalle en `services/api/CLAUDE.md`.
- **Frontend** — Flutter con **BLoC obligatorio** + `go_router`, dark mode, design tokens en `AppColors`. Detalle en `apps/mobile/CLAUDE.md`.

## Estado por fase (real, según código + git)

> ⚠️ La tabla de fases del `README.md` está **desactualizada** (marca F1–F3 como ⏳). El estado real, según el historial git y el código:

| Fase | Nombre | Estado real |
|---|---|---|
| F0 | Monorepo + Infra | ✅ Implementado |
| F1 | Domain + Auth Steam (JWT) | ✅ Implementado |
| F2 | Database Schema + Migrations + Seed | ✅ Implementado |
| F3 | Motor de Items | ✅ Implementado |
| F4 | Combate + Idle Engine | ✅ Implementado (motor por turnos estilo HSR: action value/Speed, skill points compartidos, ultimates por energía, toughness/weakness break; `IdleSimulator` + `IdleTickJob` + endpoints `/combat/*`) |
| F5 | Steam Integration | 🟡 Esqueleto (`SteamInventoryService` stub; vars `STEAM_*`) |
| F6 | Anti-Bot System | 🟡 Solo entidad `AntiBotEvent` + enums + `RiskScore` (sin engine/middleware) |
| F7 | Flutter App | 🟡 Preview temprana (login, dashboard, inventory, widget mock) |
| F8 | Android Widget | ❌ No implementado (falta `apps/widget/` real y carpeta `android/`) |
| F9 | Meta-Progresión | ❌ No implementado |

Antes de tocar una fase, **no asumas** que existe lo de fases posteriores; verifica en el código.

## Reglas de oro del flujo de trabajo

1. **Nunca saltar fases.** Cada fase asume la anterior commiteada y con tests verdes.
2. `make test-all` debe pasar antes de avanzar. Un test roto = no se avanza de fase.
3. Commits por fase: `feat: phase-N complete`.
4. **Zero-ambiguity**: enums, firmas y contratos están definidos en el plan/código; no inventes variantes ni versiones.

## Reglas transversales (aplican a todo el codebase)

- **Enums canónicos**: definidos **una sola vez** en `IdleRPG.Domain/Enums` y usados en todo el código: `CharacterClass` (10), `CharacterRole` (5), `ItemSlot` (12), `ItemClass` (4), `ItemRarity` (**21 niveles**, Broken→OneOfOne; `Unique`+ con stats FIXED y no tradeable), `AccountStatus`, `AntiBotRiskLevel`, `BotEventType`. No los redefinas en otras capas.
- **UX — NUNCA mostrar números crudos de stats al usuario.** Solo estados legibles: **Winning / Danger / Stuck / Rewards Ready / Steam Desynced**. La comparación de items devuelve **texto descriptivo** (p. ej. "Más defensa", "Mejor para críticos"), no cifras. Aplica tanto al endpoint `/items/compare` como a toda la UI Flutter.
- **Caps de stats** (en `StatAggregator`): `CritRate ≤ 0.75`, `CritMultiplier ≤ 5.0`, resistencias `≤ 0.90`.
- **Stat rolling** (`ItemFactory`): Box-Muller, varianza ±15% clamp `[0.85, 1.15]`, `baseStat × rarityMult × roll`. Passive slots por rareza (0→5). Rarezas FIXED se copian sin rollear.
- **Persistencia**: snake_case automático en `AppDbContext`, soft delete global (`DeletedAt == null`), `created_at`/`updated_at`, índices únicos `users.steam_id` e `item_instances.steam_inventory_id`.
- **Esquema de Redis keys** (se establece en F4; usar exactamente): `idle:state:{userId}`, `idle:session:{userId}`, `stats:{characterId}` (TTL 1h, invalidar al equipar), `steam:owns:{steamId}:{itemId}`, `antibot:score:{userId}`, `ratelimit:{ip}`, `steam:inventory:{steamId}`, `desynced:{userId}:{itemId}`.
- **Combate / offline** (F4, implementado en `IdleRPG.Domain/Combat`): `EffectiveResistance = clamp(resist − pen, 0, 0.90)`; `FinalDamage = base × (crit ? critMult : 1) × (1 − effResist)`; `OfflineEfficiency` = 1.0 hasta 36h, luego −5%/día, mínimo 1%. 1 tick = 1s = 10 AV; `IdleTickJob` (Hangfire, cron minutely) avanza el estado de cada usuario; benchmark 10k ticks < 100ms verificado en tests. Diseño por turnos estilo HSR: timeline por action value (`10000/Speed`), pool de 5 skill points compartidos (básico +1, skill −1), ultimates por energía (coste 100–140 por clase, acción gratuita al cargarse), toughness/weakness break (básico 30 / skill 60 / ult 90; al romper: break damage, retraso de acción y +25% daño recibido) y IA por rol (tank aggro ×4, healer cura <65%, support buffea). Enemigos en `EnemyCatalog` (zonas de 10 waves, boss en la 10) con ataque superlineal (presión `1+L/150`, cap ×4) para que existan muros de progresión. **Loot ARPG estilo Diablo/PoE** (`Domain/Loot` + `ItemArchetype` + `ArchetypeCatalog`): cada drop se genera con rareza (tabla canónica + Luck), **arquetipo temático** (8: Juggernaut/Executioner/Stormcaller/Plaguebringer/Oracle/Windrunner/Breaker/Fortunate, cada uno con pool de afijos coherente y clases favorecidas), smart loot 70/30 hacia el equipo, afijos por banda de rareza (`PassiveSlots+1`, cap 3 prefijos/3 sufijos, blancos <Uncommon sin afijos) y nombre compuesto ("Savage Blade of Slaughter"). Pendientes en `IdleState.PendingLoot` (cap 100 + overflow) hasta que F5 los materialice como items Steam.
- **Anti-bot** (F6, pendiente): risk score 0–100 en Redis (TTL 24h), decae −1 cada 6h; los umbrales disparan acciones (banner UI, −50% drop, sin market, suspensión, ban). El sistema debe ser invisible para usuarios legítimos; nunca bloquear `/auth`, `/health`, `/swagger`.

## Comandos rápidos (desde la raíz)

```bash
cp .env.example .env.local        # editar valores antes de empezar
make dev                          # docker compose up (postgres, redis, api, pgadmin)
curl http://localhost:5000/health # {"status":"healthy"}
#       http://localhost:5000/swagger
make test-all                     # dotnet test + (flutter test si está instalado)
make db-migrate | db-reset | db-seed
# Flutter (en apps/mobile): flutter pub get | flutter run -d chrome | flutter analyze | flutter test
# Migración EF: dotnet ef migrations add <N> --project IdleRPG.Infrastructure --startup-project IdleRPG.API
```

Detalle de cada comando en `services/api/CLAUDE.md`, `apps/mobile/CLAUDE.md` e `infra/docker/CLAUDE.md`.

## CI/CD y despliegue

- **Rama de trabajo**: `claude/game-implementation-dev-q5wa7d` (es la rama por defecto del remoto; **no existe `main`**). `altstore.json` y parte de los workflows apuntan a esta rama.
- **`.github/workflows/ci.yml`**: `test-api` (dotnet build+test), `test-flutter` (pub get + analyze + test, Flutter 3.22) y `build-docker`. Triggers: push a `main` (inexistente) y PRs → hoy efectivamente corre en PRs.
- **`.github/workflows/ios-build.yml`**: en push a la rama de trabajo/main que toque `apps/mobile/**` (o manual), compila un **IPA iOS sin firmar** en macOS, lo sube como artifact y crea/actualiza el GitHub Release `ios-latest`.
- **Distribución iOS (preview)**: vía **AltStore PAL** (UE). `altstore.json` (bundle `com.icabellos.idlerpg`) es la fuente; el IPA se descarga del release `ios-latest`. Iconos servidos desde la rama **`gh-pages`**.
- **Web/assets**: la rama `gh-pages` aloja assets (iconos) y puede servir el build web del cliente Flutter (`flutter build web`).

## Gotchas frecuentes

- No violar la regla de dependencias del backend (si un `using` apunta "hacia afuera", introduce una interface).
- Migraciones EF **siempre** con `--project IdleRPG.Infrastructure --startup-project IdleRPG.API`.
- Tests de integración requieren **Docker** (Testcontainers de PostgreSQL + Redis).
- Connection strings van en forma URI (`postgresql://…`, `redis://…`); `ConnectionStringHelper` las convierte.
- El dashboard `/hangfire` queda sin protección si faltan `HANGFIRE_DASHBOARD_USER/PASS`.
- Errores comunes y fixes rápidos: ver la sección "Errores Comunes" del plan maestro (Npgsql connection refused → `make dev`; EF table exists → `db drop --force` + migrate; JWT expired → refresh automático del interceptor Dio; etc.).
