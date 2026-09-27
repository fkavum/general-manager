# Architecture review — how the portfolio is managed today (second eye, 2026-09-27)

Scope: the six-app portfolio as described in `general-manager/introduction.md`, evaluated from the point of view of a
solo developer who must keep Crossle (the only live product) healthy while continuing four pre-release apps, and who
wants features to move between projects cheaply. Everything below was verified against the repos on 2026-09-27
(git state, md5 of "byte-identical" copies, `sync-dcm-features.sh --check` in all four downstreams, script contents).
Paths are relative to `/Users/fkavum/Documents/project/`.

The short version:

- **The management system itself is good.** Manager folders, dated owner decisions, contract tests as gates, the port
  registry and the one-upstream rule are all above what most small teams have. Keep them.
- **The biggest risk is not architecture, it is release discipline on Crossle.** Production is the state of 2026-07-24;
  two months of work, including a rewritten login path and table-dropping migrations, sit unreleased on `dev` and on a
  105-commit client feature branch. The owner's estimate (2026-09-27): at least one month of art work before it is
  shippable. There is no CI anywhere. (Correction 2026-09-27: the Dokploy server takes a daily database backup — the
  script in `bash-scripts` is simply not the mechanism in use.)
- **Sharing is solved on the server side and unsolved on the client side.** The five .NET projects have one upstream,
  one owner per module and a mechanical drift check. The three Flutter clients and the two Unity clients share nothing
  but hand-ported copies, and the same client features have already been implemented three times.
- **The documentation is starting to work against you.** `dcm-manager/introduction.md` is 407 lines (~29k tokens) and
  carries 23 open implementations; every AI session pays that before doing anything.

---

## 1. What is working well (keep, and do not "improve" away)

### 1.1 The manager convention
`introduction.md` + `implementations/<feature>/` (`overview.md`, per-project notes, `session_progress.md`,
`editor_guide.md` for Unity) + `implementation-done/`. Six managers follow the same shape, decisions are numbered
(D1…Dn) and dated with the owner's wording, and `session_progress.md` records what was verified (test counts, live
smoke rows). This is exactly what makes solo work with AI resumable. It is the single most valuable asset in the
portfolio and the reason the identity refactor could be done in days without breaking shipped clients.

### 1.2 Contract tests as the gate for shared changes
`LoginWireContractTest` / `UserWireContractTest` in dcm-web pin raw JSON, status codes and messages the Unity clients
and dcm-game-server parse. Downstreams have `Baselines/routes.txt` and `efmodel.txt` snapshot tests. Refactoring the
production auth behind these was the right order of operations. The rule "run the wire test before touching
`Features/Auth*`" is the kind of rule that actually protects a live game.

### 1.3 One upstream, one owner, mechanical drift check
`dcm-web` owns every module used by two or more web projects; downstreams pull byte-identical folders with
`Tools/sync-dcm-features.sh`, and `--check` is the gate. Verified today: **all four downstreams pass `--check`**, the
generic `AI_RULES.web.md` and `sync-dcm-core.sh` are md5-identical in all four repos and the master, and the four
`sync-dcm-features.sh` copies differ from the master only inside `FEATURES`. The hosted-module mechanism
(`NOT_USED_BY_CROSSLE.md` → excluded from `DcmCoreWeb.dll`, compiled by `Src/Main.Hosted`) is a clever fix for a real
route-collision hazard and it fails in dcm-web's build instead of on the next downstream sync. Good.

### 1.4 The port registry
`2NNRR` is decodable at a glance, has one authoritative file, and compose files carry the registry value as their
default. Applied across all apps. Nothing to change.

### 1.5 Shared local-run tooling
`general-manager/bash/lib` with per-project wrappers, a golden test for what the launcher generates, and the
`GM_`-prefix rule born from a real bug (`APP_ENV` leaking into compose). Five managers use it. Good pattern.

### 1.6 Tests that need no environment
Four of five web projects run NUnit against a Testcontainers MySQL; dcm-web's suite was brought from 41 failing to
152/153 on 2026-09-24. Docker is the only prerequisite. This is the right test shape for a solo developer.

### 1.7 Sensible infra separation
Crossle has its own MySQL/Redis (`dcm-network`); every pre-release app shares one `dcx-mysql-container` and creates its
own database in migration `0000`. Blast radius of an experiment never reaches the live game's data.

