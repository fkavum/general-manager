# flutter-core — one shared Dart package for the three Flutter clients, run like dcm-web's upstream

Owner, 2026-09-27: "I have no Flutter knowledge … I only managed to have widget scripts, couldn't have a common
convention across all clients … leaving the how-to to you; you know how I like to work from the backend and Unity
projects (modularization and upstream)." Multi-project: `testapp/client` (Hunter, H), `flash/client` (Flash, F),
`tapit/tapit-client` (Tapit, T), a new package repo. Paths relative to `/Users/fkavum/Documents/project/`.
Facts below were verified in the three clients on 2026-09-27.

## 0. Flutter in ten lines (what this plan relies on)

- A Flutter **app** and a Flutter **package** are the same kind of folder (`pubspec.yaml` + `lib/`); a package just has
  no `main.dart`. `flutter create --template=package dcx_flutter_core` makes one.
- An app uses a package by listing it in `pubspec.yaml`. `path: ../../dcx-flutter-core` means "the folder next door",
  no registry, no publish step, edits are visible immediately. This is the Dart equivalent of a project reference;
  it replaces our byte-copy scripts because the **compiler** reports drift (a renamed class breaks the app build).
- `lib/<name>.dart` files at the top of a package are its public entry points ("barrel" files that `export` what is
  under `lib/src/`). Apps import `package:dcx_flutter_core/api.dart`; they never import `src/`.
- `flutter analyze` is the compiler + linter; `flutter test` runs `test/`; both work for a package alone.
- `--dart-define-from-file=appsettings.<env>.json` bakes values into the build; code reads them with
  `String.fromEnvironment('KEY')`. All three clients already do this.
- Theming: `Theme.of(context).colorScheme` is Material's role-named palette (`primary`, `error`, `surface`…). A
  `ThemeExtension` is an app-defined add-on. Shared widgets that use only `colorScheme` need nothing from the app.
- A `ChangeNotifier` + `ListenableBuilder` is the state mechanism the clients already use; no package needed.
- `pubspec.lock` records a path package's **version** from its pubspec, so bumping the package version shows up
  as a one-line diff in every consumer — the equivalent of `dcm-features.lock.md`.

## 1. State (2026-09-27)

| | H (Hunter) | F (Flash) | T (Tapit) |
|---|---|---|---|
| Dart SDK / Flutter | `^3.10.4` / 3.44.4 | `^3.12.2` / 3.44.4 | `^3.12.2` / 3.44.4 |
| HTTP layer | `services/api_service.dart` 244 l: generic `get/post/put/delete/uploadFile`, `_guard` (10 s timeout → `ServerUnavailableException`), callers throw `ApiException(status, parseError(body), endpoint)` | `services/flash_web_service.dart` 375 l: plumbing + every deck/community call in one class, `utf8.decode(bodyBytes)`, 401 → re-login once | `services/api_service.dart` 218 l: singleton, `_throwIfError` central mapping, `ApiException(message,{statusCode})` |
| `_guard` / `ping` / `→ ← ✖` logging | near-identical text in all three (copy-paste) | | |
| Auth | Firebase sign-in → `POST /login/firebase` → dcm JWT; static `AuthSession` on prefs `dcm_*`; header `auth: Bearer` | `POST /api/login/anonymous {deviceId}` (self-made UUID) → `{token,userId,name}`; prefs `flash_*`; header `auth: Bearer` | own `AuthMultiTenant` (`/api/auth/login-token|pin|login`), JWT in memory only, header `Authorization: Bearer` |
| Startup gate | `BootstrapGate` (70 l): `ping` → `ServerUnavailableScreen(onRetry)` → AuthGate | none (screens push the unavailable screen on failure) | `BootstrapGate` in `main.dart`, near-identical to H's |
| `ServerUnavailableScreen` | same `StatefulWidget` contract ×3 (`onRetry`, `_retrying` guard); bodies differ: `UnreachableState` + `context.tr` / `EmptyState`+`RetryButton` / `OfflineHero`+`BusyFilledButton` | | |
| Common widgets | 41 files | 12 | 14 — overlapping names `EmptyState`, `ErrorState`, `LoadingScreen`, `ConfirmDialog`, `showErrorSnackBar` with **different signatures** |
| Theme | same architecture ×3: `AppColors` + `AppStyles extends ThemeExtension` + `AppText` + `AppTheme.light()` + `context.styles/colors/appText`; every colour value per app; H has dark, F not | | |
| Config | `AppConfig.devTools` (H, T); `API_BASE_URL` **with `/api`** in H, without in F/T; `DEV_TOOLS` string in H JSON, boolean in T | | |
| `tool/run.dart` | functionally identical ×3 (comments differ) | | |
| `Docker/` | `nginx.conf` identical ×3 (minus comments); Dockerfile differs by `APP_ENV` default (prod / docker / local) and T's HEALTHCHECK; compose differs in labels/logging | | |
| `AI_RULES.md` | same 7 headings ×3; H adds l10n + controller rules, T adds `check_theme`, F neither | | |
| `check_theme.sh` | 38 / 47 / 87 lines; T's is the strictest (`// theme-gate: ok` exemptions) | | |
| Tests | 5 logic tests | 9 incl. widget tests | 1 smoke |
| Unused | H declares `provider`, imports it in 0 files | | |

