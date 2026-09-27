# sharing-hygiene — the small fixes around the sharing machinery (review §2.5, §2.7, §3.5, §3.6)

Owner 2026-09-27: agreed, plan each. Multi-project: general-manager, dcm-web, 4 downstreams, hunter-manager,
dcm-manager, racer-web. Paths relative to `/Users/fkavum/Documents/project/`.

## 1. Items

| # | Finding (verified 2026-09-27) | Change | Where |
|---|---|---|---|
| H1 | All four `Tools/dcm-features.lock.md` record dcm-web `961a878` **with 33 uncommitted files** — the lock does not identify what was copied | `sync-dcm-features.sh` and `sync-dcm-core.sh` **refuse** a dirty dcm-web tree (`git status --porcelain` non-empty → exit 1 with the file list; `--allow-dirty` for an explicit local experiment, recorded in the lock as `DIRTY`). Master + 4 copies re-synced; md5 check | `hunter-manager/docs/web-modularization/` master → 4 `Tools/` |
| H2 | `HttpShared/` at the project root is a generated intermediate outside git; dcm-client's copy (in the submodule) lags it | `generate-http-shared.sh` writes straight into the targets (`client`, `server`) and no longer into `../HttpShared`; delete the root folder. racer-web's script already writes into its own repo | dcm-web `Tools/`, root |
| H3 | Master copies of the generic web rules + sync scripts live in `testapp/hunter-manager/docs/web-modularization/` (inside the Hunter monorepo) | Move to `general-manager/docs/web/` (`AI_RULES.web.md`, `sync-dcm-features.sh`, `sync-dcm-core.sh`, `README.web.template.md`, `generic-prompt.md`); every header comment and every intro that names the old path updated; hunter-manager keeps a 1-line pointer file | general-manager, hunter-manager, 4 web repos (header comments), dcm-manager intro |
| H4 | `dcm-manager/tools` (v1) and `tools_v2` coexist; `general-manager/bash/lib/README.md` points at a non-existent `dcm-manager/tools_v2/README.md` and does not list flash | Delete `dcm-manager/tools` (v1) after confirming nothing references it (`grep -r "tools/run-" dcm-manager`); fix the README pointer to `tools_v2/bash/runner/README.md`; add flash to the user list; the v1/v2 comparison note in `tools_v2/bash/runner/README.md` becomes history | dcm-manager, general-manager |
| H5 | dcm-web `Main.csproj` / `Main.Hosted.csproj` comments cite `AuthOffline` as the hosted example; only `Core/Cors` is hosted | Comment → `Core/Cors` | dcm-web |
| H6 | `racer-web/Src/Docs/README.md` says only `.env.local` exists; `.env.dev`/`.env.prod` are present | Fix the line | racer-web |
| H7 | racer-web has no test project | `Src/Main.Test` from flash's shape: `ConfigureMysqlFixture` (Testcontainers), `RouteInventoryTest` + `EfModelSnapshotTest` with `Baselines/`, one login smoke (`anonymous` → `refresh` → `me`); `racer.sln` gains it | racer-web |
| H8 | Strays: `general-manager/implementations/dependencies/dev-prompt.md` (a pasted `flutter pub get` log), `dcm-docker/error` (230 KB), `dcm-manager/implementations/migrationguide.md` loose file, two JSON files in `dcm-manager/docs/`, Grafana compose mounts `./my.cnf` but the file is `./.my.cnf` | Owner decides per item: delete the log folder and `error`; move `migrationguide.md` into `docs/`; fix the Grafana mount (or the filename); the JSON files: owner's call, not touched | general-manager, dcm-docker, dcm-manager |
| H9 | Three repo topologies (per-component `dcm-*`, monorepo `testapp/flash/tapit`, Unity-repo-with-manager `racer` + separate `racer-web`) | Write the rule for **new** apps into `general-manager/introduction.md` → "Adding an app": monorepo `<app>/{<app>-web,<app>-client,<app>-manager}`; nothing existing is moved | general-manager |
| H10 | `bash/lib/README.md`: "used by flash, hunter, tapit, racer, dcm-manager/tools_v2" — flash missing; `stop.sh` has an uncommitted per-service `env=` fix | README line; the `stop.sh` change is the owner's to commit (it mirrors `run.sh` — looks correct) | general-manager |

## 2. Phases

| Phase | Scope | Gate |
|---|---|---|
| P0 | H1 (scripts) + H3 (move masters) together — one re-sync of the 4 copies | md5 of the 5 copies identical; `--check` green ×4; a dirty dcm-web makes the script exit 1 |
| P1 | H2, H5, H6, H10 | `generate-http-shared.sh client` + `server` leave the submodule copies identical to before (diff), root folder gone |
| P2 | H7 racer-web tests | `dotnet test` green; baselines committed by the owner |
| P3 | H4, H8, H9 | `dcm-manager/tools` gone, README links resolve, intro rule written; move to `implementation-done/` |

## 3. Decisions for Fatih

| # | Question | Proposal |
|---|---|---|
| D1 | Dirty-tree behaviour | Refuse (exit 1), `--allow-dirty` escape hatch that stamps `DIRTY` into the lock. |
| D2 | Root `HttpShared/` | Delete after the generator writes directly into the targets; dcm-manager intro's "Output: `../HttpShared/` (outside all repos)" line changes. |
| D3 | Masters' new home | `general-manager/docs/web/` (next to `docs/app-icons/`, same "control from general-manager" idea). |
| D4 | H8 strays | Delete the pub log + `error`; move `migrationguide.md`; JSON files untouched unless told. |
| D5 | Topology rule | Monorepo for new apps; existing untouched. |

Effort: ≈ 1 day total; H7 is half of it.
