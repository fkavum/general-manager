# card-platform — Batak as the first game on a Crossle twin backend (planned 2026-10-27, decisions 2026-10-27)

Owner's goal (2026-10-27): a new mobile game picked for organic downloads (research: `general-manager/docs/new-game-research/`,
Batak first, then Pişti and King). Build it as a **twin of Crossle**: same infra, byte-identical code for every shared
feature across web / game server / client / docker; only gameplay differs. One card web API + one card game server +
one card database serve **every** card game; users belong to one game each (`user_game`); one lobby per game *variant*.
Crossle stays the single upstream and sync scripts prove the twin. It doubles as the test of how well Crossle is modularized.

Paths relative to `/Users/fkavum/Documents/project/`. Per-project detail: `game_server_implementation.md`,
`web_implementation.md`, `client_implementation.md`, `infra_sync_implementation.md`. Progress: `session_progress.md`.

## 1. What the maps found (2026-10-27, read-only)

| Project | Twin-readiness today | Blockers for "identical except gameplay" |
|---|---|---|
| dcm-game-server | Engine interfaces (`IGameFactory`, `IGame`, `IGameModel`, `LobbyConfiguration`) are generic; `GameModules/CrossWord/` is the whole game (~2.9K lines). No sync scripts. | Lobby id **is** `ELanguage` (`UserModel.LobbyId => (int)Language`, `LobbyConfiguration` built from the enum); `Room.MaxPlayerCount = 2` hardcoded; game-end reward/stats/log/xp flow lives inside `CrossWord/Game.cs`; `IGame.GetSnapshot` returns the crossword `GameSnapshotResponse`; `AppBootstrapper` hardcodes `DcmGameModule`; `OnLanguageChangeRequestReceived` uses `CrossWord.LobbyDisplayNames`; unused `using CrossWord` in `Lobby.cs`. The Crossle client never reads the numeric `LobbyId` (checked 2026-10-27), so lobby ids are free to change server-side. |
| dcm-web | 27 features, module pattern, Resources SQL rule, downstream sync scripts (feature-list style, racer). | No table has a game dimension (not needed with the membership model); HttpShared export is stale (Bot, Medal, Season missing) and the full regen is destructive; request DTOs partly hand-written in CCG; `user_linked_accounts` is unique per `(provider, social_id)`; anonymous login keys on the client's `DeviceId`. |
| dcm-client | `GameComponents/` is the reuse layer (369 cs); CI/CD builders exist with `[CliCommand]` + global `iOSBuilder.Build` etc. | The generic app shell (bootstrap, network client, scene loader, login/post-login tasks, inventory service, user model) **lives inside `Assets/DontCrossMe/Scripts/Core` + `GamePlay`**; 68 GameComponents files `using DontCrossMe.Scripts.*`; no first-party asmdefs; all builders + CLI wrappers are in `DontCrossMe/Editor`; the message-handler table in `AppBootstrapper` mixes generic and crossword handlers; 28 of ~55 Addressables point into DontCrossMe. |
| dcm-docker / infra | Port scheme, shared MySQL on `dcx-network`, per-repo Dockerfiles, Dokploy. Next free app = **06**. | Crossle's compose/deploy scripts carry legacy leftovers (root Dockerfile paths, 2303 published by both docker and host nginx); no shared Redis in `common-infra`; no "add an app" checklist in `PORTS.md`. |
| CommonClientGame (CCG) | One submodule for client + server; MessageId 1–15 generic, 100–102 crossword. | Crossword DTOs sit next to generic ones (`Dtos/Socket/Game/Cross*`, `GeneratorShared/`); `GameConfig.cs` mixes generic rewards with word amounts. |

Related planned work this plan depends on or absorbs: `implementations/sharing-hygiene/` (H1 dirty-tree refusal, **H2
HttpShared direct-to-target**, H3 masters to `general-manager/docs/web/`, H9 topology rule), `implementations/unity-core/`
(parked package extraction — this plan moves the generic Unity core into `GameComponents/Core` first; the package can be cut
from there later).