The managers confirm the cost: `client-env-config`, `server-unavailable-page`, `serilog-logging`, `ui-design-system`
were each done three times (hunter-, flash-, tapit-manager `implementation-done/`).

## 2. Decision (proposal)

**One package, `dcx_flutter_core`, living in the Hunter monorepo at `testapp/packages/dcx_flutter_core/` (Hunter is the
upstream, like dcm-web is for the web projects — D1), consumed by `path:` from each client.** It is the client-side twin of dcm-web's upstream, with the same
rules, translated:

```
OWNERSHIP (Flutter, mirrors the web rule)
- Used by exactly one client → that client owns it, plain name, lives only there (lib/screens, lib/services/<domain>, lib/theme values).
- Used by two or more clients → dcx_flutter_core owns it, under lib/src/<module>/, exported by lib/<module>.dart.
- Never copy client → client. A second client needing another client's file means PROMOTE it into the package
  (generalise there, pick the better of the existing implementations), then both import it.
- Ownership test is mechanical: does the class exist in dcx_flutter_core? Yes → import it, improve it upstream first.
  No → client-owned. A client variant of a package widget is a new class named <Name><App> in the client, never a
  patched copy of the package file.
- A package change is verified by `flutter analyze` + `flutter test` in the package AND in every client (check-all.sh).
- Bump `version:` in the package pubspec on any breaking change; the consumer's pubspec.lock diff is the record.
- Shared widgets use Theme.of(context).colorScheme / textTheme only — never an app's ThemeExtension. Colour VALUES
  stay per app. Strings passed in, never hard-coded (the package has no l10n).
- Domain services (decks, products, tasks) stay in the client as thin classes over the package ApiClient —
  like Crossle's Features/User aggregate over Identity.
```

Why a package and not the byte-copy pattern: Dart has a first-class mechanism; copy scripts would give drift
detection after the fact, the package gives a compile error at the moment of the change. Why `path:` and not a git
dependency or submodule: one developer, one checkout, edits in the package are visible in all three apps instantly.

## 3. Package layout and the first modules

