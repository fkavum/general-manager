# Scripts catalogue — every tool script across the projects

One line per script: path (relative to `project/`), arguments, what it is for. Written 2026-10-27 from the script headers
themselves; when a header and this file disagree, the header wins — run `<script> --help` where it exists.
"Master" = the one copy to edit; the others are byte-identical copies pushed by the master's own tooling.

Groups: §1 launchers (run / stop / logs per project) · §2 repo sync (fresh machine) · §3 upstream → downstream sharing
(web, Unity, Flutter) · §4 Crossle build / test / bench · §5 twin repos (card games) · §6 gates and misc ·
§7 legacy ops library (`bash-scripts/`) · §8 non-shell tools.

## 1. Launchers — one pane per service (`<app>-manager/tools/…/runner/`)

Thin wrappers; the implementation is `general-manager/bash/lib/*.sh` (macOS/Linux) and `general-manager/cmd/lib/*.cmd`
(Windows). A project declares what it consists of in `project.sh` / `project.cmd` next to the wrappers. Same wrapper set in
`dcm-manager/tools_v2/bash/runner`, `racer/racer-manager/tools/bash/runner`, `flash/flash-manager/tools/bash/runner`,
`tapit/tapit-manager/tools/bash/runner`, `testapp/hunter-manager/tools/bash/runner` (and `…/tools/cmd/runner/*.cmd`).
`.run/` next to them holds the generated pane scripts and `run.log` — regenerated on every run, never edited.

| Script (per project) | Arguments | Purpose |
|---|---|---|
| `run-docker.sh` | `[--no-infra] [--no-build] [--with=a,b] [--infra-env=F] [--app-env=F] [--terminal=auto\|wezterm\|tmux\|os\|none] [--dry-run] [--debug]` | Every service of the project in Docker, attached, one pane each; panes wait for the ports they need. |
| `run-manual.sh` | `[--no-infra] [--with=a,b] [--watch] [--device=X] [--infra-env=F] [--app-env=F] [--terminal=X] [--dry-run] [--debug]` | Infra in Docker, the services built and run from source (`dotnet run` / `flutter run`), one pane each. |
| `stop.sh` | `[--stop-infra] [--keep-ports] [--volumes] [--with=a,b] [--app-env=F] [--infra-env=F]` | `docker compose down` per stack (shared DB left running unless `--stop-infra`), then kills leftovers on the project's ports. |
| `logs.sh` | `[--docker\|--manual] [--services=a,b] [--with-infra] [--lines=N] [--terminal=X] [--dry-run]` | One pane per service following its logs; read-only, follows whichever mode is actually running (sources in `tools/logs.conf`). |
| `test.sh` | `[--panes=N] [--terminal=X] [--no-terminal] [--hold=SEC] [--timeout=SEC]` | Opens N dummy panes through the real launcher path and verifies they ran (marker files). |
| `project.sh` / `project.cmd` | sourced, no args | The only project-specific part: services, kinds, ports, env files, dependency order. |

Shared library behind them (`general-manager/bash/lib/`, Windows twins in `general-manager/cmd/lib/`):

