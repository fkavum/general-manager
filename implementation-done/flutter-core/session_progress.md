# flutter-core — progress

Plan: `overview.md`. Owner 2026-09-27: yes; how-to left to the plan; wants the backend/Unity modularization + upstream
style. Then "implement all, I will review them later" — P0–P5 implemented the same day; two owner review rounds; **moved to `implementation-done/` 2026-09-27** (owner).

| Step | Status |
|---|---|
| Fact sheet of H/F/T (config, api, auth, bootstrap, widgets, theme, tooling, tests, rules) | ✅ 2026-09-27 |
| D1–D9 | 🟡 implemented with the proposals as defaults; **D1 amended** (vendoring, below); open for veto |
| P0 package skeleton + config/api/auth/storage/bootstrap/widgets + tests | ✅ 2026-09-27 |
| P1 Flash adopts (auth included) | ✅ 2026-09-27 |
| P2 Hunter adopts (auth via Firebase token exchange) | ✅ 2026-09-27 |
| P3 Tapit adopts (no auth, D7) | ✅ 2026-09-27 |
| P4 launcher, shared theme gate, templates (AI_RULES + nginx), `AI_RULES.local.md` ×3 | ✅ 2026-09-27 (old `tool/run.dart` ×3 left for the owner to delete) |
| P5 docs + `bash/flutter-core-check.sh` | ✅ 2026-09-27 — moved to `implementation-done/` |
| Obsolete files deleted (round 2) | ✅ 2026-09-27 |
| Owner: live smoke per app (overview §4), commit, then re-run `tool/sync-flutter-core.sh` in flash/tapit so the lock names a commit | ⏳ |

Nothing committed, staged or deleted (hard rule; file deletion was also blocked by the permission classifier).

## D1 amended — vendored copies for flash and tapit

The three clients are three GitHub repos (`jinju-live/testapp`, `fkavum/flash`, `fkavum/tapit`) and Dokploy builds
each from its own checkout, so `path: ../../testapp/packages/…` would work on the Mac and fail on every deploy.
Hunter's Docker context (`client/`) did not contain `../packages` either. Implemented:

- **Hunter**: `path: ../packages/dcx_flutter_core`; compose `context: "../.."` (repo root), `dockerfile:
  client/Docker/Dockerfile`, allow-list `client/Docker/Dockerfile.dockerignore`. Dokploy compose path unchanged.
- **Flash, Tapit**: vendored copy `<client>/packages/dcx_flutter_core/` (`path: packages/…`), Dockerfile copies
  `packages/` before `pub get`, `analysis_options.yaml` excludes `packages/**`. Each pulls with its own
  `tool/sync-flutter-core.sh [--check]` (lock `tool/flutter-core.lock.md`) — the twin of `Tools/sync-dcm-features.sh`;
  upstream `tool/vendor.sh sync|check` just runs both. The compiler still checks each client
  against its copy; `sync-flutter-core.sh --check` catches a stale or hand-edited copy. CI needs no cross-repo checkout.

## What was built