---

## 2. What is hurting, or will

Ordered by how much damage it can do to the one live product.

### 2.1 Crossle's release gap (highest risk)

| Repo | Production branch last moved | Where the work is |
|---|---|---|
| dcm-web | `master` 2026-07-24 (`release/1-0-8`) | `dev` is 27 commits ahead: unified Auth, Identity, `0052_drop_user_accounts.sql`, `0053`, `0054` |
| dcm-client | `master` == `dev` (nothing merged since July) | `feature/friends` is **105 commits ahead of both**: friends, tutorial, WebGL, email login, auth, UI validation |
| dcm-game-server | `master` (July) | `dev`: friends presence/invites, WS transport |
| CommonClientGame (submodule) | — | `dev` 3f0d373, pinned identically in client and server (good) |

Consequences:
- The next release is a big-bang across three repos plus the submodule plus migrations that **drop a table**. Every
  week it waits, the diff to bisect when something breaks in production gets larger.
- A production hotfix today has to be made on `master` and then forward-ported over a rewritten auth layer.
- `bash-scripts/apps/dcm_ubuntu/deploy_dcm.sh` does `git reset --hard` + checkout `master` on the VPS, so "deploy" is
  literally "merge to master". `auto_merge.sh` and `release.sh` exist but have not been used since July.
- The **shared-module work lands on Crossle's production code path first.** Making Auth shareable rewrote Crossle's
  login controller; Hunter's need for roles added a column and a route to Crossle; per-app name rules changed
  `UserService`. Each was additive and contract-tested, but the sum is: Crossle's unreleased `dev` carries changes
  motivated by apps that have no users. The `upstream-ownership` decision says "revisit if dcm-web's release cadence
  starts blocking the others" — the opposite is what is happening: the others' churn is sitting in Crossle's release.

This is a process problem, not a code problem, and the fix is cheap (see §3.1).

### 2.2 No CI, manual deploy steps left open
- Backups: **corrected 2026-09-27** — the Dokploy server takes a daily database backup (owner). The repo view is
  misleading: `bash-scripts/apps/bash_lib/mysql/super_mysql_backup.sh` is the older Mac-side mechanism, has no
  scheduler and its last committed dumps are 2026-04-07. Worth one line in `dcm-manager/introduction.md` saying where
  the real backup lives and one restore drill on a copy before the next release, since DbUp runs at startup with no
  rollback and `0052` drops a table.
- No `.github/workflows`, Jenkinsfile or equivalent anywhere in the portfolio. Every gate (`--check`,
  `list-shared-modules.sh`, `icons.sh check`, `test-generate.sh`, the wire tests) runs only when someone remembers.
- Deploy is two different worlds: Crossle via VPS pull scripts + host nginx (2303/2306 legacy TCP) **and** Traefik on
  `dokploy-network`; the apps via Dokploy only. Dokploy's target container ports live only in its UI; the port-scheme
  migration still has its manual Dokploy/VPS steps unchecked since 2026-09-11 (`implementations/port-scheme/`), and
  `dcm-docker` sits on an unmerged `new-ports` branch.

### 2.3 Client-side sharing is zero, and the same features were built three times
Server side has a strict rule; client side has none. Verified state of the three Flutter clients:
- No `path:` dependency, no shared package. `lib/theme/*`, `server_unavailable_screen.dart`, `app_snack_bar.dart`,
  `empty_state.dart`, `api_service.dart`, `auth_service.dart`, `tool/run.dart`, `Docker/*`, `web/index.html`,
  `web/manifest.json` exist in all three and are all forked (different md5), most only by comments or names.
- The managers prove the cost: `client-env-config`, `serilog-logging`, `server-unavailable-page`, `ui-design-system`
  appear as separate implementations in hunter-manager **and** flash-manager **and** tapit-manager. Three plans, three
  sessions, three drifting results for one feature.
- Unity: Racer ports dcm-client `GameComponents` by hand ("Ported from … only namespaces/usings differ" headers), does
  not use the `CommonClientGame` submodule, and has its own `HttpSender`. Two games, no shared package, and Crossle's
  namespace (`DontCrossMe.GameComponents.*`) makes a later extraction touch the live game.

The `app-icons` work (2026-09-27) is the first client-side sharing mechanism and it uses the same borrow-and-sync shape
as the server. That is fine for a build script; it is the wrong shape for Dart/C# code (see §3.4).

