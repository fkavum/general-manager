# Upstream ownership — progress

Decided 2026-09-24: one upstream (dcm-web), one owner per module, promote instead of sibling-copy. Rules,
inventory, tooling design and open decisions in `overview.md`.

| Step | Status |
|---|---|
| Plan written (`overview.md`), inventory verified with `diff -rq` across the five web projects | ✅ 2026-09-24 |
| D1 (`dev`) and D2 (racer → standard layout) answered by owner | ✅ 2026-09-24 |
| D3–D7 answered by owner in chat (proposals accepted; D7 with an exit: leave both Community features app-owned if too app-specific) | ✅ 2026-09-24 |
| **P0** OWNERSHIP block in `dcm-web/Src/Docs/AI_RULES.md` (CRLF kept) + master `AI_RULES.web.md` + 4 byte-identical copies; `Src/Docs/NOT_USED_BY_CROSSLE.template.md`; `Tools/list-shared-modules.sh`; **hosted-module build mechanism** (`Main.csproj` `RemoveHostedModules`, new `Src/Main.Hosted` in `Dcm.sln`) after the owner's route-collision warning — probe-tested: marker folder absent from `DcmCoreWeb.dll`, present in `DcmCoreWeb.Hosted.dll`; `Dcm.sln` + `Main.Test` build 0 errors | ✅ 2026-09-24 |
| **P1** `sync-dcm-features.sh` + `sync-dcm-core.sh` masters in `hunter-manager/docs/web-modularization/` (generic bodies: auto-detect dcm-web at `../` or `../../`, `dev`-branch warning); copies in racer/hunter/flash/tapit `Tools/` — `FEATURES`: flash `Core/Storage` (identical, lock written), others empty until their phase; `--check` green in all four; racer moved to the standard layout (D2, details in overview §6), `dotnet build racer.sln` 0 errors | ✅ 2026-09-24 |
| **P2a** `Tools/sync-dcm-core.sh` run in all four → DLLs from dcm-web `542fc783` (dev); all four solutions build | ✅ 2026-09-24 |
| **P2b** D6 read: hunter's `Core/Storage` was simply older (2026-07-26, before dcm-web added `DownloadAsync`/`DeleteAsync`), not a customisation → `Core/Storage` added to hunter `FEATURES`, synced; hunter's test stub `StubStorage` (hunter-owned test code) got the two new members; `hunter-web.sln` builds | ✅ 2026-09-24 |
| **P2c** `Kvp` → racer: content was already identical except a "Ported from" header per file, the old subfolder layout, and racer carrying `KvpMapper` inside the feature while dcm-web kept it in `Core/Mapping/` (only Kvp uses it → portability violation). Fixed upstream: `dcm-web/Src/Main/Src/Features/Kvp/KvpMapper.cs` (moved, namespace unchanged); `Features/Kvp` added to racer `FEATURES`, synced flat, `AddKvpModule(EKvpClientMode.OfflineSync)` still registered, both `kvp_*` DbUp scripts reported present; `Dcm.sln` + `racer.sln` build; Kvp contracts unchanged so no client DTO regeneration needed | ✅ 2026-09-24 |
| **P2d** `Core/Database` reconciled upstream (D8 Console logging, D9 `AppDbContext` → `Main.Core.Database`, D10 `Mysql:ServerVersion` pin, default 8.0.36) → `Core/Database/Migration` + `Core/Database/MysqlEfModule.cs` synced to all four (single-file entries supported); documented in hunter/flash CONFIGURATION.md | ✅ 2026-09-24 |
| **P3** `Features/AuthOffline` + `Features/UserOffline` hosted in dcm-web (markers; excluded from `DcmCoreWeb.dll`, compiled by `Main.Hosted`). Base = flash's (typed responses, ApiExceptions, EF via `Set<T>()`, `ILogger`, CancellationToken) + racer's ban rule/`change_status`; routes = union (`POST api/login/{anonymous,refresh}`, `GET/PUT api/user/me`, `POST api/user/change_status`); `LoginResponse {UserId, Token, Name, Status}`. Prerequisite D11 (`Db` → `Main.Core.Database`, 47 files). racer: synced flat (old subfolder forks replaced), `Core/Middleware/UserAccessMiddleware.cs` reduced to the `Main.Utils.UserAccessPipeline` alias Kvp needs, `AppDbContext` DbSets retyped, `0006_alter_user_last_ip.sql`. flash: synced, `Core/Auth/` deleted, `DeckController` using switched, `Db.UserStatus` + `0006_create_user_status.sql`, baselines regenerated (+`change_status` route, +`UserStatusEntity`); **flash 92/92 tests pass against MySQL** (login/profile end-to-end). The racer Unity client has no login code yet → flash's Flutter client was the only shipped consumer; its wire shape (200 + camelCase) is what the module emits | ✅ 2026-09-24 |
| **P4** `Community` assessed (D7 exit taken): hunter's is product reviews/ratings/categories/trending over barcodes, flash's is a public deck browser (`decks`, `decks/{id}/preview`) — they share only the word; a generic `TargetType/TargetId` core would serve neither today. **Both stay app-owned, unchanged** (the mechanical ownership test — folder exists in dcm-web? no — already says so); noted in both manager intros | ✅ 2026-09-24 (no code) |
| **P5** `Core/Cors` hosted in dcm-web (marker): one config-driven module (`AllowedOrigins`, `AllowLocalhost`, `AllowCredentials`, `AllowAnyOrigin`) covering tapit's whitelist, hunter's localhost+credentials (SignalR) and flash's any-origin; synced to hunter/flash/tapit with appsettings adapted (tapit `PwaOrigins` → `AllowedOrigins`, flash `AddCorsModule(configuration)` + `AllowAnyOrigin`, hunter flags). `Core/Swagger/SwaggerBearerSecurity.cs` promoted as a single shared file (title parameter) → hunter ("ProductBook API"), tapit ("tapit-web API"). hunter 42/42, tapit 20/20 (incl. its CORS preflight tests) | ✅ 2026-09-24 |
| **P6** presign folded into `Core/Storage` upstream: `IFileStorageProvider.CreateUploadUrl/GetPublicUrl/IsOwnedUrl`, `FileStoragePresignResult`, `RustFsConfig.PublicBaseUrl/PresignExpiryMinutes`, `UseHttp` for http endpoints. tapit: `Core/StoragePresign/` deleted, `Core/Storage` synced, key scheme + content-type whitelist → `Features/Worker/WorkerPhotoService.cs` (+`WorkerModule`, contracts moved to `Features/Worker/Contracts/`), `TaskService` → `IFileStorageProvider.IsOwnedUrl`, config `Storage` → `FileStorage:RustFs`, `AWSSDK.S3` → 4.0.24.4, test factory env; flash `InMemoryFileStorage` + hunter `StubStorage` implement the new members. All three test suites green | ✅ 2026-09-24 |
| **P7** docs: OWNERSHIP/portability rules extended in both AI_RULES files (+4 copies), racer/flash/hunter/tapit/dcm manager intros, dcm-web + racer READMEs, flash/hunter/tapit CONFIGURATION.md, README template; folder moved to `implementation-done/` | ✅ 2026-09-24 |
| Gate for every phase: all touched solutions build, `dotnet test` where present, `sync-dcm-features.sh --check` passes in every downstream; nothing committed | ✅ builds: dcm-web (`Dcm.sln` incl. `Main.Hosted`), racer, hunter, flash, tapit; tests: flash 92/92, hunter 42/42, tapit 20/20 (Testcontainers MySQL); racer has no test project; dcm-web: see note below; `--check` green ×4; nothing committed or staged |