**Package** `testapp/packages/dcx_flutter_core/` 0.1.0 (deps `http`, `shared_preferences`), 25 tests:
`config` (`AppConfig`), `api` (`ApiClient`, `ApiAuthenticator`, `ApiException(statusCode, message, endpoint:)`,
`ServerUnavailableException`, `ErrorBody`), `auth` (`DcmAuth`, `AuthSession`+`AuthSessionKeys`, `DeviceId`,
`AnonymousProvider`, `TokenExchangeProvider`, `DcmUser`), `bootstrap` (`BootstrapGate`, `ServerUnavailableScreen`,
`ServerUnavailableTexts`), `widgets` (`EmptyState`, `ErrorState`, `LoadingIndicator`, `LoadingScreen`,
`ButtonSpinner`, `LoadingButton`, `ConfirmDialog`, `TextPromptDialog`, snackbars), `theme` (`context.scheme/text`,
`DcxTokens`), `storage` (`KeyValueStore`); `bin/run.dart`; `tool/check_theme.sh` (shared baseline, sources the
client's `tool/check_theme.local.sh`), `tool/vendor.sh`, `tool/templates.sh`; `templates/AI_RULES.md`,
`templates/Docker/nginx.conf`; `AI_RULES.md`, `README.md`.

**Flash**: `FlashWebService` = routes over `ApiClient` + `DcmAuth(AnonymousProvider)`; `AuthService` over
`AuthSession` with the original `flash_*` keys; package `BootstrapGate` in `main.dart` (`FlashApp(ping:)` for tests);
package widgets; `theme_context.dart` re-exports the package theme. 80 tests (+1).

**Hunter**: `ApiService` over one shared `ApiClient` + `HunterAuthenticator` (dotnet → `DcmAuth` with
`TokenExchangeProvider('/api/login/firebase')`, `auth: Bearer`, re-exchange on 401; Firebase path →
`Authorization: Bearer <id token>`); `AuthService.session = AuthSession(KeyValueStore('dcm_'))` (keys unchanged);
D2 done — `API_BASE_URL` without `/api` ×3 env files, 88 endpoint paths gained `/api`; `BootstrapGate` wraps the
package gate with translated texts; package widgets with `context.tr` labels; `filledButtonTheme` mirrors the
elevated one; `provider` removed (D6), SDK `^3.12.2` (D5), 5 bogus lint names removed. 33 tests (+5).

**Tapit**: `ApiService` singleton over `ApiClient` + private `_JwtAuthenticator` (`Authorization`, no retry);
presigned S3 PUT via `sendExternal`; package gate with `onReachable` = deep-link login (`TapItApp(ping:)`);
`serverUnavailableTexts` keeps today's bilingual strings; `LoadingButton` with `styles.filledTinted(color)` (theme
token, gate-clean); `EmptyStateTapit` keeps the worker-scale look (ownership rule `<Name><App>`). 2 tests (+1).

## Verification 2026-09-27

| | analyze | test | theme gate | web build (prod) | docker build |
|---|---|---|---|---|---|
| package | 0 issues | 31/31 (after review round 1) | — | — | — |
| Flash | 0 issues | 80/80 | ✔ | ✔ prod URL baked | ✔ |
| Hunter | 0 errors/warnings, 128 infos (126 before, pre-existing) | 33/33 | ✔ | ✔ no `/api` in URL | ✔ repo-root context, 2.6 MB |
| Tapit | 0 issues | 2/2 | ✔ | ✔ | ✔ |

`vendor.sh check` ✔ ×2, `templates.sh check` ✔ ×6, `dart run dcx_flutter_core:run` resolves in all three clients.
**Not done:** live smoke per app (P1/P2/P3 smoke lists in `overview.md` §4) — needs the backends and a human.

## Owner review round 1 — 2026-09-27

Owner: "1. disable the startup gate for flash, 2. for visual changes if you can make it configurable … without weird
look, 3. the small print under error states, the hunters way".

1. **Flash**: `BootstrapGate(enabled: false, …)` — offline-first, local decks open without flash-web; online actions
   still route an outage to the package `ServerUnavailableScreen`. Test: unreachable server does not block launch.