### 2.4 Documentation weight and WIP count
- `dcm-manager/introduction.md`: 407 lines, ~29k tokens. The "Active implementations" bullets are 300–1500-word
  paragraphs (meta-art alone is ~1200 words); the shared-change log lives inside the intro. Every session on Crossle
  loads this before reading a single line of code. Across the six managers there are ~98k lines of markdown.
- **23 open implementations** in dcm-manager (25 done). For one person that is a backlog presented as a plan. Several
  have been "blocked on D1–D8" for a month (mini-game-ideas, splash-screen); `email-login` was moved to done and
  reopened; `global-product-moderation` is in both `implementations/` and `implementation-done/` in hunter-manager.
- The "Hard rules" block is copy-pasted into at least six intros plus AI rules files. One wording change means six edits.

### 2.5 Binary and copy-based sharing has no version signal
- `Dcm.Core.dll`, `CommonLib.dll`, `MysqlHelper.dll` are checked into `Src/Lib/` in five repos. The chain is
  dcm-generator → `sync-libs.sh` → dcm-web → `sync-dcm-core.sh` → four downstreams, with a README stamp as the only
  version. The rule "keep the consumer's NuGet versions in step with `Dcm.Core.csproj`" is manual. A breaking Dcm.Core
  change is discovered at sync time in each downstream, not at build time upstream (the hosted-module trick covers
  source modules, not the DLL boundary).
- Every `Tools/dcm-features.lock.md` records dcm-web `961a878` **with 33 uncommitted files** — the downstreams were
  synced from a dirty working tree, so the lock does not identify what was copied. The scripts warn on the wrong branch
  but not on a dirty tree.
- `HttpShared/` at the project root is a generated intermediate that is not in any git repo; the copy inside
  dcm-client's submodule lags it (no `Auth*`/`Identity` split yet). Two truths for one contract.

### 2.6 Three repo topologies for five apps
`dcm-*` = one repo per component (8 repos + submodule); `testapp/`, `flash/`, `tapit/` = monorepo with web + client +
manager; `racer/` = Unity repo that contains the manager, with `racer-web` separate at the top level. Tooling already
special-cases it (`DCM_WEB` at `../` or `../../`, project.sh comments). Not a fire, but every cross-app script pays for
it and a sixth app will copy whichever shape it is started from.

### 2.7 Small hygiene items (each is five minutes, together they mislead the next session)
- The master copies of the generic web rules and sync scripts live in
  `testapp/hunter-manager/docs/web-modularization/` — inside the Hunter monorepo, not in general-manager.
- `general-manager/bash/lib/README.md` points to `dcm-manager/tools_v2/README.md` (does not exist; the file is
  `tools_v2/bash/runner/README.md`) and does not list flash as a user. `dcm-manager/tools` (v1) and `tools_v2` coexist;
  the intro mentions neither.
- `general-manager/implementations/dependencies/dev-prompt.md` is a pasted `flutter pub get` log, nothing else.
- `dcm-docker/error` is a 230 KB stray file; `dcm-docker` Grafana compose mounts `./my.cnf` but the file is `.my.cnf`
  (already noted in port-scheme progress, still open).
- `dcm-web` csproj comments cite `AuthOffline` as the hosted example; it no longer exists (only `Core/Cors` is hosted).
- `racer-web/Src/Docs/README.md` says only `.env.local` exists; `.env.dev` and `.env.prod` are present. racer-web has
  no test project at all.
- `dcm-manager/docs/` holds two stray JSON files unrelated to docs.

---

## 3. Recommendations, in the order I would do them

### 3.1 Ship Crossle and fix the branch model (this week, before any more shared work)
1. In dcm-client, `dev` == `master`, so `feature/friends` can fast-forward into `dev`. Do it now even though the
   release is a month away: it costs nothing and stops the branch growing. Decide what 1.0.9 is (owner: art is the
   blocker, ~1 month); plan in `implementations/crossle-release-discipline/`.
2. Rehearse the migration path once on a restored copy of prod (`dcm-docker/crossle/mysql-init/` already has dumps;
   `0052` drops `user_accounts`, so verify `api/user/get` on real rows first).
3. Deploy `dev` to the stage environment (`appsettings.stage_docker.json` exists) and run the wire-contract tests plus
   the 30-row live smoke from identity-core against it. Then `release.sh` → `master` → `deploy_dcm.sh`.