## Notes

- 2026-09-24 (owner request) `dcm-web/Tools/sync-libs.sh`: dcm-web's own pull-and-stamp script for the two DLLs it takes from
  dcm-generator (`CommonLib.dll`, `MysqlHelper.dll` → `Src/Lib/`, `Src/Lib/README.md` stamp with the dcm-generator commit,
  warns off `dev`). Chain is now dcm-generator → `sync-libs.sh` → dcm-web → `sync-dcm-core.sh` → downstreams. Ran it (DLLs
  refreshed from `1fc1a32`), dcm-web 152/152, then `sync-dcm-core.sh` in all four downstreams — all build.

- 2026-09-24 **live smoke tests** (each web project booted locally with `--env=local` against the shared `dcx-mysql-container`,
  Crossle against `dcm-mysql-container`; servers stopped afterwards, smoke rows deleted from racer/flash DBs):
  racer 20/20 (anonymous → same uid per device, refresh, `me` GET/PUT incl. 400s, Kvp set/get/get_all + 401, `change_status`
  401 without server token, ban → token "" + status 1, expired ban → auto-unban + DB row reset, `0006` applied, swagger has
  `/api/login/anonymous` once); flash 15/15 (same login/profile flow, community + deck/mine, ban rule, `user_status` created,
  CORS `*`); tapit 15/15 (admin + worker login, worker tasks, **presign via the shared provider**: http PUT URL with SigV4,
  photoUrl `…/tapit-photos/companies/{c}/workers/{w}/…jpg`, 400 on unsupported type, Swagger title + Bearer, CORS allow/deny,
  `/health/deep` Healthy); hunter 10/10 (on :20299 — :20200 is the running `hunter-web-container`; Swagger title + Bearer,
  CORS localhost + credentials, deny unknown, public community, 401 on products); dcm-web 7/7 (Crossle's own
  `/api/login/anonymous` answers with Crossle's body, swagger lists it exactly once and has no `/api/user/me` → hosted
  modules did not leak, DbMigrator Console lines present).

