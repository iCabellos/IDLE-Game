# CLAUDE.md — infra/docker

Ver tambien: [/CLAUDE.md](/CLAUDE.md) (contexto raiz del monorepo, fases, stack y reglas de oro).

## Proposito del directorio

Definicion del entorno local del stack IdleRPG via Docker Compose. Es la pieza central de **F0 (Monorepo + Fundamentos)** y la dependencia de runtime para F1+ (la API necesita Postgres y Redis arriba para migraciones, auth y cache).

**Estado: Implementado (F0).** Este directorio contiene un unico archivo:

| Archivo | Estado | Contenido |
|---------|--------|-----------|
| `docker-compose.yml` | Implementado | 4 servicios: `postgres`, `redis`, `api`, `pgadmin`; red `idlerpg-net`; 4 volumenes nombrados. |

> No hay `Dockerfile` aqui. El servicio `api` se construye desde `services/api/IdleRPG.API/Dockerfile` (multi-stage, ver abajo). El `.dockerignore` vive en `services/api/.dockerignore`.

## Mapa de archivos relacionados (fuera de este dir pero acoplados)

- `services/api/IdleRPG.API/Dockerfile` — build de la imagen `api` (lo referencia el compose).
- `services/api/.dockerignore` — excluye `**/bin/`, `**/obj/`, `**/.vs/`, `**/*.user`, `logs/`.
- `/.env.example` — plantilla de variables; copiar a `/.env.local`.
- `/Makefile` — `make dev` y demas targets envuelven este compose (`COMPOSE := docker compose -f infra/docker/docker-compose.yml`).
- `services/api/IdleRPG.API/Program.cs` — define `/health`, `/swagger`, `/hangfire` y el flag `SEED_AND_EXIT`.

## Servicios (lo que REALMENTE hay)

Project name del compose: `name: idlerpg`. Todos los servicios cuelgan de la red `idlerpg-net` (bridge).

### postgres
- Imagen: `postgres:16` — container `idlerpg-postgres`.
- Credenciales hardcoded (solo dev): `POSTGRES_USER=idlerpg`, `POSTGRES_PASSWORD=secret`, `POSTGRES_DB=idlerpg`.
- Puerto: `5432:5432`. Volumen: `idlerpg-postgres-data:/var/lib/postgresql/data`.
- Healthcheck: `pg_isready -U idlerpg -d idlerpg` (interval 10s, timeout 5s, retries 5, start_period 10s).

### redis
- Imagen: `redis:7` — container `idlerpg-redis`.
- Command: `redis-server --appendonly yes` (persistencia AOF activada).
- Puerto: `6379:6379`. Volumen: `idlerpg-redis-data:/data`.
- Healthcheck: `redis-cli ping` (interval 10s, retries 5, start_period 5s).

> Nota de version: el plan canonico fija **Redis 7.2**; el compose usa el tag flotante `redis:7`. La libreria cliente sigue siendo `StackExchange.Redis`. Si se necesita el pin exacto, cambiar a `redis:7.2`.

### api
- Build: `context: ../../services/api`, `dockerfile: IdleRPG.API/Dockerfile` — container `idlerpg-api`.
- `depends_on` con `condition: service_healthy` sobre `postgres` y `redis` (no arranca hasta que ambos esten healthy).
- Env del contenedor:
  - `ASPNETCORE_ENVIRONMENT=Development`, `ASPNETCORE_URLS=http://+:5000`.
  - `POSTGRES_URL=postgresql://idlerpg:secret@postgres:5432/idlerpg` (host = nombre de servicio `postgres`).
  - `REDIS_URL=redis://redis:6379` (host = nombre de servicio `redis`).
  - `JWT_SECRET`/`JWT_ISSUER`/`JWT_AUDIENCE` y `HANGFIRE_DASHBOARD_USER`/`HANGFIRE_DASHBOARD_PASS` con defaults via `${VAR:-default}` (el secret por defecto es de juguete: `dev-only-secret-key-change-me-min-32-chars`).
- Puerto: `5000:5000`. Volumen: `idlerpg-api-logs:/app/logs` (sink de Serilog).
- Healthcheck: `curl -f http://localhost:5000/health || exit 1` (interval 15s, retries 5, **start_period 30s** para dar margen a migraciones + arranque .NET).

### pgadmin
- Imagen: `dpage/pgadmin4` (tag flotante) — container `idlerpg-pgadmin`. Util de dev, no es parte del runtime de produccion.
- `depends_on: postgres (service_healthy)`.
- Env: `PGADMIN_DEFAULT_EMAIL=admin@idlerpg.local`, `PGADMIN_DEFAULT_PASSWORD=admin`, `PGADMIN_CONFIG_SERVER_MODE=False` (desktop mode, sin login multiusuario).
- Puerto: `5050:80`. Volumen: `idlerpg-pgadmin-data:/var/lib/pgadmin`.
- Healthcheck: `wget -qO- http://localhost:80/misc/ping || exit 1`.

## Puertos expuestos (host)

| Servicio | Host:Container | URL local |
|----------|----------------|-----------|
| postgres | 5432:5432 | `postgresql://idlerpg:secret@localhost:5432/idlerpg` |
| redis | 6379:6379 | `redis://localhost:6379` |
| api | 5000:5000 | `http://localhost:5000` (`/health`, `/swagger`, `/hangfire`) |
| pgadmin | 5050:80 | `http://localhost:5050` |

## Dockerfile de la API (resumen — vive en services/api/IdleRPG.API/Dockerfile)

