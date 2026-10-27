# card-platform — dcm-web (upstream, P1b) and card-web (twin, P2)

Paths relative to `dcm-web/Src/Main/Src/` unless noted. Map source: read-only scan 2026-10-27.

## 1. Upstream changes (P1b) — **implemented 2026-10-27 (uncommitted, `dev`)**, owner's model: a mapping table, no feature touched

Tests: `dotnet test Src/Main.Test` 268 pass / 0 fail / 1 skipped (269; before: 264 + the same skip). New tests:
`Features/GameMembership/GameMembershipServiceTest` (DB-backed), `GameMembershipWireTest` (server-tier set/get + the aggregate).
Live: dcm-web restarted from source on the local stack → DbUp applied **0068**; `POST api/game_membership/set` → `"Success"`,
`GET api/game_membership/{uid}` and `api/user/get` → `UserCoreData.GameId`. Two test-infra fixes rode along: `Src/Main/Resources/Queries/Drop/drop_all.sql`
gains `user_game` (the test reset did not know the table), `PublicProfileMedalsTest` passes the new `UserService` dependency.

| # | Change | Where |
|---|---|---|
| W1 ✅ | `HttpShared/Common/EGameId.cs` (identical to the CCG hand copy, order = wire). | `HttpShared/Common` |
| W2 ✅ | `Features/GameMembership`: `user_game (uid PK, game_id tinyint, create_date)` + `Resources/game_membership.sql`; `Db.UserGame`; `IGameMembershipRepository` / `GameMembershipRepository` (MySqlExecutor, `INSERT IGNORE` = set-if-absent); `GameMembershipService` (`GetAsync` → default when no row, `SetIfAbsentAsync` refuses `None`); `GameMembershipOptions { DefaultGameId = Crossle }`; `GameMembershipController` `api/game_membership`: server-tier `POST set` (body `Contracts/GameMembershipSetRequestBody {Uid, GameId}`, answers `"Success"` like set_language, idempotent) and `GET {uid}` (`Contracts/GameMembershipData`); `AddGameMembershipModule(options)`; migration `0068_create_user_game.sql`; endpoint inventory in `Src/Main/ReadMe.md`. | `Features/GameMembership/*`, `Core/Database/DbConstants.cs`, `Resources/Migrations/Versioned/0068_create_user_game.sql`, `Src/Main/ReadMe.md` |
| W3 ✅ | `UserCoreData.GameId` (additive); Crossle's `UserService.GetUserAggregate` fills it from `GameMembershipService` (no row → the app default, Crossle). `AppModules`: `AddGameMembershipModule(o => o.DefaultGameId = EGameId.Crossle)`. | `Features/User/{Contracts/UserCoreData,UserService}.cs`, `BootStrapper/AppModules.cs` |
| W4 ✅ | **Contracts complete + generator direct-to-target (sharing-hygiene H2).** `Tools/generate-http-shared.sh` rewritten: exports every `Features/*/Contracts` + `HttpShared/Common` **straight into both CCG checkouts** (`client`, `server`, default `all`), leaves matching files untouched, writes `.meta` files with GUIDs shared by both checkouts, deletes orphans (+ `.meta`, + empty folders), `--check` mode = drift gate; the root `../HttpShared` intermediate is no longer produced (the stale folder is still on disk — sharing-hygiene D2 decides its deletion). Run 2026-10-27: 110 changes per checkout — the provider folders (`AuthApple/Email/Facebook/Firebase/Google`, moved out of `Auth/`, content identical), `AuthCrossle/` (Crossle's `Main.Dtos` `AnonymousRequestBody`/`LoginResponse`, exactly what `Auth/` held before), `Auth/` now = the shared base DTOs (`Main.Features.Auth.Contracts`), `Identity/` (14 files), `GameMembership/`, `User/UserAccountData`, orphan `UserLoginEnrichmentData` removed. Checked: no Unity client file imports the new namespaces, every type the client uses keeps its namespace; dcm-game-server builds and its tests are unchanged (443/3). The 57 hand-written `Dtos/Http/Requests/*` in CCG are the request *senders* (`WebRequestBase` wrappers), not DTOs — they stay hand-written; every DTO they carry is now generated. | `Tools/generate-http-shared.sh`, both CCG `HttpShared/` trees |
| W5 ✅ | Twin-DB baseline per D15 is a P2 step (dump at the sync commit); nothing to do upstream. | — |
| W6 ✅ | `Features/Stats`: `AddStatsModule<TExtension>()` registers the app's extension on the existing `IStatsUpdateObserver` seam (no new interface); `Features/Stats/Extensions/CrossleStatsExtension` (empty) wired in `AppModules` — the one per-app file of the Stats module. | `Features/Stats/{StatsModule.cs,Extensions/CrossleStatsExtension.cs}`, `BootStrapper/AppModules.cs` |
| W7 ✅ | Tests as above. No route baseline exists in dcm-web (only downstreams carry `Baselines/routes.txt`). | `Src/Main.Test` |

Deferred to the second card game (recorded in `overview.md` §2/D16): **provider-login scoping without a new column** (lookup
joins `user_game` for the requesting game, unique key → `(provider, social_id, uid)`, `GameId` in provider login/attach bodies);
leaderboard join on `user_game` for the requester's game + per-game season schedule key; `data_min_versions` / `data_supported_logins`
per app; bot rows in `user_game`.

## 2. Twin exclude manifest (first cut, `card-web/Tools/upstream-exclude.txt`)

```
Src/Main/Src/BootStrapper/AppModules.cs            # wiring: no PuzzleProgress; GameMembership default = Batak; Stats extension = BatakStatsExtension
Src/Main/Src/Features/Stats/Extensions/**           # CrossleStatsExtension upstream / BatakStatsExtension twin (D12)
Src/Main/Resources/Configs/appsettings*.json        # port 20600, DB card on dcx-mysql-container:3306, redis 20011, JWT
Src/Main/Resources/Migrations/**                    # own numbering: 0000 create_database, 0001.. = copies of Resources/*.sql, seeds game 2
Src/Main/Src/Features/PuzzleProgress/**             # Crossle only (not wired on the twin; kept out to avoid dead routes)
Docker/**  Tools/upstream-exclude.txt  Tools/upstream.lock.md
Src/Main.Test/Baselines/**                          # route/EF baselines are per app
```
Synced byte-for-byte: `Dcm.Core` source (project reference, as in dcm-web), `Main.Hosted`, every other feature, `Core/*`,
`Src/Docs/*`, csproj/sln. Open point: assembly name `DcmCoreWeb` kept on the twin (D3).

## 3. card-web per-app files (P2)

- `AppModules.cs`: same order as dcm-web minus `PuzzleProgress`; `AddGameMembershipModule(o => o.DefaultGameId = EGameId.Batak)`;
  `AddStatsModule(o => o.Extension<BatakStatsExtension>())` (empty class); Identity policy identical (Tr/En, 3–10 unique names).
  `user_statistics` columns are reused as-is (Batak rows only).
- Migrations: `0000_create_database.sql` (`card`), `0001_baseline_schema.sql` = `mysqldump --no-data --routines --triggers dcm`
  taken at the P2 sync commit (D15; dcm-web's own `Versioned/` scripts are never touched), then `0002+` seeds for game 2
  (data_item: item 4 stays "trophy" — same meaning for Batak; data_reward, data_min_versions, data_supported_logins, quest catalog,
  medal item rows 70001+ reused as generic win/game-count medals). Lobby list is server config.
- `appsettings.local/docker/prod_docker.json`: `Urls` 20600, Mysql `dcx-mysql-container`, Redis `dcx-redis-container` db 6.
- Docker: `Docker/Main/{Dockerfile (ASPNETCORE_HTTP_PORTS=20600), docker-compose.yml (card-web-container, dcx-network + dokploy-network), .env.*}`.
