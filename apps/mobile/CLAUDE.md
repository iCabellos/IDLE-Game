# CLAUDE.md — apps/mobile (Flutter client)

Cliente **Flutter** del monorepo IDLE-Game (Idle RPG + Steam Market). Soporta web, iOS y desktop; Android aun pendiente. Estado global: **preview temprana de la Fase F7** — UI navegable con datos mock, sin capa de datos real, sin DI, sin BLoCs y sin websocket todavia.

Ver tambien: `/CLAUDE.md` (indice raiz del monorepo y plan maestro).

---

## Proposito

App de progresion idle cuyos items son items del inventario Steam. Esta carpeta contiene SOLO la presentacion (Flutter). El backend (`services/api`, .NET) posee la logica de negocio, validacion de ownership y calculo de stats. El cliente **nunca** recalcula combate ni muestra numeros crudos.

Package Dart: `idle_rpg` (ver `pubspec.yaml`, `name: idle_rpg`). Bundle id iOS: `com.icabellos.idlerpg`.

---

## Estado actual: Implementado vs Planificado

### Implementado (preview F7)
- **Tema dark** (`AppTheme.dark`, Material 3) y design tokens `AppColors` / `RarityColors`.
- **Routing** con `go_router`: `appRouter` en `lib/core/router/app_router.dart`. Rutas: `/login` (fuera del shell) y `ShellRoute` con `/dashboard`, `/inventory`, `/widget`.
- **Shell** con `NavigationBar` de 3 tabs (`AppShell`).
- **Pantallas**: `LoginScreen`, `DashboardScreen`, `InventoryScreen`, `WidgetPreviewScreen` (mockup del widget Android F8).
- **Modelos cliente**: enum `CharacterStatus` (+ extension) y `InventoryItem` (+ `mockInventory`).
- **Tests**: `test/app_theme_test.dart` (tokens y `RarityColors.forRarity`) y `test/widget_test.dart` (boot a login).
- Plataformas presentes: `web/` e `ios/`.

### Planificado (NO implementado todavia — no lo asumas presente)
- **DI con get_it + injectable**: dependencias declaradas en `pubspec.yaml` pero **no hay wiring**. `main.dart` lo dice explicito: "Full DI wiring lands in Phase F7". No existen `@injectable`, `injection.dart` ni `*.config.dart`.
- **BLoC / Cubit**: `flutter_bloc` y `bloc_test` declarados, pero **no hay ningun Bloc/Cubit**. Las pantallas usan `StatefulWidget` con `setState` y datos mock (ej. el boton refresh del dashboard cicla `CharacterStatus`, el login hace un `Future.delayed` y navega).
- **Repos Dio / capa de red**: `dio` declarado, sin cliente ni repos. Endpoints referenciados solo en comentarios (`/items/inventory`, ver `IdleRPG.Application.UseCases.Items.GetInventory`).
- **DTOs freezed**: `freezed` / `json_serializable` declarados, **sin** archivos `*.freezed.dart` / `*.g.dart` generados (estan excluidos en `analysis_options.yaml`). Los modelos actuales (`InventoryItem`) son clases planas a mano.
- **WebSocket / SignalR** (push de estado idle en vivo): no existe; el plan lo situa en F7.
- **Auth Steam OpenID real**: el `LoginScreen` es un stub que navega tras un delay. Integracion real en F5/F7.
- **Equipment / Team / Meta**: pantallas no creadas (Fases F7/F9).
- **Almacenamiento local**: `hive_flutter` y `flutter_secure_storage` declarados, sin uso aun.
- **Android (`android/`)**: la carpeta NO existe. Solo hay `ios/` y `web/`. El widget nativo Home Screen (Jetpack Glance) es F8 y vive fuera de aqui; `WidgetPreviewScreen` es solo una maqueta visual en Flutter.

---

## Stack y versiones (lo que REALMENTE declara `pubspec.yaml`)

> Aviso importante: las versiones reales del repo **divergen** del "plan maestro" canonico. Respeta el `pubspec.yaml`/`pubspec.lock` del repo, no las del plan, al editar codigo. Diferencias observadas:

| Dependencia | `pubspec.yaml` real | Plan maestro |
|---|---|---|
| `flutter_bloc` | `^9.1.1` | 8.1.6 |
| `go_router` | `^17.3.0` | 14.x |
| `get_it` | `^9.2.1` | (get_it) |
| `injectable` | `^3.0.0` | (injectable) |
| `freezed` | `^3.2.5` | freezed |
| `dio` | `^5.4.0` | 5.x (coincide) |
| `hive_flutter` | `^1.1.0` | 1.1 (coincide) |
| `flutter_animate` | `^4.5.0` | 4.5 (coincide) |

SDK: Dart `>=3.4.0 <4.0.0`, Flutter `>=3.22.0`. Otras: `flutter_secure_storage ^10.3.1`, `json_annotation`, `cached_network_image`, `cupertino_icons`. Dev: `flutter_lints ^6.0.0`, `build_runner`, `bloc_test ^10`, `mocktail ^1.0.3`.

Inconsistencia de CI: `.github/workflows/ci.yml` (job `test-flutter`) usa Flutter `3.22.0`, mientras `ios-build.yml` usa `3.44.2`. Tenlo en cuenta si algo compila en local pero falla en un workflow.

---

## Mapa de archivos clave

```
lib/
  main.dart                         # IdleRpgApp: MaterialApp.router, tema dark, appRouter
  core/
    theme/app_theme.dart            # AppColors, RarityColors, AppTheme.dark
    router/app_router.dart          # appRouter (go_router): /login + ShellRoute
    models/
      character_status.dart         # enum CharacterStatus + extension (label/description/color/icon)
      inventory_item.dart           # InventoryItem + mockInventory
  features/
    auth/login_screen.dart          # LoginScreen (stub Steam)
    dashboard/
      dashboard_screen.dart         # DashboardScreen + tarjetas internas (StatefulWidget/setState)
      widgets/character_status_card.dart
    inventory/
      inventory_screen.dart         # GridView sobre mockInventory + filtro por slot
      widgets/item_card.dart        # ItemCard: borde/glow por rareza
    shell/app_shell.dart            # AppShell: NavigationBar de 3 tabs
    widget_preview/widget_preview_screen.dart  # maqueta del widget Android F8
test/
  app_theme_test.dart
  widget_test.dart
ios/    web/                        # plataformas presentes (android/ ausente)
pubspec.yaml  analysis_options.yaml
```

Convencion de carpetas: `core/` (transversal: theme, router, models) + `features/<feature>/` con `widgets/` por feature. Al crecer F7, cada feature debera incorporar su `bloc/` (Bloc/Cubit + states/events) y su `data/` (repo + DTOs freezed). Mantener este patron.

---

## REGLA UX CRITICA: nunca mostrar numeros crudos

**Prohibido** renderizar stats numericos (HP, ataque, defensa, %crit, resistencias, multiplicadores) en la UI. Solo se muestran **estados legibles** del enum `CharacterStatus` (`lib/core/models/character_status.dart`):

`Winning` · `Danger` · `Stuck` · `Rewards Ready` · `Steam Desynced`

- Usa `status.label`, `status.description`, `status.color`, `status.icon` — todo ya mapeado en la extension `CharacterStatusX`. No inventes labels ni colores nuevos.
- Comparacion de items = **texto descriptivo**, nunca numeros. Ejemplos ya presentes: el dashboard muestra "Time away: 6h 42m", "Enemies defeated: Dozens", "Loot found: 3 items"; el set bonus se describe como "Unbreakable — immune to one-shot defeats".
- `ItemCard` codifica la rareza con color de borde/glow (no con numeros). Solo nombre + nombre de rareza + set opcional.

Cualquier PR que filtre numeros crudos a la vista es incorrecto por diseno.

---

## Design tokens y colores de rareza

`AppColors` (en `app_theme.dart`) — usar SIEMPRE estos, no `Color(0x...)` sueltos:
`navy 0xFF0F2740`, `blue 0xFF1A56A0` (primary), `accent 0xFF0EA5E9` (secondary), `success 0xFF059669`, `danger 0xFFDC2626`, `amber 0xFFD97706`, `surface 0xFF1E2D3D`, `bg 0xFF0F1B2A`, `text 0xFFF1F5F9`, `muted 0xFF94A3B8`.