4. Write the rule into `dcm-manager/introduction.md`: **feature branches live two weeks; `dev` is always deployable to
   stage; a shared-module change that touches a Crossle-wired module is released with the next Crossle release, not
   held.** Shared work then rides small releases instead of accumulating.

### 3.2 A minimum of automation (same week)
1. Backups already run daily on the Dokploy server (owner, 2026-09-27). Document that in `dcm-manager/introduction.md`
   (Infrastructure section) and restore one of them onto a local `dcm-mysql-container` once, as the migration rehearsal
   for §3.1 step 2. Retire or clearly label the Mac-side `backup_mysql` scripts in `bash-scripts`.
2. Add one GitHub Actions workflow per .NET repo: `dotnet build` + `dotnet test` on push (Testcontainers runs on the
   hosted runner; `DOTNET_ROLL_FORWARD=LatestMajor` as the README says). Five repos, one 25-line file each. This turns
   `Baselines/`, the wire tests and `Main.Hosted` into gates that cannot be forgotten.
3. Add `general-manager/check-all.sh`: runs `sync-dcm-features.sh --check` in the four downstreams,
   `dcm-web/Tools/list-shared-modules.sh`, `docs/app-icons/icons.sh check`, `bash/lib/test-generate.sh`, and prints one
   table. Run it at the end of every multi-project implementation (write that into the manager convention).
4. Close `implementations/port-scheme/`: do the Dokploy target-port edits and the VPS redeploy, merge `dcm-docker`
   `new-ports`, or explicitly park it. A folder marked "Current" since 2026-09-11 with manual steps open is a trap for
   the next port move.

### 3.3 Shrink the entry points and cap WIP (one afternoon)
1. `introduction.md` in every manager = stable facts only, target under 150 lines. The "Active implementations" list
   becomes one line per item: name, state, link. The per-feature narrative already exists in each folder's
   `overview.md`; delete the duplicate from the intro.
2. Move the shared-change log out of `dcm-manager/introduction.md` into `dcm-manager/docs/shared-change-log.md`
   (append-only, dated). Same for the port table (it is in `PORTS.md`).
3. Hard rules live in one file (`general-manager/introduction.md` already has them) and every other intro says "see
   general-manager hard rules". The memory file in this Claude project already enforces them anyway.
4. Triage dcm-manager's 23 open folders into **active (max 3)**, **parked** (decisions pending, nothing to do) and
   **ideas**; move parked/ideas under `implementations/_parked/` so the active list is the real plan. Fix the
   duplicated `global-product-moderation` in hunter-manager.

### 3.4 Client-side sharing (next, after 3.1–3.3; this is where the next months of duplication are avoided)
Flutter — a local path package, not file copies:
- Create `dcx-flutter-core/` (its own repo, or under `general-manager/packages/`) and reference it from the three
  clients with `path:`. Start with what is already near-identical: config loading (`app_config.dart`, the
  `--dart-define-from-file` convention, `tool/run.dart`), the API client base + auth token plumbing,
  `server_unavailable_screen`, snackbar/empty/error/loading widgets, `Docker/` template. Leave theme *values* per app;
  share only the theme *scaffolding* if it is the same shape.
- Rule mirroring the server: a Dart file that exists in two clients is promoted into the package; clients never copy
  from each other. Flutter's `path:` dependency gives you build-time breakage instead of drift, which byte-copy cannot.

Unity — later, and only when Racer gets close to shipping:
- Keep Crossle untouched until then. When ready, the generic `GameComponents` (Kvp, PopupSystem, Config,
  LoadingWidget) go into a local UPM package (`file:../dcx-unity-core`) or into the existing `CommonClientGame`
  submodule that Racer then also consumes. Namespace unification is the one-time cost; do it in a Crossle release
  window, not between them.

### 3.5 Tighten the server-side sharing mechanics (small, whenever convenient)
- `sync-dcm-features.sh` and `sync-dcm-core.sh`: **refuse** (not warn) when dcm-web has uncommitted changes, so the
  lock file identifies the content. The 2026-09-25 locks all say "33 uncommitted".