2. **`DcxTheme`** (package 0.2.0): a package-owned `ThemeExtension` every package widget reads — spacing, max width,
   EmptyState icon size/colour/**circle background**/styles, prominent (server-unavailable) icon + styles, ErrorState
   icon/size/colour/message + detail styles/**text-only retry**, spinner size/stroke/colour, **trailing button icon**,
   danger button style, snackbar colours + durations. All fields optional (fallback: Material roles / `DcxTokens`).
   Each app registers one from its own tokens in `AppTheme` (`_dcx`), so the old looks are back without call-site
   styling: Hunter — icon circle, danger error text + `detailMono`, text-only retry, `label  icon` buttons, danger
   snackbar 4 s, big `displaySmall` unavailable screen; Tapit — worker scale (`wifi_off` 64 muted, `workerBody`,
   `workerTitle`/`bodyMuted` hero, 24 px spinner, danger snackbar); Flash — its token sizes and `dangerButton`.
   Hunter gained tokens `emptyIconSize`/`emptyIconAlpha`/`heroIconSize`/`spinnerStroke` in `app_styles.dart` (were
   literals in the old widgets). Rendered each app's set under its real theme and checked (scratchpad goldens).
3. **Hunter's small print is the package default**: `errorDetail(error)` — an `ApiException` renders
   `METHOD /path failed (HTTP n): message`; `ErrorState(detail:)` and `showErrorSnackBar(detail:)` take the caught
   error. Hunter's `ApiService.describe` removed; its 8 call sites pass `snapshot.error`.

Still true: `ApiException.toString()` is the message only; a refused Firebase exchange is an `ApiException`, no longer
"server unavailable"; every JSON body goes out as UTF-8 bytes, every response is read as UTF-8. Remaining small
differences: Tapit's error-state padding 16 (was 24), Hunter's unavailable-screen title→message gap 12 (was 16).

## Owner review round 2 — 2026-09-27

Owner: "delete the obsolete files for me, i dont see any sync shell script file in the tools folder like we have in
the downstream web projects".

- **Obsolete files deleted** (28, nothing imported them): Flash — `server_unavailable_screen`, `widgets/common/
  {empty_state,confirm_dialog,app_snack_bar,text_input_dialog,retry_button}`, `tool/run.dart`; Hunter —
  `auth_session`, `config/app_config`, `server_unavailable_screen`, `widgets/common/{unreachable_state,empty_state,
  error_state,loading_screen,loading_button,confirm_dialog,text_prompt_dialog}`, `tool/run.dart`; Tapit —
  `config/app_config`, `widgets/common/{app_snack_bar,busy_filled_button,button_spinner,empty_state,error_state,
  loading_indicator,loading_screen,offline_hero}`, `tool/run.dart`. Tapit's `styleFrom` gate no longer excludes
  `busy_filled_button.dart`.
- **Downstream pull script**, like `Tools/sync-dcm-features.sh`: `flash/client/tool/sync-flutter-core.sh` and
  `tapit/tapit-client/tool/sync-flutter-core.sh` (byte-identical; master `templates/tool/sync-flutter-core.sh`,
  distributed by `tool/templates.sh apply`). Without args: rsync the upstream package into `packages/dcx_flutter_core/`
  and write `tool/flutter-core.lock.md` (version, upstream commit, branch, uncommitted upstream files, time), plus a
  version-bump and "next: pub get / analyze / test / theme gate" reminder. `--check`: exit 1 on any diff (verified
  with a hand edit). Upstream location auto-detected (`../../testapp/packages/dcx_flutter_core`), override
  `DCX_FLUTTER_CORE=`. The upstream `tool/vendor.sh sync|check` is now only a loop over both clients' scripts.

## Package follow-ups

1. Hunter's pending `implementations/localization/` plan touches the server-unavailable screen and API error text —
   it now goes through `ServerUnavailableTexts` and `ErrorBody`/`ApiException`/`errorDetail`.

## 2026-09-27 — Phase 2 candidate "l10n mechanism" done elsewhere
- The localization engine is the sibling package `testapp/packages/dcx_flutter_localization` (csv per language, generated
  `L.` keys, `context.tr`, `LanguagePicker`, `resolveCoreError`, `l10n gen|check` + gate); core gained `ApiException.code`,
  `ErrorBody.code()`, `ServerUnavailableScreen.overlay`; `templates/tool/sync-flutter-core.sh` now vendors every package
  under `testapp/packages/` (one lock row each) and `bash/flutter-core-check.sh` loops packages + runs `tool/check_l10n.sh`
  for clients that localize. Plan + progress: `testapp/hunter-manager/implementations/localization/`.
