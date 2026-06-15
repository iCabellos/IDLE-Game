# Idle RPG + Steam Market

Idle RPG con integración Steam. Monorepo siguiendo el *Implementation Plan v2.0
(Claude Code Edition)*.

## Stack

| Capa        | Tecnología   | Versión   |
|-------------|--------------|-----------|
| Frontend    | Flutter      | 3.22+     |
| State Mgmt  | flutter_bloc | 8.1.6     |
| Backend     | .NET         | 8.0 LTS   |
| ORM         | EF Core      | 8.x       |
| DB          | PostgreSQL   | 16        |
| Cache       | Redis        | 7.2       |
| Jobs        | Hangfire     | 1.8.x     |

## Estructura

```
idle-rpg/
├── apps/
│   ├── mobile/        # Flutter (Android + iOS)
│   ├── desktop/       # Flutter Desktop
│   └── widget/        # Android home-screen widget (Kotlin + Glance)
├── services/
│   ├── api/           # .NET 8 — Clean Architecture
│   ├── worker/        # Hangfire background service
│   └── steam-bridge/  # Steamworks wrapper
├── packages/shared/   # DTOs compartidos
├── infra/docker/      # docker-compose.yml
└── docs/
```

## Quick start

```bash
# 1. Copiar variables de entorno
cp .env.example .env.local   # editar valores

# 2. Levantar el stack (postgres, redis, api, pgadmin)
make dev

# 3. Comprobar salud
curl http://localhost:5000/health      # {"status":"healthy"}
open http://localhost:5000/swagger

# 4. Tests
make test-all
```

## Fases

| Fase | Nombre                      | Estado |
|------|-----------------------------|--------|
| F0   | Monorepo + Fundamentos      | ✅     |
| F1   | Domain Layer + Auth Steam   | ⏳     |
| F2   | Database Schema + Migrations| ⏳     |
| F3   | Motor de Items              | ⏳     |
| F4   | Combate + Idle Engine       | ⏳     |
| F5   | Steam Integration           | ⏳     |
| F6   | Anti-Bot System             | ⏳     |
| F7   | Flutter App                 | ⏳     |
| F8   | Android Widget + Desktop    | ⏳     |
| F9   | Meta-Progresión             | ⏳     |