Multi-stage, respeta la regla de dependencias de Clean Architecture al copiar `.csproj` en orden Domain → Application → Infrastructure → API → Tests:
- **build**: `mcr.microsoft.com/dotnet/sdk:8.0`, `WORKDIR /src`. Copia `.sln` + `.csproj` primero, `dotnet restore IdleRPG.API/...`, luego copia todo y `dotnet publish IdleRPG.API -c Release -o /app/publish /p:UseAppHost=false`.
- **runtime**: `mcr.microsoft.com/dotnet/aspnet:8.0`, `WORKDIR /app`. Crea `/app/logs`, `EXPOSE 5000`, `ENV ASPNETCORE_URLS=http://+:5000`, `ENTRYPOINT ["dotnet", "IdleRPG.API.dll"]`.

Importante: el `context` es `services/api` (raiz de la solucion), no la carpeta del proyecto API. Los paths del Dockerfile (`COPY IdleRPG.sln`, `COPY IdleRPG.Domain/...`) son relativos a ese context.

## Como levantar el stack

```bash
# 1. Variables de entorno (desde la raiz del repo)
cp .env.example .env.local   # editar valores reales (Steam keys, JWT_SECRET >=32 chars, ...)

# 2. Levantar todo
make dev
#   == docker compose -f infra/docker/docker-compose.yml up --build -d  +  docker compose ps

# o directamente, sin make:
docker compose -f infra/docker/docker-compose.yml up --build

# 3. Verificar salud
curl http://localhost:5000/health     # -> {"status":"healthy"}
open  http://localhost:5000/swagger    # solo en Development

# 4. Parar / limpiar
make down    # docker compose ... down
make clean   # dotnet clean + docker compose down -v (BORRA volumenes) + limpia bin/obj
```

## Criterio de aceptacion F0 (lo que debe cumplirse)

- `docker compose up --build` deja el stack **healthy en < 2 min**.
- `GET http://localhost:5000/health` responde **200** con body `{"status":"healthy"}` (lo escribe `MapHealthChecks` en `Program.cs`).
- `http://localhost:5000/swagger` carga la UI (Swagger solo se monta cuando `ASPNETCORE_ENVIRONMENT=Development`, que es el valor en el compose).

## Relacion con make dev y .env

- `make dev`, `make down`, `make clean` y `make db-reset` usan este compose via la variable `COMPOSE` del Makefile raiz. No invoques `docker compose` con otro `-f`; usa siempre `infra/docker/docker-compose.yml`.
- Las variables `${JWT_SECRET}`, `${JWT_ISSUER}`, `${JWT_AUDIENCE}`, `${HANGFIRE_DASHBOARD_USER}`, `${HANGFIRE_DASHBOARD_PASS}` se interpolan desde el entorno / archivo `.env`. Docker Compose lee por defecto `infra/docker/.env`, **no** `/.env.local`. Hoy el repo solo trae `/.env.example`; las variables tienen defaults `:-` en el compose, asi que el stack arranca sin `.env`, pero con secretos de juguete. Si necesitas valores reales, exporta las vars en tu shell antes de `make dev` o ajusta de donde lee Compose.
- `POSTGRES_URL`/`REDIS_URL` del contenedor `api` apuntan a los **nombres de servicio** (`postgres`, `redis`), no a `localhost`. El `.env.example` usa `localhost` porque esta pensado para correr la API **fuera** de Docker (p. ej. `dotnet run` contra los contenedores de infra). No mezcles ambos.

## Migraciones y seed (no se hacen desde el compose)

- Al arrancar en `Development`, `Program.cs` ejecuta `db.Database.MigrateAsync()` + `DbSeeder.SeedAsync(...)` automaticamente. No hay servicio "migrator" separado en el compose.
- Para migraciones/seed manuales usa el Makefile raiz (requieren `dotnet-ef` y la API local, no el contenedor):
  - `make db-migrate` — `dotnet ef database update --project IdleRPG.Infrastructure --startup-project IdleRPG.API`.
  - `make db-reset` — drop + migrate + seed.
  - `make db-seed` — corre la API con `SEED_AND_EXIT=true` (migra, siembra y sale; ver `Program.cs`).

## Gotchas / errores comunes

- **Conflicto de puertos**: 5432, 6379, 5000 y 5050 deben estar libres en el host. Otra instancia de Postgres/Redis local rompe el `up`.
- **`api` no levanta hasta que Postgres/Redis esten healthy**: si `api` queda en estado "Created"/esperando, revisa primero los healthchecks de las dependencias (`docker compose ps`, `docker compose logs postgres`).
- **start_period del api (30s)**: durante los primeros ~30s `/health` puede dar fallo transitorio mientras aplica migraciones; no lo interpretes como caido hasta agotar retries.
- **`make clean` y `down -v` borran datos**: eliminan los volumenes nombrados (incluido `idlerpg-postgres-data`). Para conservar datos usa `make down` (sin `-v`).
- **Tags flotantes**: `redis:7`, `dpage/pgadmin4` y los `dotnet:8.0` no estan pineados a digest. Builds reproducibles pueden requerir pins explicitos.
- **Secretos por defecto**: `JWT_SECRET` default y `POSTGRES_PASSWORD=secret`/pgadmin `admin` son SOLO para dev local. Nunca promover este compose tal cual a Staging/Production.
- **Cache de build de la API**: si cambias solo codigo (no `.csproj`), el layer de `restore` se reutiliza; si tocas dependencias, fuerza `--build` (lo hace `make dev`).

## Que NO existe aun aqui (Planificado)

- No hay overrides por entorno (`docker-compose.override.yml`, `docker-compose.prod.yml`).
- No hay servicios para `worker` (Hangfire dedicado), `steam-bridge` ni Flutter — F4/F5/F7/F8 todavia no los necesitan en este compose. La API hospeda Hangfire in-process (`/hangfire`) por ahora.
- No hay `.env` en `infra/docker/`; la gestion de variables reales esta pendiente de formalizar (hoy depende de defaults `:-`).