- Generate `HttpShared` directly into its consumers and delete the root-level orphan, or make it a repo. One truth.
- Consider a folder-based local NuGet feed for `Dcm.Core`/`CommonLib`/`MysqlHelper` (`dotnet pack` + a
  `nuget.config` source pointing at a folder) instead of DLLs in `Src/Lib/`. Semver on the package makes "which
  Dcm.Core do I have" a csproj line instead of a README stamp, and a breaking change fails at restore. Not urgent; the
  current scheme works while one person runs all the syncs.
- Move the master copies from `testapp/hunter-manager/docs/web-modularization/` to `general-manager/docs/web/`. The
  cross-app home should own cross-app masters; `app-icons` already set the precedent.
- Delete `dcm-manager/tools` (v1) once nothing references it; fix the README pointer and add flash to the user list.
- Add a test project to racer-web (even the `routes.txt` + `efmodel.txt` baselines alone would be worth it).

### 3.6 Decide the topology once, for new apps only
Standardize on the monorepo shape (`<app>/{<app>-web, <app>-client, <app>-manager}`) for every future app: one clone,
one branch, one place for the manager, and the sync scripts already handle it. Do **not** spend time reshaping
`dcm-*` or `racer`; write the decision down in `general-manager/introduction.md` under "Adding an app".

---

## 4. Decisions that could hurt later (watch list)

| Decision | Why it was right | What to watch |
|---|---|---|
| dcm-web (production) is the only upstream | One rule, no new repo, forks were already happening | Every downstream need becomes unreleased production change. Trigger to extract a `dcx-web-core` repo: the first time you want to hotfix Crossle and `dev` carries shared work you do not want to ship. Today's state is close to that. |
| Byte-identical copies as the sharing primitive (scripts, rules, icon pipeline, modules) | Zero tooling, `--check` catches drift | It scales with the number of copies × the number of masters. Fine for scripts and rules; wrong for Dart/C# code where the language has a package mechanism (§3.4). |
| DbUp at startup, no down scripts | Simple, journaled, works | Combined with big-bang releases it is the step that cannot be undone. The Dokploy daily backup plus the rehearsal in §3.1 step 2 are the mitigation. |
| Legacy 2303/2306 kept as extra publishes | Shipped clients depend on them | Needs an explicit retirement condition (min client version) or it is permanent. |
| Hosted-not-wired modules compiled into `Main.Hosted` | Fixes route collisions, fails early | Crossle's build now compiles code Crossle never runs. Acceptable; just keep `list-shared-modules.sh` in the check-all script. |
| Manager intros as the single entry point for AI | Resumability | They are becoming changelogs; §3.3 keeps them as entry points. |
| "No GitHub Actions, bash-scripts on the Mac mini" (webgl-page-design) | Matches the existing Crossle deploy | For **builds and tests** of the web repos, Actions is cheaper than remembering; keep the mini for Unity/WebGL where it is needed. |

---

## 5. Facts this review is based on (for re-checking later)

- Git: dcm-client `feature/friends` +105 over `dev`/`master`; dcm-web `dev` +27 over `master` (master 2026-07-24);
  dcm-game-server on `dev`; dcm-docker on `new-ports`; every repo's dirty count ≤ 10.
- `sync-dcm-features.sh --check`: exit 0 in hunter-web, flash-web, tapit-web, racer-web (2026-09-27).
- md5: `AI_RULES.web.md` and the four `Src/Docs/AI_RULES.md` copies identical; `sync-dcm-core.sh` ×5 identical;
  `Src/Lib/*.dll` identical across the four downstreams.
- Locks: all four `Tools/dcm-features.lock.md` → dcm-web `961a878`, `dev`, "33 uncommitted", 2026-09-25T14:53Z.
- Flutter: no `path:` deps; same-named files in `lib/theme`, `lib/screens`, `lib/widgets/common`, `lib/services`,
  `tool/`, `Docker/`, `web/` all differ by md5 across the three clients; `tool/app_icons.swift` identical in Hunter and Flash.
- Unity: both 6000.0.60f1; racer has no `.gitmodules`; Kvp DTOs identical, Kvp scripts differ by namespace + header.
- CI: no workflow files anywhere. Backup: daily on the Dokploy server (owner statement); the repo-side
  `super_mysql_backup.sh` has no scheduler and last committed dumps 2026-04-07.
- Docs: dcm-manager 65,692 lines of markdown, 23 open / 25 done implementations; hunter-manager 12,957; racer 11,114;
  flash 4,506; tapit 2,641; general-manager 1,425.