## 2. Target shape

```
Crossle (upstream)                          Card (twin, app 06, folder card/)
dcm-web ───────── twin/sync-upstream.sh ──► card/card-backend/web           (one process, DB `card`, every card game)
dcm-game-server ─ twin/sync-upstream.sh ──► card/card-backend/game-server   (one process; lobbies per game variant)
dcm-docker/crossle* ─ copy+ports ─────────► card/card-backend/docker
                                            card/card-backend/manager       (the one card manager)
                                            card/card-backend/twin/         (sync script, web + game-server manifests, lock)
dcm-client ────── twin/sync-upstream.sh ──► card/batak-client               (own repo; Assets/Batak instead of Assets/DontCrossMe)
                                            card/pisti-client, card/king-client … (later, same rule)
CommonClientGame (same submodule, same commit in every consumer; per-game DTO folders)
```

- **Shared = everything the exclude manifest does not list.** Each twin repo has `twin/sync-upstream.sh` (master
  `general-manager/docs/twin/`; rsync `--delete` from the upstream working tree, manifest `twin/<kind>.exclude`, lock
  `twin/upstream.lock.md`, `--check` gate, `--init`; submodules pinned by git, not copied). The manifest *is* the definition
  of "game-specific"; the masters live next to the script. Built and dry-run 2026-10-27 (P1d, `infra_sync_implementation.md` §1).
- **Game membership.** No `game_id` column on any existing table. New module `Features/GameMembership` owns
  `user_game (uid PK, game_id, created_at)`: **one uid belongs to exactly one game, users never collide** (D5). Users partition
  themselves: a Batak uid's rows in statistics, inventory, quests, medals, friends are Batak rows by construction.
  `EGameId { None = 0, Crossle = 1, Batak = 2, Pisti = 3, King = 4 }` (order = wire). The user aggregate (`api/user/get` →
  `UserResponse`) carries `GameId`; the game server reads it to place the user. First login of a new uid: the socket `LoginRequest`
  gains a trailing `GameId` int (Crossle sends 0 → language lobbies), the card server records it once via server-tier
  `POST api/game_membership/set` (never overwrites). "Which users belong to which game" = one table.
- **No collisions (D5).** Anonymous login: card clients send `deviceId + ":" + gameId` as `DeviceId` (client-side only).
  Provider logins (Google/Apple/Facebook/Email) are unique per `(provider, social_id)` today, so the same Google account in two
  card apps would resolve to one uid — **the second-game item D16** scopes the lookup per game through `user_game` (no new
  column; join + widened unique key + the game in the login body). Not needed while Batak is the only card game.