- 2026-09-24 dcm-web test suite: 41 of 153 fail **with and without this implementation** (baseline measured on a clean
  worktree of `dev` HEAD — see the line below for the numbers). Two pre-existing causes, both outside every file this plan
  touched: (1) DbUp on a fresh test database aborts with `Duplicate column name 'is_friendly'` (`0050_create_friends.sql`,
  commit `dea1f6d` "friendss"), which fails every `WebApplicationFactory` test (Auth email flows, IAP, Kvp, Level…);
  (2) `LeaderboardTest`/`Stats`/`WeeklyBonus`/`UserUnitOfWork` build their own `ServiceCollection` and register
  `DataRepository` without `ConfigurationService`. **Fixed on owner request 2026-09-24** (dcm-web, 6 files): `0050_create_friends.sql`'s
  `ALTER TABLE log_game ADD COLUMN is_friendly` wrapped in the repo's idempotent INFORMATION_SCHEMA procedure pattern
  (0039/0051 style — DbUp journals by name, so already-migrated DBs are untouched), and the five self-wired fixtures
  (Leaderboard, Level, Stats, WeeklyBonus, UserUnitOfWork) register `IConfiguration` + `ConfigurationService` the way
  `FriendsServiceTest` already did. Result: **152 passed, 0 failed, 1 skipped of 153**.
- Baseline run 2026-09-24 on a clean detached worktree of dcm-web `dev` HEAD `542fc78` (no plan changes): **Failed 41, Passed 111, Skipped 1 of 153** — identical to the run with the plan applied. The worktree was removed afterwards.

- 2026-09-24 (owner, mid-P1): "be careful while moving, endpoints should not collide, there are too many different auth
  features" → confirmed real (dcm `Auth` and racer/flash `AuthOffline` both map `api/login/anonymous` + `refresh`; dcm `User`
  and racer `UserOffline` both map `api/user/change_status`) and, worse, ASP.NET maps every controller in the assembly
  regardless of module registration. Fixed by making the marker file remove the folder from `DcmCoreWeb.dll`
  (overview §3.3) and by adding the route-ownership rule to both AI_RULES files.

- 2026-09-24: drift found while planning — `Community` (hunter≠flash), `AuthOffline`/`UserOffline` (racer≠flash),
  `Core/Cors` and `Core/Database` (hunter≠flash≠tapit) all share a name with no upstream; hunter edited synced
  `Core/Storage` locally (2 files); racer's `Kvp` predates dcm-web's interface refactor. Details in `overview.md` §2.1.
