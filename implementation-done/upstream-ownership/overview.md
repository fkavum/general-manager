# Upstream ownership — one upstream, one owner per module

Decided 2026-09-24. Applies to every .NET web project: `dcm-web`, `racer-web`, `testapp/hunter-web`,
`flash/flash-web`, `tapit/tapit-web`, and every future one. Paths relative to `/Users/fkavum/Documents/project/`.

## 1. Decision

There is exactly one upstream: **dcm-web**. No tiers (no "racer upstreams offline modules", no "hunter upstreams app
modules"). The tiered model was rejected because the case it can't answer — a module needed by two non-Crossle
projects — is already the common case (`Community`: hunter+flash, `AuthOffline`/`UserOffline`: racer+flash,
`Core/Cors`+`Core/Database`: hunter+flash+tapit), and every one of those has already forked under the same name
because nobody owned it. Extracting a separate shared repo was considered and deferred (five-repo migration for a
problem one rule solves; revisit if dcm-web's release cadence starts blocking the others).

### Rules (go verbatim into `dcm-web/Src/Docs/AI_RULES.md` and the generic `AI_RULES.web.md`)

```
OWNERSHIP (one upstream, one owner per module)
- Used by exactly one project → that project owns it, plain name, lives only there.
- Used by two or more projects → dcm-web owns it, under Src/Main/Src/Features/<Name> or Src/Main/Src/Core/<Name>,
  even if Crossle does not register it. Such a module carries a NOT_USED_BY_CROSSLE.md in its folder and is not
  wired in AppModules.cs. The marker also removes the folder from DcmCoreWeb.dll (Main.csproj target
  RemoveHostedModules); Src/Main.Hosted compiles it instead — see §3.3 for why this is mandatory.
- Routes are client contracts and must never collide: hosted modules are disjoint from Crossle's routes and from each
  other; a promoted module serves the UNION of routes the shipped clients already call; downstream, Baselines/routes.txt
  is the gate after every sync (owner warning 2026-09-24: "too many different auth features").
- Never copy sibling → sibling. When a second project needs a module another app built, PROMOTE it: move it to
  dcm-web (generalise there, pick the better of the existing implementations), then both projects sync from dcm-web.
  Promotion is the one moment a shared module may be redesigned.
- Ownership test is mechanical: does the folder exist in dcm-web? Yes → synced (byte-identical, Tools/sync-dcm-features.sh,
  improve upstream first). No → project-owned; the <DcmName><Purpose> fork rule applies as before.
- Variants live upstream too: Auth (Crossle, online) and AuthOffline (shared, offline) are sibling modules in dcm-web.
  The suffix describes the flavour; "is it a fork?" is answered only by the folder-exists-in-dcm-web check.
- A synced module is edited only in dcm-web. A downstream diff against dcm-web is a bug, not a customisation
  (sync-dcm-features.sh --check must pass before a downstream build is considered green).
```

### `NOT_USED_BY_CROSSLE.md` (owner request 2026-09-24)

Every dcm-web module that Crossle does not register gets this file in its folder, exact text:

```markdown
# Not used by Crossle

Its not used by crossle. This module lives in dcm-web only because dcm-web is the upstream for every web project.
It is NOT registered in `Src/Main/Src/BootStrapper/AppModules.cs`.

Used by: <project list, e.g. flash-web, hunter-web>
Improve it here, then run `Tools/sync-dcm-features.sh` in each project listed above.
```

`sync-dcm-features.sh` excludes this file when copying (downstream folders never carry it).

## 2. Inventory (state on 2026-09-24, verified by `diff -rq`)

Legend: **owner** = who the rule assigns; **state** = what the repos actually contain; **action** = what this
implementation does.

### 2.1 Shared modules → owner dcm-web

| Module | Copies today | State | Crossle uses it? | Action |
|---|---|---|---|---|
| `Dcm.Core` (DLL) | dcm-web src; hunter, flash, tapit `Src/Lib/` via `sync-dcm-core.sh`; racer `lib/` by hand | racer has no sync script (racer-manager: "planned, not written") | yes | add `racer-web/Tools/sync-dcm-core.sh`; re-sync all four |
| `Features/Kvp` | dcm-web, racer-web | **drifted** — racer has the old `Endpoints/`/`Entities/` layout, dcm moved to `IKvp*` interfaces | yes | re-sync racer from dcm-web; racer's `AddKvpModule()` wiring re-checked |
| `Core/Storage` (FileStorage) | dcm-web, flash, hunter | dcm↔flash identical; hunter `IFileStorageProvider.cs` + `RustFsStorageProvider.cs` differ | yes | diff hunter's two files: if an improvement → apply in dcm-web then sync everywhere; if hunter-only → move into a hunter-owned wrapper and re-sync the module |
| `Core/Database/Migration` (`DbMigrator`, `DbMigrationModule`) | dcm, hunter, flash, tapit, racer | `DbMigrator.cs` differs dcm↔hunter and dcm↔flash | yes | reconcile in dcm-web, sync to all |
| `Core/Database/MysqlEfModule.cs`, `DbConstants.cs` | all five | differ across projects | yes | `MysqlEfModule` → shared, sync. `DbConstants` + `AppDbContext` are **per-app by nature** (DbSets, table names) → stay project-owned; document the split. hunter's `UtcDateTimeConverter.cs` → promote into `Core/Database` if generic |
| `Features/Community` | hunter, flash | **forked under the same name** — every file differs; flash adds `CommunityDeckEntity`, `CommunitySort`, page/preview responses; hunter adds `SubmitRatingBody` | no | **promote**: design one generic community/rating module in dcm-web (target type is a parameter, not a deck/product); `NOT_USED_BY_CROSSLE.md`; both re-sync. Base: flash's (paging + sort), fold hunter's rating body in |
| `Features/AuthOffline` + `Features/UserOffline` | racer, flash | **forked under the same name** — unrelated shapes (racer: `Anon/`, `Core/`, `Endpoints/`, `Entities/`, `Repositories/`, `UserUnitOfWork`; flash: flat files, `JwtService`, `LinkedAccountEntity/Repository`, `LoginController`) | no | **promote**: one implementation in dcm-web (base: flash's — flat layout matches the `Features/Report/` reference shape and already has JWT + linked accounts; carry racer's `EUserStatus`/`UserStatusData` over); `NOT_USED_BY_CROSSLE.md`; racer + flash re-sync |
| `Core/Cors` | hunter, flash, tapit | three versions; tapit adds `CorsConfig.cs` | no (dcm has no Core/Cors) | **promote** tapit's config-driven version to dcm-web; `NOT_USED_BY_CROSSLE.md` unless Crossle adopts it (decision D3) |
| `Core/Swagger/SwaggerBearerSecurity.cs` | hunter, tapit | differ | no (dcm has `SwaggerCustomHeader.cs` only) | **promote** one version into dcm-web `Core/Swagger/` next to `SwaggerCustomHeader.cs`; mark not-used |
| `Features/TestFixtures` | hunter, tapit | different purpose (hunter: golden-products controller; tapit: `DbSeeder`) | no | **not** the same module — rename to disambiguate (`TestFixturesProducts` in hunter, keep tapit's as the generic candidate); promote tapit's only if a third project needs a seeder |
| Storage, second design: tapit `Core/StoragePresign` | tapit | presign-URL flow vs dcm `FileStorage` upload/download | — | decision D4: fold presign into `FileStorage` upstream as `IFileStorageProvider.PresignAsync(...)`, then tapit syncs `Core/Storage` and drops `StoragePresign` |

### 2.2 Crossle-only today (owner dcm-web, no action beyond the rule)

`Features/`: Auth, Data, Friends, GameLog, Iap, Inventory, Leaderboard, Legal, Level, Quest, Report, Reward, Skins,
Stats, Support, Test, User, WeeklyBonus. `Core/`: Common, Configuration, Mapping, Middleware, Redis, Swagger
(`SwaggerCustomHeader`). `HttpShared/`. These become synced the moment a second project copies one — via the
script, never by hand.

### 2.3 Project-owned (plain name or `<DcmName><Purpose>` fork, stays put)

| Project | Owned modules |
|---|---|
| hunter-web | `Features/`: Products, GlobalProducts, ProductImages, Shelves, ShoppingLists, FriendsSignalR (fork), UserFirebase (fork); `Core/`: FirebaseAuth, OpenFoodFacts, Realtime, Common |
| flash-web | `Features/Deck`; `Core/Auth` (`UserAccessMiddleware`) |
| tapit-web | `Features/`: Tasks, Admin, AuthMultiTenant (fork), Worker; `Core/Extensions` |
| racer-web | nothing web-side — all three of its modules are shared candidates (Kvp synced, AuthOffline/UserOffline promoted) |

## 3. Tooling

### 3.1 `Tools/sync-dcm-core.sh` — already exists in hunter/flash/tapit, add to racer

Same script, only the project name differs; racer's DLLs move from `lib/` to `Src/Lib/` as part of its layout
migration (D2) so the destination is uniform too (`<HintPath>` in the csproj updated). Master copy for new projects:
`testapp/hunter-manager/docs/web-modularization/sync-dcm-core.sh` (add it there; the generic AI rules already live in
that folder).

### 3.2 `Tools/sync-dcm-features.sh` — new, one per downstream project

Owner request: a bash script with an array of features defined inside; it copies the listed folders from dcm-web.

```bash
#!/usr/bin/env bash
# Syncs the shared modules this project takes from dcm-web. dcm-web is the only upstream; a synced folder is
# byte-identical to dcm-web's and is never edited here. Add/remove entries in FEATURES only.
set -euo pipefail

# Paths relative to dcm-web/Src/Main/Src/ and to this project's SRC_ROOT.
FEATURES=(
  "Features/Kvp"
  "Core/Storage"
  "Core/Database/Migration"
)

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DCM_WEB="${DCM_WEB:-$ROOT/../../dcm-web}"      # racer-web: $ROOT/../dcm-web
DCM_SRC="$DCM_WEB/Src/Main/Src"
SRC_ROOT="$ROOT/Src/Main/Src"                   # identical in every project (racer moves to this layout in P1, D2)
RECORD="$ROOT/Tools/dcm-features.lock.md"
CHECK=0; [[ "${1:-}" == "--check" ]] && CHECK=1
```

Behaviour per entry:

1. `--check` mode: `diff -rq --exclude=NOT_USED_BY_CROSSLE.md "$DCM_SRC/$f" "$SRC_ROOT/$f"`; any difference → print it,
   exit 1 at the end. This is the "downstream diff is a bug" gate; run it before declaring a build green.
2. Sync mode: `rsync -a --delete --exclude=NOT_USED_BY_CROSSLE.md "$DCM_SRC/$f/" "$SRC_ROOT/$f/"` — `--delete` is what
   keeps the folder byte-identical (removes files dcm-web removed).
3. Migration hint: feature SQL lives outside the folder (`Resources/Migrations/Versioned/NNNN_*.sql`) and every
   project numbers its own scripts, so SQL is **not** copied. The script lists dcm-web scripts whose filename contains
   the feature's lowercase name (`kvp` → `0025_create_kvp_client.sql`, `0026_create_kvp_server.sql`) and, for each,
   says whether a script with the same suffix (after `NNNN_`) already exists in this project's `Versioned/`. Missing
   ones are printed as "copy with your next number". Decision D5 covers the naming this relies on.
4. Record: rewrite `Tools/dcm-features.lock.md` — table of feature → dcm-web commit, branch, dirty-count, UTC date
   (same fields `sync-dcm-core.sh` writes into `Src/Lib/README.md`). Answering "which Community do I have" is a lookup.
5. Wiring is manual and printed as a reminder: `services.Add<Name>Module()` in the project's `BootStrapper`, plus
   the NuGet packages the module needs (a copied folder carries no package references — check the module's usings
   against `Main.csproj`).

Namespaces are already portable: every project's root namespace is `Main` (`Main.Features.Kvp`, `Main.Core.Storage`
verified in dcm-web, flash-web, hunter-web, racer-web), so copied files compile without edits.

Master copy: `testapp/hunter-manager/docs/web-modularization/sync-dcm-features.sh` with an empty `FEATURES=()`;
each project's copy differs only in `FEATURES`, `DCM_WEB` default and `SRC_ROOT`.

### 3.3 dcm-web side — hosting without route collisions (✅ built and probe-tested 2026-09-24)

"Not wired" is not enough. `AddControllers()` maps **every** controller found in the assembly whether or not
`Add<Name>Module()` ran, so a hosted `AuthOffline` inside `DcmCoreWeb.dll` would register `api/login/anonymous` and
`api/login/refresh` next to Crossle's `Auth` (same paths) and `api/user/change_status` next to `User` → ambiguous-route
failure at Crossle startup. Verified against the real `[Route]`s of dcm-web Auth/User, racer and flash AuthOffline/UserOffline.

Mechanism (all in dcm-web, all driven by the marker file alone):

- `Src/Main/Main.csproj`: item `HostedMarker = Src\**\NOT_USED_BY_CROSSLE.md`; target `RemoveHostedModules`
  (`BeforeTargets=CoreCompile`) does `Compile Remove="Src\%(HostedMarker.RecursiveDir)**\*.cs"` per marker. A marker
  folder is therefore never part of `DcmCoreWeb.dll` (probe: a controller on `api/login/anonymous` + marker → absent
  from the DLL; marker removed → present again).
- `Src/Main.Hosted/Main.Hosted.csproj` (new, in `Dcm.sln`): build-only class library, `EnableDefaultCompileItems=false`,
  references `Main`, target `IncludeHostedModules` compiles the same marker folders. Nothing references it at runtime;
  `dotnet build Dcm.sln` fails if a dcm-web refactor breaks a hosted module. `ImplicitUsings` disabled like Main, so
  hosted code needs explicit usings (downstreams have implicit usings on — explicit is the safe superset).
- `Tools/list-shared-modules.sh`: HOSTED / WIRED / UNWIRED / HELPER per folder; exit 1 if a folder is hosted AND wired.
- `Src/Docs/NOT_USED_BY_CROSSLE.template.md`: the marker text (owner wording) + `Used by:` line.
- Tests for hosted modules (P3+): `Main.Test` may reference `Main.Hosted` for construction tests; the runtime coverage
  is the downstream projects' own test suites.

## 4. Docs to update (same change as the rule, never later)

| File | Change |
|---|---|
| `dcm-web/Src/Docs/AI_RULES.md` | add the OWNERSHIP block under ARCHITECTURE — UPSTREAM ROLE; add the `NOT_USED_BY_CROSSLE.md` convention; mention `list-shared-modules.sh` |
| `testapp/hunter-manager/docs/web-modularization/AI_RULES.web.md` (master) → byte-identical copies in racer-web, hunter-web, flash-web, tapit-web | add the OWNERSHIP block; replace "copy it" wording with "add to `FEATURES` in `Tools/sync-dcm-features.sh` and run it"; add the `--check` gate |
| `general-manager/introduction.md` | new section "Upstream ownership" (3 lines + pointer here); `Current:` line gains this folder |
| `dcm-manager/introduction.md` | list of hosted-not-wired modules and who consumes them (the "shared change → note it here" rule already exists) |
| `racer/racer-manager/introduction.md` | `AuthOffline`/`UserOffline` are no longer racer-owned forks → synced from dcm-web; `sync-dcm-core.sh` now exists; drop "planned but not yet written" |
| `flash/flash-manager/introduction.md` | `AuthOffline`/`UserOffline`/`Community`/`Core/Cors` → synced; `Core/Storage` unchanged (already synced) |
| `testapp/hunter-manager/introduction.md` | `Community`, `Core/Cors`, `Core/Swagger`, `Core/Storage` → synced; `TestFixtures` renamed |
| `tapit/tapit-manager/introduction.md` | `Core/Cors` promoted from here; `StoragePresign` fate per D4 |

## 5. Phases

Order matters: tooling first (so every later move is done with the script, never by hand), then re-syncs of things
that already have an owner, then promotions (the redesign work), then docs.

| Phase | Scope | Projects |
|---|---|---|
| **P0 Rules + markers** | Write the OWNERSHIP block into both AI_RULES files; create `NOT_USED_BY_CROSSLE.md` template; `list-shared-modules.sh` | dcm-web, hunter-manager master, 4 copies |
| **P1 Tooling** | `sync-dcm-features.sh` master + per-project copies with today's honest `FEATURES` (only modules that are *already* identical: flash `Core/Storage`; everything else enters the array as its phase lands); `sync-dcm-core.sh` for racer; `dcm-features.lock.md` generated | all 4 downstream |
| **P2 Re-sync existing owners** | `Kvp` → racer; `Core/Storage` → hunter (after deciding its 2-file diff); `Core/Database/Migration` + `MysqlEfModule` reconciled in dcm-web → all | racer, hunter, flash, tapit |
| **P3 Promote AuthOffline/UserOffline** | Build the upstream version in dcm-web from flash's (+ racer's status types), `NOT_USED_BY_CROSSLE.md`, tests; **routes = union of what both shipped clients call** (racer: `api/login/{anonymous,refresh}`, `api/user/change_status`; flash: `api/login/{anonymous,refresh}`, `api/user/me` GET/PUT) — verify with `dotnet build Dcm.sln` (hosted assembly) and each downstream's `Baselines/routes.txt`; racer and flash replace theirs via the script; DbUp scripts (`user`, `user_status`, `user_linked_accounts`) checked with the migration hint; both apps smoke-tested (login → token → authed call) | dcm-web, racer, flash |
| **P4 Promote Community** | Generic module in dcm-web (target-type parameter), marker, tests; hunter + flash re-sync; each keeps an app-owned adapter for its target entity (deck / product) | dcm-web, hunter, flash |
| **P5 Promote Core/Cors + Core/Swagger** | tapit's Cors, one `SwaggerBearerSecurity`; markers; hunter/flash/tapit re-sync | dcm-web, hunter, flash, tapit |
| **P6 Storage presign (D4)** | `PresignAsync` upstream; tapit syncs `Core/Storage`, deletes `StoragePresign` | dcm-web, tapit |
| **P7 Docs** | Section 4 table; managers' `session_progress.md`; move this folder to `implementation-done/` | all |

Each phase ends with: `dotnet build` of every touched solution, `dotnet test` where a `Main.Test` exists, and
`sync-dcm-features.sh --check` passing in every downstream. No commits (owner rule).

## 6. Decisions for Fatih

| # | Question | Proposal |
|---|---|---|
| D1 | Which dcm-web branch do downstreams sync from? | ✅ owner 2026-09-24: **`dev`**. `sync-dcm-features.sh` and `sync-dcm-core.sh` warn (not fail) when dcm-web is on another branch; the lock file records branch + commit |
| D2 | racer-web layout is `racer/Src/Core/Features/<Name>`, not `Src/Main/Src/Features/<Name>` | ✅ owner 2026-09-24: **move racer to the standard layout** in P1 — "all downstreams follow the same standards as their upstream". **Done 2026-09-24:** `Src/Main/Main.csproj` (assembly `RacerWeb`, like `FlashWeb`/`TapItWeb`/`DcmCoreWeb`), `Src/Main/Src/{BootStrapper,Core,Features,HttpShared}`, `Src/Main/Resources`, `Src/Lib/` (HintPath `..\Lib\`), `Tools/generate-http-shared.sh` (moved from the root like dcm-web's), `racer.sln`, Dockerfile (`RacerWeb.dll`), compose comment, `Src/Docs/README.md`, racer-manager intro. `dotnet build racer.sln` 0 errors; `Tools/generate-http-shared.sh` regenerates Kvp + Common byte-identical (it now also emits AuthOffline/UserOffline contracts that were never generated before — output restored to the committed state, taking them is Fatih's call per racer-manager). Moves were plain `mv` (nothing staged) |
| D3 | Should Crossle adopt the promoted `Core/Cors`? dcm-web today relies on `Dcm.Core`'s `AllowAnyOrigin` | ✅ owner 2026-09-24 (proposal accepted): no change to Crossle now; module is hosted-not-wired |
| D4 | tapit `StoragePresign` vs `FileStorage` | ✅ owner 2026-09-24 (proposal accepted): fold presign into `FileStorage` upstream (one storage module); tapit drops `StoragePresign` |
| D5 | Migration naming so the script's hint works: `NNNN_<verb>_<feature-table>.sql` with the feature name in the filename | ✅ owner 2026-09-24 (proposal accepted): rule is in both AI_RULES files since P0 |
| D6 | Hunter's two `Core/Storage` edits — improvement or hunter-specific? Needs a read of the diff before P2 | ✅ owner 2026-09-24 (proposal accepted): read the diff in P2, decide then — outcome recorded in `session_progress.md` P2 |
| D7 | Community's generic shape (target type as string column vs. generic entity) — affects hunter's `Products` and flash's `Deck` adapters | ✅ owner 2026-09-24 (proposal accepted **with an exit**): string `TargetType` + `TargetId` columns, app-owned adapter per project — **but if the two Community features turn out too app-specific to share a core, leave both as they are** (app-owned, and then renamed apart so the same name no longer promises identity). P4 starts with that assessment and reports before writing code |
| D8 | `Core/Database/Migration/DbMigrator.cs`: dcm-web and racer log via `Logy`, hunter/flash/tapit via `Console.WriteLine`; the generic rule already says "No `Console.WriteLine` outside `DbMigrator` (which runs before logging exists)" | ✅ owner 2026-09-24 ("finish all the phases"), applied: make dcm-web's DbMigrator use `Console.WriteLine` (conforms to the master rule, keeps hunter's ILogger-only convention intact; Crossle's migration lines still reach `docker logs` via stdout), then sync `Core/Database/Migration` to all four |
| D9 | `AppDbContext` namespace is `Main.Database` in dcm-web (16 files incl. tests) and racer (3 files), `Main.Core.Database` in hunter/flash/tapit; the rule is namespace = folder → `Main.Core.Database`. Blocks a byte-identical `MysqlEfModule.cs` (dcm's needs `using Main.Database;`) | ✅ applied 2026-09-24: change dcm-web + racer to `Main.Core.Database` (mechanical: 19 `using`/namespace lines, no type renamed), then `MysqlEfModule.cs` needs no extra using |
| D10 | `MysqlEfModule.cs` server version: dcm-web + racer `ServerVersion.AutoDetect(connectionString)` (opens a connection at startup), flash `MySqlServerVersion(8.0.0)`, tapit `MySqlServerVersion(8.0.36)`, hunter fixed 8.0.0 — downstream reason: EF model must be buildable without a live DB (`EfModelSnapshotTest`) | ✅ applied 2026-09-24: upstream = fixed version read from config with a default: `Mysql:ServerVersion` (default `8.0.36`, the shared `dcx-mysql` image), so Crossle can pin what its own MySQL runs; then `Core/Database/MysqlEfModule.cs` becomes a single-file `FEATURES` entry in all four |
| D11 | `Db` (DbConstants) namespace is `Main.Repository` in dcm-web + racer, `Main.Core.Database` in hunter/flash/tapit; a synced module can reference `Db.*` with only one `using` | ✅ applied 2026-09-24 (same rationale as D9, rule = namespace is the folder): moved in dcm-web + racer, `using Main.Core.Database;` added to 47 files, `Db.User.DefaultName` added; every build green |