- **Lobby = game variant, lobby-id ranges reserved per game (D6).** `lobbyId = gameId × 100 + localLobbyId` (1…99), so every
  game owns 100 lobby ids like an app owns 100 ports. Crossle (game 1): `100 + ELanguage` (en = 101, tr = 102 … — ids change on
  the wire, the client does not read them). Batak (game 2): 201 tekli ihaleli (MVP), 202 eşli, 203 koz maça later; Pişti 301…;
  King 401…. `LobbyDefinition { LobbyId, GameId, Variant, Factory, MaxPlayers, DisplayName, Language? }` from server config.
  A user may only switch between lobbies of **their own game** (membership check); default lobby of a game = `gameId×100+1`.
  The registry of lobby ids lives in `card-manager/introduction.md` (and Crossle's in dcm-manager) — same discipline as `PORTS.md`.
- **Client twin (D9/D11).** Generic code still inside `DontCrossMe` moves to **`Assets/GameComponents/`** (app shell → `GameComponents/Core`,
  the client-related common scripts), not to a new folder. After that the game folder is the only difference: `Assets/DontCrossMe/`
  (Crossle) / `Assets/Batak/` (batak-client). **One client repo per store app** (`batak-client`, later `pisti-client`), each a twin
  of dcm-client. Card-game UI shared by Batak/Pişti/King (deck, hand fan, trick area, seats, bid panel) becomes a GameComponent
  **`GameComponents/CardKit/`** owned upstream in dcm-client even though Crossle never uses it — the Unity twin of the web's
  "hosted, not wired" rule. Builders and CLI wrappers move to `Assets/Editor/Dcx/{Build,Cli}` (global class names kept so
  `bash-scripts` keep working); game-specific feature builders stay in the game folder.
- **The game server owns the wire (CCG split, 2026-10-27).** Socket DTOs live in `Contracts/` folders of dcm-game-server
  (`Engine/Contracts` = `MessageId`, `UserDto`…; `Engine/{Lobby,GameEnd}/Contracts`; `Features/<X>/Contracts`;
  `GameModules/<G>/Contracts` — Batak's DTOs go into `GameModules/Batak/Contracts`, a twin-only path) and are exported by
  `Tools/generate-socket-shared.sh` into the client's `Assets/SharedData/SocketShared/`. MessageId blocks 100–199 CrossWord,
  500–599 Batak, 600–699 Pişti, 700–799 King (the enum is the cross-game registry, kept upstream). CCG itself is library only.
- **HttpShared complete.** Every endpoint's request + response DTO **and its client sender** (`H*Request : WebRequestBase`) lives in
  `Features/<X>/Contracts` on dcm-web (`WebRequestBase`, `HttpConstants` in `HttpShared/Core`); the generator writes
  `SharedData/HttpShared/<Feature>/{Request,Response,Data}` into client and game server (`.meta`-safe, sharing-hygiene H2).
- **Stats seam (D12).** `Features/Stats` gains `IStatsExtension` (no-op default; per-app class under `Features/Stats/Extensions/`,
  the one per-app web file besides `AppModules` and seeds). No table split now; `user_statistics` columns are reused as-is.
- **Twin DB (D15).** `card-web` migrations: `0000_create_database.sql` (`card`), `0001_baseline_schema.sql` (schema-only dump of
  the local `dcm` DB at the P2 sync commit), then seeds for game 2. **dcm-web's own migration scripts are not touched**; resetting /
  centralising them is a later step after dcm-web's next live release.

## 3. Decisions (Fatih, 2026-10-27)

| # | Question | Decision |
|---|---|---|
| D1 | App number / ports | ✅ **06**: web 20600, game TCP 20601, WS 20602, client 20620, web metrics 20630, game metrics 20631; Redis shared 20011 (D13); DB `card` in `dcx-mysql-container` (20010), created by card-web migration 0000. Written to `PORTS.md` + intro apps table at the start of P2. |
| D2 | Repo topology | ✅ (revised by the owner 2026-10-27) Folder `card/` holds **one backend mono repo `card/card-backend`** = `web/` (dcm-web twin) + `game-server/` (dcm-game-server twin) + `docker/` (compose, env) + `manager/` (the one card manager: twin rules, registries, `implementations/<game>-mvp/`) + `twin/` (sync tooling), and **one client repo per store app** next to it (`card/batak-client`, later `card/pisti-client`; names never generic). Matches sharing-hygiene H9/D5 (mono repo for new apps); only the Unity client stays a separate repo. |
| D3 | Twin mechanism | ✅ Full-tree rsync with an exclude manifest; lock + `--check`; dirty-upstream refusal (H1). |
| D4 | Game id on the wire | ✅ `EGameId` enum (order = wire); `LoginRequest` trailing `GameId` (0 from Crossle); `UserResponse.GameId`; no HTTP header. |
| D5 | Account ↔ game | ✅ `user_game` mapping, one uid = one game, **users never collide**: anonymous `DeviceId` = `deviceId:gameId` on card clients; provider-login scoping = D16 (second game). |
| D6 | Lobbies | ✅ One lobby per game **variant**; `lobbyId = gameId×100 + localLobbyId`, 100 ids reserved per game; MVP = Batak **tekli ihaleli** (201); other variants later as more lobbies. |
| D7 | Room size | ✅ `MaxPlayers` per lobby definition (Crossle 2, Batak 4); bot fill of **all** empty seats after the grace period. |
| D8 | Game-end flow | ✅ Extracted into `Engine/GameEnd/` (`GameEndReport` + `GameEndReporter`); the game keeps its own end rules and hands a report to the engine, `IGame` unchanged (implemented P1a, 2026-10-27). Smoke + LoadBot gate pending. |
| D9 | Client generic-core folder | ✅ Generic code left in `DontCrossMe` moves into `GameComponents/` (`GameComponents/Core` for the app shell and client-common scripts). No new top-level folder. AI_RULES line "DontCrossMe/Scripts/Core must not move into GameComponents/Core" is replaced. |
| D10 | Client game registration | ✅ `IClientGameModule { Register(); Handlers; GameScene; LobbyPages }`; generic `AppBootstrapper` + one game module per project. |
| D11 | Client repo per store app | ✅ Separate repos (`batak-client`, `pisti-client` …), each a dcm-client twin with one game folder (owner's D2 note; recommendation accepted 2026-10-27). Shared card UI generalised into `GameComponents/CardKit` upstream. A future bundle app is a twin with several game folders. |
| D12 | Stats shape | ✅ Keep `user_statistics` as-is; add the `IStatsExtension` seam now (empty for Crossle and Batak), per-app class excluded from sync. |
| D13 | Redis | ✅ `dcx-redis-container` 20011 in `common-infra`, DB index per app; Crossle keeps `dcm-redis-container` until its own move. |
| D14 | Release coordination | ✅ Not a blocker: P1c proceeds on `dev` while Crossle polishes 1.0.9; after 1.0.9 ships, every twin re-syncs to make the card release-ready. |
| D15 | Twin DB baseline | ✅ `0001_baseline_schema.sql` + seeds; dcm-web migrations untouched; centralise/reset later after dcm-web's next live release. |
| D16 | Provider-login scoping (second game) | ✅ (owner 2026-10-27) **No new column**: a link's game is known from its uid via `user_game`. What changes when the second game ships: the provider lookup becomes "the link whose uid belongs to the requesting game" (join on `user_game`), the unique key `(provider, social_id)` widens to `(provider, social_id, uid)`, and provider login/attach bodies carry `GameId` (absent → default 1). Auth module change, Crossle-safe. Not the MVP. |

## 4. Phases and gates

| Phase | Scope | Gate (what proves it) |
|---|---|---|
| **P1a server** ✅ 2026-10-27 | Lobby definitions with the id rule + `GameId` + `Variant`, `ILobbyResolver` (by language / by membership), own-game check on lobby switch, `MaxPlayers`, bot fill N seats, game-end extraction (D8), generic snapshot envelope, `AppBootstrapper` takes `IGameModuleRegistration`, CrossWord namespace out of engine/features, `LoginRequest.GameId`, MessageId blocks, CCG per-game DTO folders. | `Tools/run-tests.sh` ≥ today (429 + 3 known), `run-smoke.sh` green, LoadBot bench within noise, Crossle client plays unchanged (lobby ids 101/102 invisible to it). |
| **P1b web** ✅ 2026-10-27 | `Features/GameMembership` (table, Resources SQL, server-tier `set`/`get`, `GameId` on the user aggregate); stats extension on the observer seam; Contracts completed for every endpoint; generator direct-to-target (H2) and regen into both CCG trees. | ✅ `dotnet test` 268/0 incl. `LoginWireContractTest` + `UserWireContractTest`; 0068 applied locally; game server builds + tests unchanged against the regenerated CCG; Unity client compile 🔲 (no file imports the new namespaces — low risk). |
| **P1c client** | Generic shell → `GameComponents/Core` (+ other generic scripts → their `GameComponents/<System>`), GameComponents → zero `using DontCrossMe`, `IClientGameModule`, builders/CLI → `Assets/Editor/Dcx`, anonymous `DeviceId` suffix hook (`AppConfig.GameId`, Crossle = no suffix), Addressables groups split (shared vs game). Runs on `dev` in parallel with 1.0.9 polish (D14). | iOS/Android/WebGL builds via the existing `bash-scripts` chains; `unity command *_validate` all OK; Play-Mode smoke login → lobby → game → end; grep gate `GameComponents` has zero `using DontCrossMe`. |
| **P1d sync tooling** ✅ 2026-10-27 | `general-manager/docs/twin/`: `sync-upstream.sh` + `web.exclude` / `game-server.exclude` / `client.exclude` + README; H1 dirty refusal folded in; S9 upstream (engine tests free of CrossWord). | ✅ Dry run in a scratch `card/card-backend` + `card/batak-client`: web twin builds `Dcm.sln` (0 errors) with a stub `AppModules`/`CardStatsExtension`; game-server twin builds with `GameModules/Stub`, its tests 125 pass / 3 known; client twin synced (1.3 GB, every per-app path absent — compile waits for P1c + Unity); `--check` green ×3 (only "submodule missing", expected without git); stray / edited / protected file semantics proven. |
| **P2 boilerplate** | Ports + apps table + lobby-id registry; `card/` repos created **by `--init`** plus the per-app files (AppModules, appsettings 206xx, Docker, migrations 0000/0001 baseline + seeds game 2, `GameModules/Batak` stub, `Assets/Batak` stub, product/bundle settings); `card-docker` compose; `common-infra` Redis; `card-manager/introduction.md` (+ runner/sync wrappers); Dokploy app; Prometheus jobs. | `sync-upstream.sh --check` green ×3; `docker compose up` locally on 206xx; anonymous login from batak-client → membership row game 2 → lobby 201; intro ≤150 lines; Grafana sees card-web/card-game. |
| **P3 MVP Batak** | Rules engine for tekli ihaleli, 4-seat room, turn timer, rule-based bot AI, reconnect/snapshot, result → stats/leaderboard/medals, `CardKit` component upstream + Batak table UI + lobby page, store listing assets. | 4-player online game with 3 pool bots end-to-end on local docker; LoadBot persona `BatakLoop`; Play-Mode smoke; `run-smoke.sh` on the card server; sync `--check` still green after the MVP. |
| **P4 release-ready** (after Crossle 1.0.9) | Re-sync all twins to the 1.0.9 upstream; D16 only if Pişti is next. | `--check` green ×3 against the 1.0.9 commit; MVP smoke repeated. |

Order: P1a → P1b → P1d → P2 (stubs) ‖ P1c → P3 → P4. Rough effort: P1a 3 d, P1b 2 d, P1c 7–10 d, P1d 2 d, P2 3 d, P3 12–15 d.

## 5. Risks

- **The client extraction is the real test of modularization** and touches the live game broadly. Mitigation: pure move, no
  behaviour change, gated by builds + smoke; runs on `dev` next to 1.0.9 art work (file moves vs asset edits rarely conflict).
- `rsync --delete` twins are unforgiving: a twin-side edit outside the manifest is wiped on the next sync. Mitigation: `--check` in
  the build gate; manifest reviewed in every card implementation plan; the rule written in both card intros.
- Lobby ids change for Crossle (1/2 → 101/102). Verified the client ignores the value; LoadBot and tests that assert lobby ids are updated in P1a.
- One uid = one game means a Google account used in two card apps collides until D16 ships. Mitigation: D16 scheduled with Pişti; documented in `card-manager/introduction.md`.
- A 4-seat table needs 3 bots per lonely human: pool capacity (100 on prod) must be sized for `3 × concurrent lonely rooms`.
