# General Manager — cross-app conventions

This folder holds decisions that span more than one app. Per-app knowledge stays in each app's own manager
(`dcm-manager`, `testapp/hunter-manager`, `flash/flash-manager`, `tapit/tapit-manager`, `racer/racer-manager`).
All paths are relative to `/Users/fkavum/Documents/project/`.

## Apps

| NN | App | Status | Code | Manager |
|---|---|---|---|---|
| 00 | Common infra | running on VPS | `dcm-docker/common-infra` (shared MySQL `dcx-mysql-container`, `dcx-network`), `dcm-docker/Grafana`, `dcm-docker/traefik`, `bash-scripts/` (host nginx, deploy scripts) | this folder |
| 01 | DCM / Crossle | **production** | `dcm-web`, `dcm-game-server`, `dcm-generator`, `dcm-client` (Unity), `dcm-admin`, `dcm-docker/crossle*`, `dcxstudios-website` | `dcm-manager/introduction.md` |
| 02 | Hunter | pre-MVP | `testapp/hunter-web`, `testapp/client` (Flutter PWA), `testapp/off-mirror` (parked) | `testapp/hunter-manager/introduction.md` |
| 03 | Flash | deployed API, PWA not yet | `flash/flash-web`, `flash/client` (Flutter PWA) | `flash/flash-manager/introduction.md` |
| 04 | Tapit | not deployed | `tapit/tapit-web`, `tapit/tapit-client` (Flutter PWA) | `tapit/tapit-manager/introduction.md` |
| 05 | Racer | local only | `racer-web`, `racer` (Unity) | `racer/racer-manager/introduction.md` |

## Ports

See **[PORTS.md](PORTS.md)** — the only authoritative list. Summary of the scheme:

- Port = `2NNRR`: `NN` app number, `RR` role offset. Range 20000–29999, 100 ports per app.
- Role offsets are identical across apps: `00` web API, `01` game TCP, `02` game WS, `03` generator, `04` admin API,
  `10` SQL, `11` Redis, `12` other DB, `13` object storage, `20` main client, `21` PWA, `22` admin SPA, `3x` metrics of backend `0x`.
- Our own services bind the registry port inside the container (host port == container port).
  Third-party images keep native ports inside (MySQL 3306, Redis 6379, Mongo 27017, nginx 80); only the host publish uses the registry number.
- Compose files use env with the registry value as default, e.g. `"${DCM_WEB_PORT:-20100}:20100"`.
- Legacy public ports are kept as extra publishes while shipped clients depend on them (DCM 2303 / 2306).

Adding a service: pick the role offset, write it in `PORTS.md` first, then wire compose → bind → consumers → Dokploy target → Prometheus → docs (checklist at the bottom of `PORTS.md`).

Adding an app: take the next free `NN`, add a row to the app table above and to `PORTS.md`.

## Shared infrastructure facts

- `dcx-mysql-container` (host 20010 → 3306, network `dcx-network`) is the one shared MySQL; each app creates its own database in its migration 0000. It is **not** the Crossle game DB (`dcm-mysql-container`, host 20110, network `dcm-network`).
- Public HTTPS for every web service goes through Dokploy's Traefik on `dokploy-network`. Dokploy stores the **target container port** in its UI; it is not in any repo, so a port move needs a manual Dokploy edit.
- The Ubuntu host nginx (`bash-scripts/apps/dcm_ubuntu/nginx`) still fronts Crossle: TCP stream `2303 → 20101`, HTTP vhosts → `20100`.
- Prometheus config lives in `dcm-docker/Grafana/prometheus.yml`; every metrics port change goes there too.
- Web config lives in `Src/Main/Resources/Configs/appsettings.<env>.json` (selected by `--env=${WEB_COMMAND_ARG}`),
  like dcm-web. docker-compose and Dokploy inject no app settings (`Mysql__*`, `JWT__SecretKey`, …); `.env.*`
  only holds compose-level values (`WEB_COMMAND_ARG`, `WEB_LOG_PATH`, port). Applied to hunter/flash/tapit/racer
  2026-09-27.

## How we work with AI

Same convention as the app managers: multi-project features get a folder `general-manager/implementations/{feature}/`
with per-project notes and a `session_progress.md`. Move to `implementation-done/` when finished.
Current: `implementations/port-scheme/` — the migration to the `2NNRR` scheme.
Done 2026-09-27: `implementation-done/flutter-core/` — the shared Flutter package `dcx_flutter_core` (Hunter upstream,
flash/tapit vendored + `tool/sync-flutter-core.sh`), adopted by all three clients; see "Flutter clients" below.
Done 2026-09-25: `implementation-done/identity-endpoints/` — the user's self-service routes (`me`, `change_name`, delete
request, language; server-tier `change_status`/`set_language`/`set_name`) moved into `Identity` for every project, Crossle
keeps only `get` + `public_profile`; `IdentityOptions.ClientEditable` decides per app which user-tier routes the client may call.
Done 2026-09-25: `implementation-done/identity-core/` — one `Identity` + one `Auth` for every project including Crossle,
provider and enricher modules, Crossle's clients untouched (contract test); prerequisite of hunter's `auth-upstream`.
Done 2026-09-24: `implementation-done/upstream-ownership/` — one upstream (dcm-web), one owner per shared web module,
`sync-dcm-features.sh`, hosted-not-wired modules (`NOT_USED_BY_CROSSLE.md` → `Src/Main.Hosted`).