`RarityColors.forRarity(int rarityTier)` resuelve color por el valor **1-based** del enum backend `ItemRarity`:
- 1 broken, 2 worn, 3 common, 4 uncommon, 5 rare, 6 superior, 7 epic, 8 mythic, 9 ancient, 10 relic.
- **11 y superior** caen todos en `legendary` (glow dorado). Es una simplificacion del cliente: el backend define 21 niveles (Legendary..Transcendent + Unique/Seasonal/Founder/EventLimited/OneOfOne). La UI aun no diferencia tiers >11 ni anade particulas (el plan pide particulas para Legendary+; pendiente).
- `ItemCard` aplica `boxShadow`/borde mas grueso cuando `rarityTier >= 11`.

Contrato con el backend: `InventoryItem.rarityTier` debe seguir mapeando 1:1 al `ItemRarity` (1-based) del Domain .NET. Los slots usados como `String` ('Head','Chest','Legs','Feet','Hands','Ring','Amulet','MainHand','OffHand','Relic1', etc.) reflejan el enum `ItemSlot` (Head=1..Relic2=12).

---

## Comandos (ejecutar dentro de `apps/mobile/`)

```bash
flutter pub get          # instalar dependencias
flutter run -d chrome    # ejecutar en web (plataforma soportada hoy)
flutter analyze          # lint (analysis_options.yaml + flutter_lints)
flutter test             # tests de widgets/unidad
```

Cuando se generen DTOs freezed (F7): `dart run build_runner build --delete-conflicting-outputs`.

Desde la raiz del monorepo: `make test-flutter` (o `make test-all`, que tambien corre los tests .NET; salta Flutter si el SDK no esta instalado). Las migraciones de DB y el stack Docker viven en `services/api` / `infra` — no aplican aqui.

iOS / AltStore: `ios-build.yml` compila un IPA sin firmar en `push` a `main`/rama de dev cuando cambia `apps/mobile/**`, publica el artifact y actualiza el release `ios-latest`. `/altstore.json` (raiz) es el source de AltStore PAL que apunta a ese release (`IdleRPG.ipa`, version 0.1.0). Si subes la version, actualiza `pubspec.yaml` (`version:`) y la entrada `versions` de `altstore.json`.

---

## Lint y convenciones de codigo

`analysis_options.yaml` extiende `package:flutter_lints/flutter.yaml` y fuerza:
- `prefer_const_constructors: true`
- `prefer_final_locals: true`

Convenciones observadas en el codigo:
- `const` agresivo en widgets; locals con `final`.
- Widgets privados con prefijo `_` dentro del archivo de la pantalla (ej. `_HeroHeader`, `_IdleSessionCard`, `_Widget2x1`).
- Animaciones con `flutter_animate` encadenadas (`.animate().fadeIn(...).slideY(...)`); duraciones con la extension `.ms`.
- Color con alpha via `color.withValues(alpha: ...)` (API nueva; NO usar `withOpacity`, deprecada).
- Navegacion con `context.go(path)` (go_router), no `Navigator.push`.
- `switch` expression (Dart 3) para mapeos (status -> label/color/icon, slot -> icono).
- `*.g.dart` y `*.freezed.dart` excluidos del analyzer; no editarlos a mano.

---

## Gotchas

- **No hay capa de datos**: todo es mock (`mockInventory`, estados ciclados con `setState`). No asumas que existe un repo/cliente HTTP; al cablear F7 crea la capa nueva, no "arregles" una inexistente.
- **No hay DI ni Bloc todavia** pese a estar en `pubspec.yaml`. Si introduces el primer Bloc/inyeccion, monta el wiring (get_it/injectable) y registra `bloc_test`/`mocktail` en los tests.
- **Android ausente**: `flutter run`/builds de Android fallaran hasta que se genere la carpeta `android/`. Usa `-d chrome` o iOS para previsualizar.
- **`apps/widget` no existe**: el comentario en `widget_preview_screen.dart` referencia un futuro `apps/widget` (Glance, F8). Hoy solo hay `apps/desktop` (con un README) y este `apps/mobile`. No enlaces a rutas inexistentes.
- **rarityTier >11**: la UI colapsa todos los tiers altos en "legendary"; si el backend envia Unique/Seasonal/etc. el cliente no los distingue aun. No es bug a "corregir" sin alinear el plan.
- **Versiones**: confia en `pubspec.lock`, no en las versiones del plan maestro (divergen). Antes de subir un major, valida `flutter analyze` y `flutter test`.
- **Desfase de Flutter en CI** (3.22.0 vs 3.44.2): si un cambio depende de APIs nuevas, puede romper el job `test-flutter`.
