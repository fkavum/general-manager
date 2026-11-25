# card-platform — sync tooling (P1d ✅), card-backend mono repo, ports, manager (P2)

Paths relative to `/Users/fkavum/Documents/project/`. Map source: read-only scan 2026-10-27. Owner's revision of D2
(2026-10-27): **the whole backend is one mono repo `card/card-backend`** (web + game server + docker + manager + twin
tooling); only the Unity client is a separate repo per store app (`card/batak-client`). This follows sharing-hygiene
H9/D5 (mono repo for new apps).

## 1. `sync-upstream.sh` (P1d ✅ 2026-10-27) — one script, three manifests

Masters in **`general-manager/docs/twin/`** (`sync-upstream.sh`, `web.exclude`, `game-server.exclude`, `client.exclude`,
`README.md`); byte-identical copies in `card/card-backend/twin/` and `card/batak-client/twin/`. `twin/` sits outside the
synced subtrees, so one script serves every kind of a repo.

| Behaviour | Detail |
|---|---|
| Source | upstream found as the first ancestor folder containing `dcm-web` (or `--upstream-root DIR`); `#@upstream=` in the manifest names the repo, `#@dest=` the subfolder (`web`, `game-server`, `.` for the client). Dirty upstream → exit 1 with the `git status` list (H1); `--allow-dirty` stamps `DIRTY(n)`; not on `dev` → warning. |
| Copy | `rsync -rlt --delete` with two exclude lists: the manifest, and a generated one = `.git`, `.gitmodules`, `.idea`, `twin/`, `.DS_Store`, every submodule path, every path the upstream gitignores (`git status --ignored` plus the root `.gitignore` patterns themselves — an ignored folder that is empty at that moment, e.g. `Temp/` of a closed editor, is not listed by git; 2026-10-28). Excluded = neither copied nor deleted. Submodules are pinned by git on the twin, never copied. |
| Lock | `twin/upstream.lock.md`: one row per kind — upstream, branch, commit, clean/DIRTY(n), submodule commits, UTC time, manifest md5. |
| `--check` | `rsync --checksum --dry-run --itemize-changes` minus attribute-only lines, plus a submodule-commit compare → non-empty = exit 1 with the list. The build gate of every twin. |
| `--init` | empty destination (only `twin/`, `.git` allowed), copies the master manifest when missing, syncs, prints the per-app paths (the manifest's own lines) and the `git submodule add … && checkout <commit>` commands. No git operation is run by the script. |

Dry run 2026-10-27 (scratch, `--allow-dirty` because dcm-web/dcm-game-server/CCG carry the uncommitted P1a/P1b work):

| Twin | Result |
|---|---|
| `card-backend/web` | 769 paths; builds `Dcm.sln` (0 errors) with stub `AppModules` (Crossle's minus `CrossleStatsExtension` → `CardStatsExtension`, membership default Batak), configs on 206xx, empty `Migrations/Versioned/`. |
| `card-backend/game-server` | 252 paths; builds `GameServer.sln` with `GameModules/Stub` (`StubGameModule.Register()` = `GameConfig` + factory + one `LobbyDefinition` 201/Batak/4 seats; `StubGame : IGame` no-op) and `AppBootstrapper` = Crossle's with the module swapped; `dotnet test` **125 pass / 3 failed** = the three known upstream failures (`LoggedInUserPoolTests` ×2, `RewardControllerTests.GiveRewardAsync_WithNonExistingUid`). Found on the way: `Core/Scripts/Editor/Tests/Game/{LobbyTest,LevelModelTest}.cs` are NUnit fixtures compiled into the server binary that reference CrossWord → manifest line (S10 for the owner). |
| `batak-client` | 1.3 GB, every per-app path absent (`DontCrossMe`, `AppConfig*`, Firebase files, `ProjectSettings.asset`, Addressables groups, keystore), shared trees present; compile waits for P1c + Unity. |
| semantics | stray file in a synced path → `*deleting`; edited synced file → listed and restored; file under a manifest path → kept; dirty upstream → refused; `--check` green ×3 afterwards (only "submodule … twin missing", expected without git). |

## 2. Ports and registry (P2, first step)

`PORTS.md` + `general-manager/introduction.md` apps table gain app **06 Card** (D1):

| Role | Port |
|---|---|
| card-web API | 20600 |
| card-game TCP | 20601 |
| card-game WebSocket `/ws` | 20602 |
| Redis | 20011 shared (`dcx-redis-container`, D13 ✅) |
| Unity client default / WebGL host | 20620 |
| web metrics / game metrics | 20630 / 20631 |

No legacy aliases, no host nginx stream: Docker publishes 20601/20602 directly (the 2303 double-listener leftover is
Crossle's and is not copied). Dokploy app `card-web` with target port 20600, built from the mono repo with build path
`web/` (compose at `docker/`); `dcm-docker/Grafana/prometheus.yml` gains `card-web host.docker.internal:20600` and
`card-game :20631`.

## 3. `card/card-backend/docker` (P2)

- Compose from `dcm-docker/crossle/` shape minus mysql/redis/generator: services `card-web-container`
  (build context `../web`, dockerfile `Docker/Main/Dockerfile`), `card-game-container` (context `../game-server`,
  dockerfile `Docker/Dockerfile` — shared with Crossle, it carries no port), networks `dcx-network` (external) +
  `dokploy-network`; logs `/opt/log/card/{web,game}`; `.env.local/.ubuntu`.
- `common-infra` gains `dcx-redis-container` (`${REDIS_PORT:-20011}:6379`, password, maxmemory) — D13.
- Process names of the source runs: `card/card-backend/Directory.Build.props` (repo root — outside `web/`, `game-server/` and the
  Docker contexts) sets `AssemblyName` `CardWeb` for `Main` and `CardGameServer` for `DcmGameServer`, so a local card process is
  never mistaken for Crossle's `DcmCoreWeb` / `DcmGameServer` (2026-10-27). Upstream `Main.csproj` keeps `DcmCoreWeb` unless a
  different name was pre-set; images and Dockerfiles unchanged.
- The web image's `Docker/Main/Dockerfile` hardcodes `ASPNETCORE_HTTP_PORTS` (20100) → per-app copy with 20600 (manifest
  excludes `web/Docker/`). Optional upstream tweak later: `ARG WEB_PORT` so the Dockerfile becomes shared too.

## 4. `card/card-backend/manager` — one manager for the backend and every card game (P2, D2)

≤150-line intro (intro rule). Mirror of `dcm-manager` scaled down:
```
card/card-backend/manager/
  introduction.md          # twin rule + manifests, repo layout (card-backend mono repo, <game>-client per game), ports,
                           # EGameId table, lobby-id registry (1xx Crossle, 2xx Batak: 201 tekli ihaleli…, 3xx Pişti, 4xx King),
                           # games table (Batak MVP, Pişti, King), D16 note, how we work with AI
  implementations/batak-mvp/{game_server_implementation.md, web_implementation.md, client_implementation.md, editor_guide.md, session_progress.md}
  implementations/<backend feature>/…       # work that is not one game (e.g. the second-game items)
  implementation-done/
  tools/bash/sync/{sync.sh, repos.sh}      # general-manager/bash/sync wrappers (dcm-web, dcm-game-server, dcm-client, dcm-docker, card-backend, batak-client)
  tools/bash/runner/{project.sh, logs.conf} # gm_infra common-infra; gm_wait mysql 20010; gm_service web card-web-container 20600, game card-game-container 20601
```
Rule written into the intro: **never edit a synced path on a twin** — change upstream, re-sync; a twin-side edit outside
the manifest is a bug (same sentence as the web ownership rule). `twin/sync-upstream.sh --check` is the first line of
every card build script.

## 5. Repo creation checklist (P2) — done 2026-10-27, see `session_progress.md` (P2 row) and `card/card-backend/manager/introduction.md`

1. Write ports (§2) → `PORTS.md`, intro apps table (`06 | Card`), H9 line "card = mono repo `card-backend` + one Unity repo per store app".
2. `mkdir card/card-backend/twin && cp general-manager/docs/twin/sync-upstream.sh card/card-backend/twin/`;
   `twin/sync-upstream.sh --init web game-server` (clean upstream `dev` — after the P1a/P1b commits); `git init`; CCG submodule
   added with the printed command at the lock's commit. Same for `card/batak-client` (`--init client`, manifest gets the
   `Assets/Batak` lines).
3. Per-app files: web (`AppModules` with `AddStatsModule<BatakStatsExtension>` + membership default Batak, `Configs/appsettings*.json`
   206xx + DB `card`, `launchSettings.json`, `Main.Test/appsettings.Test.json`, migrations `0000_create_database` + `0001_baseline_schema`
   (schema-only dump of the local `dcm` DB without routines/triggers — `Repeatable/` is shared and owns them) + seeds game 2, `Docker/`),
   game server (`AppBootstrapper` with `BatakGameModule`, `Resources/AppConfig*.json` 20601/20602/20631 + lobby 201 Batak tekli
   ihaleli 4 players, `launchSettings.json`, `GameModules/Batak` from the P1d stub shape, `Docker/docker-compose.yml`),
   client (`Assets/Resources/AppConfig*.json` GameId 2 + 206xx hosts, `ProjectSettings.asset` product "Batak" + bundle id,
   `EditorBuildSettings.asset`, Firebase files, `Assets/Batak` stub, keystore).
4. `docker/` compose; `common-infra` redis; Prometheus jobs; Dokploy app.
5. `manager/` intro + wrappers; lobby-id registry written.
6. Gate: `--check` green in both repos, `docker compose up` on 206xx, anonymous login → lobby list shows Batak, Grafana targets up.