## App icons (Flutter clients)

Decided 2026-09-27, details in `docs/app-icons/README.md`: **every Flutter client's icon is controlled from
`docs/app-icons/`** — the artwork (`<app>/source.png`, optional hand-drawn `<app>/icon_<N>x<N>….png`), the pipeline
(`app_icons.swift`, copied byte-identical to `<client>/tool/`) and the client registry (`apps.txt`). No packages.
`./icons.sh apply <app|all>` pushes and regenerates, `./icons.sh check` is the sync gate. Never edit a client's icon
files by hand. Adopted: Hunter, Flash. Not yet: Tapit.

## Flutter clients — shared package

Decided and implemented 2026-09-27, details in `implementation-done/flutter-core/`: **`dcx_flutter_core` is the Flutter twin of the dcm-web upstream.** It lives in Hunter's repo at
`testapp/packages/dcx_flutter_core/` and owns `config` (`AppConfig`, `API_BASE_URL` without `/api`), `api`
(`ApiClient`, `ApiException`, `ServerUnavailableException`), `auth` (`DcmAuth` over the shared Auth/Identity),
`bootstrap` (`BootstrapGate`, `ServerUnavailableScreen`), `widgets`, `theme`, `storage`, the launcher
(`dart run dcx_flutter_core:run [env] [device]`) and the baseline theme gate.

- Exists in the package → import it; needed by a second client → promote it there. Never copy client → client.
- Hunter: `path: ../packages/dcx_flutter_core` (Docker context = repo root). Flash, Tapit (own repos, built by
  Dokploy from their own checkout): vendored copy `<client>/packages/dcx_flutter_core/`, pulled by the client's own
  `tool/sync-flutter-core.sh [--check]` (writes `tool/flutter-core.lock.md`) — the twin of `Tools/sync-dcm-features.sh`.
- `templates/AI_RULES.md` + `templates/Docker/nginx.conf` are byte-identical in every client (`tool/templates.sh
  apply|check`); per-client rules in `AI_RULES.local.md`.
- Gate: `bash/flutter-core-check.sh` (package + copies + templates + each client's analyze/test/theme gate).
- Adopted: Flash (incl. `auth`), Hunter (incl. `auth`), Tapit (no `auth` until tapit-web moves to Identity).

## Upstream ownership (web projects)

Decided and implemented 2026-09-24, details in `implementation-done/upstream-ownership/overview.md`:

- **dcm-web is the only upstream.** A module used by two or more web projects is owned by dcm-web even when Crossle
  does not use it; such a module carries `NOT_USED_BY_CROSSLE.md` in its folder and is not wired in `AppModules.cs`.
- **Never copy sibling → sibling.** A second project needing an app's module means *promote to dcm-web*, then both sync.
- Synced folders are byte-identical and pulled with `Tools/sync-dcm-features.sh` (features array inside the script);
  `Dcm.Core` with `Tools/sync-dcm-core.sh`. A downstream diff against dcm-web is a bug (`--check` gate).
- A hosted module (`NOT_USED_BY_CROSSLE.md`) is excluded from `DcmCoreWeb.dll` and compiled by `dcm-web/Src/Main.Hosted` —
  ASP.NET maps every controller in an assembly, so hosted routes would otherwise collide
  with Crossle's. Today hosted: `Core/Cors`; synced modules Crossle runs too: `Identity`, `Auth`, `Kvp`,
  `Core/Storage`, `Core/Database/Migration`, `Core/Database/MysqlEfModule.cs`, `Core/Swagger/SwaggerBearerSecurity.cs`.
- **Identity vs Auth** (identity-core, 2026-09-25): `Identity` owns the `user`, `user_status` and `log_deleted_users`
  tables AND the user's self-service routes on `api/user` (`me`, `change_name`, `change_language`, delete request; server-tier
  `change_status`/`set_language`/`set_name`/`set_role` — `IdentityOptions` carries the app's policy: `NameRule`, `ClientEditable`,
  languages; roles are `user.role` + `[RequireRole]`); `Auth` =
  linked accounts + JWT + LoginService + `api/login/*`, one module for Crossle and the apps; providers (`Auth<Provider>`)
  and login enrichers are modules an app registers; aggregates and app-specific rules stay per app as thin classes over
  Identity's seams (Crossle `Features/User` = `get` + `public_profile` aggregate; racer/flash need nothing extra).
  `dcm-web/Tools/list-shared-modules.sh` prints the live state; each downstream's `Tools/dcm-features.lock.md` its set.
  A shared module with tables ships `Features/<Name>/Resources/<name>.sql` (idempotent create + seeds) — the first-time
  DbUp script for any downstream (2026-09-25).

### Hard rules (all projects, no exceptions)

1. **Never commit.** Implement, then stop and report. Fatih reviews and commits himself. This includes `git commit`,
   `git push`, amends, tags, and any script or hook that would do it. Staging is also his call — leave the working tree as is.
2. **No secret-management advice.** Secrets in this repo and in GitHub are fine and intentional. Do not warn about
   committed credentials, do not suggest `.env` files, vaults, rotation, or `.gitignore` entries for them, and do not
   redact values in code or output unless explicitly asked.