| Script | Arguments | Purpose |
|---|---|---|
| `run.sh` | `docker\|manual [options above]` | The generic launcher both `run-*.sh` wrappers call. |
| `stop.sh`, `logs.sh`, `test-panes.sh` | as above | Generic implementations of the wrappers. |
| `tools.sh` | sourced | Pane/terminal/readiness/env-file machinery (`gm_add_pane`, `gm_run_panes`, logging to `.run/<script>.log`). |
| `waitport.sh` | `<label> <host> <port> [timeout-seconds]` | Blocks until a server really answers on the port (survives Docker Desktop's early accept); exit 1 on timeout. |
| `tailer.sh` | `<glob-with-%DATE%> [lines]` | Waits for log files to appear, then follows them; used inside log panes. |
| `test-generate.sh` (`.cmd` + `test-generate.ps1` on Windows) | `[--update]` | Golden test of what the launcher *generates* (`.run/env.sh`, pane scripts) against `testdata/golden/`, with stub docker/dotnet/flutter. |

Older Crossle-only launcher, kept until tools_v2 replaces it everywhere: `dcm-manager/tools/{run-docker,run-manual,stop,logs,test}.sh` (+ `.bat`) with the same flags minus `--with`, helpers in `dcm-manager/tools/lib/{common,waitport,tailer}.sh`.

## 2. Repo sync — "I just switched PCs" (`<app>-manager/tools/bash/sync/`)

| Script | Arguments | Purpose |
|---|---|---|
| `general-manager/bash/sync/sync.sh` (master) | `<branch> [--yes] [--dry-run] [--only=a,b] [--no-fetch]` | Makes every repo of a project match `origin/<branch>` exactly (fetch, report losses, reset --hard, clean, checkout -B, same for submodules; missing repos cloned). |
| `<app>-manager/tools/bash/sync/sync.sh` | same | Thin wrapper per project (dcm, racer, flash, tapit, hunter). |
| `<app>-manager/tools/bash/sync/repos.sh` | sourced | The project's repo list: `gm_repo <dir> [url=<clone url>]` per repo. |

## 3. Upstream → downstream sharing

### 3a. Shared data of Crossle (dcm-web / dcm-game-server / dcm-generator → `SharedData/` of client and game server)

| Script | Arguments | Purpose |
|---|---|---|
| `dcm-web/Tools/generate-http-shared.sh` | `[--check] [client\|server\|all]` (default all) | Mirrors `Features/*/Contracts/**` + `HttpShared/Core/**` into `dcm-client/Assets/SharedData/HttpShared` (`.meta`-safe) and `dcm-game-server/…/SharedData/HttpShared`; `--check` = drift gate (exit 1). |
| `dcm-game-server/Tools/generate-socket-shared.sh` | `[--check] [client]` | Mirrors every `Contracts/` folder of the game server into `dcm-client/Assets/SharedData/SocketShared` (`Engine/Contracts` → `Core`, `GameModules/<G>` → `Game/<G>`). |
| `dcm-generator/Tools/generate-generator-shared.sh` | `[--check] [client\|server\|all]` | Mirrors `Generator/Generator/Src/GeneratorShared/**` into `SharedData/GeneratorShared` of client and game server. |
| `racer-web/Tools/generate-http-shared.sh` | `[client]` | racer's older counterpart: assembles `racer-web/HttpShared` from the feature `Contracts/` and, with `client`, syncs it into the racer Unity project (`.meta` preserved). |

### 3b. Shared DLLs (.NET)

| Script | Arguments | Purpose |
|---|---|---|
| `dcm-generator/Tools/build-common-libs.sh` | `<dest-folder>… [--no-mysqlhelper]` or `--all` | Builds CommonLib (+ MysqlHelper) Release and copies the DLLs to the consumers (`--all` = dcm-web `Src/Lib` both, dcm-game-server `Lib` CommonLib only). |
| `dcm-web/Tools/sync-libs.sh` | none (`DCM_GENERATOR=` overrides the upstream path) | Pulls CommonLib.dll + MysqlHelper.dll from dcm-generator into `dcm-web/Src/Lib/` and stamps its README; first step of a libs change. |
| `dcm-web/Tools/build-dcm-core.sh` | `<dest-folder> [--no-deps] [--with-pdb] [--no-stamp] [--config <cfg>]` | Builds `Src/Dcm.Core` and copies Dcm.Core.dll (+ its two deps) into a downstream `Src/Lib`. |
| `<downstream-web>/Tools/sync-dcm-core.sh` (master `testapp/hunter-manager/docs/web-modularization/sync-dcm-core.sh`) | none (`DCM_WEB=` override) | Downstream pull of Dcm.Core.dll + deps from dcm-web into `Src/Lib/`; copies in racer-web, flash-web, tapit-web, hunter-web. |
| `dcm-web/Tools/list-shared-modules.sh` | none | Lists dcm-web module folders by ownership state (HOSTED / WIRED / UNWIRED / HELPER); exit 1 on a hosted-and-wired contradiction. |

### 3c. Shared web feature modules (dcm-web → downstream web projects)

| Script | Arguments | Purpose |
|---|---|---|
| `<downstream-web>/Tools/sync-dcm-features.sh` (master `testapp/hunter-manager/docs/web-modularization/sync-dcm-features.sh`) | `[--check]` (`DCM_WEB=` override) | Copies every folder in the repo's `FEATURES` list from dcm-web byte-identically and writes `Tools/dcm-features.lock.md`; `--check` = build gate. `FEATURES` is the only per-repo part. Copies in racer-web, flash-web, tapit-web, hunter-web. Since 2026-10-27 a repo syncing `Identity`/`Auth`/`Kvp` also needs `HttpShared/Core` in its list. |

### 3d. Shared Flutter packages (Hunter `testapp/packages/` → flash, tapit)

| Script | Arguments | Purpose |
|---|---|---|
| `<client>/tool/sync-flutter-core.sh` (master `testapp/packages/dcx_flutter_core/templates/tool/sync-flutter-core.sh`) | `[--check]` (`DCX_FLUTTER_PACKAGES=` override) | Vendors every package under `testapp/packages/` into `<client>/packages/` byte-identically, writes `tool/flutter-core.lock.md`; `--check` = build gate. Copies in `flash/client`, `tapit/tapit-client`. |
| `testapp/packages/dcx_flutter_core/tool/vendor.sh` | `sync\|check` | Upstream shortcut: runs the sync (or check) in every vendoring client. |
| `testapp/packages/dcx_flutter_core/tool/templates.sh` | `apply\|check` | Pushes the byte-identical client files mastered under `templates/` (AI_RULES.md, Docker/nginx.conf, tool/sync-flutter-core.sh) into every client; `check` = sync gate. |

## 4. Crossle build / test / bench (`dcm-game-server/Tools/`, `dcm-manager/tools_v2/`)

| Script | Arguments | Purpose |
|---|---|---|
| `dcm-game-server/Tools/run-tests.sh` | passes through to `dotnet test` | Runs `DcmGameServer.Tests` (`DcmGameServer/run-tests.sh` is a forwarder kept for old habits). |
| `dcm-game-server/Tools/run-smoke.sh` | passes through to `run-bench.sh` (`DCM_DICT=` overrides the dictionary folder) | Protocol gate: two load bots play real games against the LOCAL stack (`--scenario=smoke.json --target=local`); run after any change to CCG, a `Contracts/` folder, `SharedData` or `GameModules`. |
| `dcm-game-server/Tools/run-bench.sh` | `--scenario=<name.json\|/path> --target=local\|web=URL,game=host:port [--dict=DIR] [--prom=URL] [--out=DIR] [load-bot args]` | Runs one load-bot scenario; results in `bench-results/<utc>_<scenario>/`; exit 0 pass, 1 invariant failed, 2 bad args, 3 aborted. |
| `dcm-manager/tools_v2/bash/bench/bench.sh` | `<target> [scenario …] [-- extra load-bot args]` (target `local\|prod\|web=…,game=…`; scenarios `smoke stability-mix web-ramp game-conn-ramp game-play-ramp soak-60m` or a file) | Runs a sequence of scenarios against one target and copies each summary next to the benchmarking plan. |
| `dcm-manager/implementations/android-bundle-optimization/measure-mem.sh` | `<label>` (boot, lobby, ingame, …) | Reads Play's memory metric (RssAnon + VmSwap) for Crossle off a connected Android device into `mem-log.csv`. |
| `dcm-docker/crossle/win_execute.bat` | none | Windows one-click: compose build + up -d + logs -f for the crossle stack with `.env.local`. |

## 5. Twin repos — card games (`general-manager/docs/twin/`)

| Script | Arguments | Purpose |
|---|---|---|
| `general-manager/docs/twin/sync-upstream.sh` (master; copy at `<twin>/twin/sync-upstream.sh`) | `[--check \| --init] [--allow-dirty] [--upstream-root DIR] [kind …]` (kinds `web`, `game-server`, `client`) | Makes a twin repo (card-backend web / game-server, batak-client) byte-identical to its Crossle upstream except the paths in `twin/<kind>.exclude`; `--check` = drift report, `--init` = first fill, lock in `twin/upstream.lock.md`. |

## 6. Gates and misc (`general-manager/`, Flutter clients)

| Script | Arguments | Purpose |
|---|---|---|
| `general-manager/bash/flutter-core-check.sh` | `[--fast]` (skips `flutter test`) | Definition of done for a shared-Flutter-package change: packages, vendored copies, template files, every client's analyze / test / theme (+ l10n) gate; read-only. |
| `<client>/tool/check_theme.sh` → `packages/dcx_flutter_core/tool/check_theme.sh` | `[client-root]` | Design-system gate: no colour / radius / spacing / text-size literal outside `lib/theme/`; client extras in `tool/check_theme.local.sh`. |
| `<client>/tool/check_l10n.sh` → `packages/dcx_flutter_localization/tool/check_l10n.sh` | `[client-root]` (`L10N_STRICT=1`, `L10N_DYNAMIC=prefix,…`) | Localization gate: generated constants up to date, csv consistency, `L.` constants only. |
| `general-manager/docs/app-icons/icons.sh` | `list` · `apply <app\|all>` · `check [app\|all]` | Central app-icon pipeline for the Flutter clients (artwork per app in this folder; macOS + swift). |
| `testapp/off-mirror/seed.sh` | none (`DUMP_PATH` in `.env`) | Seeds the Open Food Facts mirror MongoDB from the mongodump archive (~60 GB, re-runnable). |
| `dcm-dict/scripts/migrate/restructure.sh` | `[--run]` (default dry run) | Phase 0.2 Drive-folder restructure of the master dictionary DB (byte-compare before any delete). |
| `obs/start.command` / `obs/start.bat` | none | Double-click starter of the OBS toolkit (checks for Node, then starts it). |

## 7. Legacy ops library — `bash-scripts/` (server-side, pre-Docker era; no headers, purposes from the names)

Kept for the Ubuntu/mini hosts; not used by the launchers above. Each `*_env.sh` holds the variables of the runner next to it.

| Folder | Scripts | Purpose |
|---|---|---|
| `apps/bash_lib/_sources/` | `build_unity.sh`, `build_unity_headless.sh`, `build_ipa.sh`, `export_ipa.sh`, `upload_to_appstore.sh`, `build_number.sh`, `package_webgl.sh`, `deploy_webgl_image.sh`, `publish_dotnet.sh`, `run_app.sh`, `serve_{android,ipa,webgl}.sh`, `create_release_branch.sh`, `create_submodule_release.sh`, `merge_branch.sh`, `merge_submodules.sh`, `pull_from_git.sh`, `pull_from_submodule.sh`, `check_process_health.sh`, `try_endpoint.sh`, `message_bot.sh`, `logger/*.sh` | Sourced building blocks: Unity/iOS/WebGL builds, App Store upload, dotnet publish, git/submodule release flow, health checks, chat notifications, logging. |
| `apps/bash_lib/_uow/` | `build_unity_{android,ios,server,webgl}.sh`, `run_unity_server.sh`, `deploy_dotnet.sh`, `kill_process.sh`, `kill_process_port.sh`, `ip_tracker.sh` | Units of work composed from `_sources`. |
| `apps/bash_lib/{mysql,mongo}/` | `super_mysql_backup.sh`, `super_mysql_restore.sh` (`BACKUP_PATH` dir or file), `mongo_start.sh` | Database backup / restore / local Mongo start. |
| `apps/bash_lib/scripts/`, `ssh/`, `system_metrics/`, `services/`, `profiles/`, `pf/` | `backup-configs.sh`, `renew_domains_ssl.sh`, `rotate-logs.sh`, `wg-up.sh`, `sshLogs.sh`, `all_metrics.sh`, `memory.sh`, `usage.sh`, `top_consumers.sh`, `iploc.sh`, `ip_tracker.sh`, `generate_csr.sh`, `pfStarterUpdated.sh` | Host maintenance: config backups, SSL renewal, log rotation, WireGuard, SSH monitoring, metrics, CSR generation, pf starter. |
| `apps/dcm_ubuntu/` | `setup_project.sh`, `deploy_dcm.sh`, `release.sh`, `auto_merge.sh`, `env.sh`, `nginx/{setup,cert}.sh`, `ubuntu/{first,ssh,zsh}.sh`, `website/{setup,deploy}.sh` | First setup and deploy flow of the Ubuntu host (DCM + website + nginx). |
| `apps/dcm-mini/` | `z_dcm_client/build_{android,ios,webgl}.sh` (+ `env_*.sh`), `z_dcm_game_server/deploy_game_server.sh`, `z_dcm_generator/deploy_generator.sh`, `z_dcm_service/deploy_web_service.sh`, `web_dcm/dcm_web_deploy.sh`, `backup_mysql/runner.sh`, `restore_mysql/runner.sh`, `unity_counter/counter_unity_{android,ios}.sh`, `nginx/{setup,cert}.sh` (each with its `*_env.sh`) | Per-service deploy runners of the Mac mini host; `z_dcm_geme_server_old/` is the superseded game-server set. |
| `backups/` | `pfStarter.sh`, `pfStarterSelfRotating.sh` | Older pf starters with log rotation. |

## 8. Non-shell tools worth knowing

| Tool | Arguments | Purpose |
|---|---|---|
| `dcm-manager/tools_v2/python/webgl-serve/serve.py` | `<build-folder> [port]` (default 8090) | Serves a Unity WebGL gzip build locally with the right `Content-Encoding` headers. |
| `racer/racer-manager/implementations/new-cars/tools/decimate_fbx.py` | Blender: `-b --factory-startup -P decimate_fbx.py -- <in.fbx> <out.fbx> [split=a,b] [normals=1] [carve=…] [wheels=a,b]` | Mesh reduction of heavy car FBX files to a triangle target, node names kept. |
| `racer/racer-manager/implementations/new-cars/tools/dump_fbx_textures.py` | Blender: `-b --factory-startup -P dump_fbx_textures.py -- <in.fbx> <out.txt>` | Lists which texture files an FBX's materials use. |
| `unity command …` (Unity Pipeline CLI; project commands are `[CliCommand]`s in `dcm-client/Assets/DontCrossMe/Editor/Cli/`) | `unity command --detail compact [--query …]`, then `unity command <name>` | Runs Editor-side builders/validators live: `booster_{build_assets,build_test_scene,preview_hammer,validate}`, `heart_stats_{build,lobby,validate}`, `season_ui_{build,validate}`, `trophies_{build,validate}`. |
| `dcm-dict/scripts/{categorizer,export,golden,importer,kiki-extract,legacy,master-build,verify}/` | per folder | Python pipelines of the master dictionary DB (see dcm-dict docs). |