```
testapp/packages/dcx_flutter_core/      inside the Hunter monorepo (D1); the layout is the same if it ever moves to its own repo
├── pubspec.yaml                        name: dcx_flutter_core, version: 0.1.0, sdk ^3.12.2, deps: http, shared_preferences
├── AI_RULES.md                         the OWNERSHIP block above + the seven client rule headings (master for clients, see §5)
├── lib/
│   ├── config.dart  api.dart  auth.dart  bootstrap.dart  widgets.dart  theme.dart  storage.dart     ← barrels
│   └── src/
│       ├── config/     AppConfig: apiBaseUrl (API_BASE_URL), devTools (DEV_TOOLS), env (APP_ENV), webPort
│       ├── api/        ApiClient, ApiException, ServerUnavailableException, ErrorBody.parse, JsonBody (utf8), Multipart
│       ├── auth/       DcmAuth (anonymous + provider-token exchange), AuthSession (prefs, app prefix), DeviceId, DcmUser (me)
│       ├── bootstrap/  BootstrapGate, ServerUnavailableScreen (texts injected), ping
│       ├── widgets/    EmptyState, ErrorState, LoadingScreen, LoadingButton, ConfirmDialog, TextPromptDialog, snackbars
│       ├── theme/      DcxThemeContext (context.scheme/text), ThemeExtension template docs — no colours
│       └── storage/    KeyValueStore (shared_preferences with prefix)
├── bin/run.dart                        `dart run dcx_flutter_core:run [env] [device]` — today's tool/run.dart
├── tool/check_theme.sh                 T's strictest version + `// theme-gate: ok`; run against a client path
├── docs/templates/Docker/              Dockerfile, nginx.conf, docker-compose.yml with ${APP_ENV_DEFAULT} etc.
└── test/                               unit tests for api (guard, error parsing, 401 retry), auth (session), config
```

| Module | Base implementation | What it unifies | Adopted by |
|---|---|---|---|
| `config` | H/T `AppConfig` | one `AppConfig` for all keys; `API_BASE_URL` **without** `/api` (D2), `DEV_TOOLS` read as string `"true"`/`"false"` so both JSON styles work | H, F, T |
| `api` | H's generic verbs + F's `utf8.decode(bodyBytes)` + T's central `_throwIfError` + F's 401-retry-once hook | `ApiClient(baseUrl, headers: () async => …, onUnauthorized: …)`; `ApiException(statusCode, message, endpoint)`; `ErrorBody.parse` reads ASP.NET `errors`/`title`, `message`, Dcm.Core `Message`, tapit `error`; `_guard` timeout 10 s | H, F, T |
| `auth` | F's anonymous flow + H's token exchange, on top of the shared dcm-web `Auth`/`Identity` wire (`api/login/anonymous` → `{userId, token, name, status}`; `api/login/refresh`; `GET/PUT api/user/me`, `me/language`, `change_name`) | `DcmAuth(client, session, provider)` with `AnonymousProvider(deviceId)` and `TokenExchangeProvider(path, body)` (H's Firebase path `login/firebase`); `AuthSession(prefix)` on prefs (`flash_`, `dcm_` kept so no user logs out); header name configurable, default `auth` (D4) | F, H — **not T** (own AuthMultiTenant; may adopt later when tapit-web moves to Identity) |
| `bootstrap` | H's `BootstrapGate` + the shared `ServerUnavailableScreen` contract | `BootstrapGate(ping: …, onReady: …, unavailable: ServerUnavailableTexts(title, message, retry))`; F gains a startup gate it never had | H, F, T |
| `widgets` | per widget: the richest signature (`showErrorSnackBar(ctx, msg, {detail, duration})`, `ConfirmDialog(confirmLabel?, cancelLabel?, danger)`, `ErrorState(message, detail?, onRetry?, retryLabel?)`) | one class per name; `colorScheme` only | H, F, T |
| `theme` | F's `theme_context.dart` | the `BuildContext` extension + the `check_theme.sh` gate; `AppColors`/`AppStyles`/`AppText` values stay in each app | H, F, T |
| `storage` | H `SettingsService` minus the translation map | `KeyValueStore(prefix)`; H's l10n map stays in H (Phase 2 candidate: the `context.tr` mechanism) | H, F |
| `bin/run.dart`, Docker templates, `check_theme.sh` | identical files today | one copy; Docker files stay per client (byte-copy from the template, `check` like `icons.sh`) | H, F, T |

Left in the clients on purpose: all screens, domain services (`dotnet_*_service.dart`, deck/community/task calls),
Firebase setup, SignalR, barcode, TTS, theme values, translations, `AI_RULES.local.md`.

## 4. Adoption order and gates

| Phase | Scope | Gate |
|---|---|---|
| **P0 Skeleton** | Repo, pubspec, barrels, `AI_RULES.md`, `config` + `api` + `bootstrap` + `widgets` modules with unit tests; `bin/run.dart`; nothing consumed yet | `flutter analyze` + `flutter test` green in the package |
| **P1 Flash** (smallest, exercises `auth` against the shared dcm-web Auth) | `path:` dep; `FlashWebService` becomes deck/community calls over `ApiClient`; `AuthService` → `AuthSession('flash_')` + `DcmAuth`; `ServerUnavailableScreen`, `EmptyState`, `ConfirmDialog`, snackbars from the package; `main.dart` gets `BootstrapGate`; delete the replaced files | analyze + 9 tests green; `dart run dcx_flutter_core:run local`; smoke: fresh install → anonymous login → my decks → community → share; existing session survives (same prefs keys); `flutter build web --dart-define-from-file=…prod.json` |
| **P2 Hunter** | `api` (H's callers stop constructing `ApiException` themselves), `bootstrap`, `widgets` (the 8 overlapping ones), `config` (`API_BASE_URL` loses `/api` in 3 JSON files, endpoints gain it — D2), `auth`: `TokenExchangeProvider('login/firebase')` + `AuthSession('dcm_')`; Firebase sign-in stays in H's `AuthService` | analyze + 5 tests + `check_theme.sh`; smoke: Firebase login → exchange → products → community → SignalR connect; `useDotnetBackend` toggle unchanged |
| **P3 Tapit** | `config`, `api`, `bootstrap`, `widgets` (`EmptyState`, `ErrorState`, `LoadingScreen`, `BusyFilledButton` → `LoadingButton`); `auth` **not** adopted; T's `ApiService` keeps the tapit auth calls over `ApiClient` with `Authorization` header | analyze + smoke: deep-link token → worker grid → transition → photo upload (presign) |
| **P4 Tooling + rules** | `tool/run.dart` ×3 deleted (`dart run dcx_flutter_core:run`); `check_theme.sh` ×3 → package script; Docker templates + `docs/templates/check.sh`; client `AI_RULES.md` ×3 → byte-identical generic (from the package's `AI_RULES.md`) + `AI_RULES.local.md` per client (H: l10n + controller rules; T: `check_theme`) — same split as `shrinking-intros/` D2 | `md5` of the three generic copies identical; every client builds |
| **P5 Docs + gate** | `general-manager/introduction.md`: "Flutter clients" section (package, rule, adoption table); hunter/flash/tapit manager intros: one line each; `check-all.sh` (`ci-gates/`) runs package + client analyze/test; `ci-gates` Flutter workflows check out `dcx-flutter-core` beside the app; move to `implementation-done/` | — |

Phase 2 candidates (not in this plan): l10n mechanism (H's `context.tr` + map loader), `SettingsService` theme-mode
plumbing, a shared `AppColors` **shape** (not values) so `check_theme.sh` can be one gate for all.

## 5. Docs to update

| File | Change |
|---|---|
| `general-manager/introduction.md` | new section "Flutter clients — shared package" (rule block + adoption table), like "Upstream ownership" |
| `testapp/packages/dcx_flutter_core/AI_RULES.md` (new master) → `testapp/client/AI_RULES.md`, `flash/client/AI_RULES.md`, `tapit/tapit-client/AI_RULES.md` | generic, byte-identical; per-client extras → `AI_RULES.local.md` |
| hunter/flash/tapit manager intros | Client Structure sections: what comes from the package, what is app-owned |
| `general-manager/bash/lib/README.md` | `kind=flutter-web` manual mode runs `dart run dcx_flutter_core:run` (same command) |
| `general-manager/docs/app-icons/README.md` | unchanged (icons stay a byte-copy pipeline; the package does not own artwork) |

## 6. Decisions for Fatih

| # | Question | Proposal |
|---|---|---|
| D1 | Where does the package live? Owner 2026-09-27: "is a separate project as upstream really necessary? can't we choose a project and make it upstream like dcm-web?" | **Yes, a client can be the upstream — recommended: Hunter's repo.** The package folder sits inside the Hunter monorepo as `testapp/packages/dcx_flutter_core/` (a sibling of `testapp/client`, not inside the app's `lib/`); Hunter uses it with `path: ../packages/dcx_flutter_core`, Flash and Tapit with `path: ../../testapp/packages/dcx_flutter_core`. Same mental model as dcm-web: the most mature app's repo owns the shared code, "does it exist in the package?" is the ownership test, Hunter is where it is edited and tested first. Why a package folder and not the app's own `lib/`: Dart cannot depend on half an app — a `path:` to `testapp/client` would pull Hunter's Firebase, SignalR and barcode packages into Flash and Tapit and its imports would be `package:testapp/…`. The one extra folder is the price of the compiler check; everything else is the dcm-web pattern. Alternatives: own repo `dcx-flutter-core/` (cleanest separation, one more repo to clone/CI); byte-copy a `lib/shared/` from Hunter with a `--check` script (exactly dcm-web's mechanism, no package — works, but drift is caught after the fact, not by the compiler; keep as the fallback if the package feels heavy). |
| D2 | `API_BASE_URL` with or without `/api`? | Without (F, T today). H's three `appsettings.*.json` lose `/api`, and H's endpoints get the prefix inside its domain services. PWAs are rebuilt anyway (`API_BASE_URL` is compiled in). |
| D3 | Shared widgets and theming | `colorScheme`/`textTheme` only, no app `ThemeExtension`; `danger` = `colorScheme.error`. Colour values remain per app. |
| D4 | Auth header name | Default `auth` (what dcm-web's `UserAccessMiddleware` reads, used by H and F); constructor parameter so T can pass `Authorization`. |
| D5 | Dart SDK floor | Package `^3.12.2`; H's pubspec bumps from `^3.10.4` (Flutter 3.44.4 ships Dart 3.12.2 — no toolchain change). |
| D6 | H's unused `provider` dependency | Remove (client rule: no packages without need). Owner's call. |
| D7 | Tapit and `auth` | Not now; revisit when tapit-web adopts Identity/Auth (it still runs `AuthMultiTenant`). |
| D8 | Adoption order | Flash → Hunter → Tapit (smallest first, the one with the most code second while the package API is still soft, web-only last). |
| D9 | Prefs keys | Keep today's per-app keys (`flash_*`, `dcm_*`) via the `AuthSession(prefix)` so no user is logged out by the migration. |

## 7. Risks

- **H's endpoint prefix change (D2)** touches every H domain service; mitigated by the analyzer (every call goes
  through `ApiClient`) and the smoke list in P2.
- **Widget signature unification** changes call sites in all three; mechanical, compiler-guided.
- **F gains a startup gate** it did not have — behaviour change: an unreachable flash-web now shows the unavailable
  screen at launch instead of on the first action. Intended (matches H/T), noted in flash-manager.
- **CI**: Hunter's workflow sees the package in the same checkout; Flash and Tapit workflows need `testapp` checked out beside them (`ci-gates/` D-list); until then `check-all.sh` covers it.

## 8. Effort

P0 1 day · P1 ½ day · P2 1 day · P3 ½ day · P4 ½ day · P5 ½ day ≈ 4 days. After that a new client-side feature that
two apps need is written once, and a fourth Flutter app starts with `config`/`api`/`auth`/`bootstrap`/`widgets` for
free — the same "free start" the web projects get from dcm-web today.
