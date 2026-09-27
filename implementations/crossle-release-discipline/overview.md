# crossle-release-discipline — stop the branch growing now, ship 1.0.9 in ~1 month, never accumulate again

Owner, 2026-09-27: "I need to ship it asap but the current state is not art-done and unshippable, I need at least one
month." Crossle-only in code, cross-app in policy (it decides how shared-module work reaches production), so the
policy lives here and the release checklist belongs in `dcm-manager/implementations/release-1-0-9/` when it starts.
Paths relative to `/Users/fkavum/Documents/project/`.

## 1. State (2026-09-27)

| Repo | Prod branch | Work branch | Gap |
|---|---|---|---|
| dcm-web | `master` = `release/1-0-8`, 2026-07-24 | `dev` | +27 commits: unified Auth/Identity (48 files), `0050`–`0054` migrations, `0052_drop_user_accounts.sql` **drops a table** |
| dcm-client | `master` == `dev` (July) | `feature/friends` | **+105 commits** over both: friends, tutorial, email login, WebGL, auth, UI validation; 6 uncommitted |
| dcm-game-server | `master` (July) | `dev` | friends presence/invites, WS transport |
| CommonClientGame | — | `dev` 3f0d373 | pinned identically in client and server ✅ |
| dcm-docker | `master` | `new-ports` | port scheme, 1 uncommitted |
| Deploy | `bash-scripts/apps/dcm_ubuntu/deploy_dcm.sh` on the VPS: `git reset --hard` + checkout `master` + `docker compose up` → "deploy" == "merge to master" |

## 2. Decision (proposal)

1. **Today, regardless of the release date:** `feature/friends` → `dev` in dcm-client (fast-forward, `dev` has nothing
   the branch lacks), so `dev` is the integration branch in all three repos again. New work branches from `dev` and
   merges back within two weeks. The 105-commit branch stops being the place where everything lands.
2. **`dev` is always stage-deployable.** dcm-web already has `appsettings.stage_docker.json`; a Dokploy stage service
   for web + game server on `dev` (or a manual compose on the VPS with `.env.subuntu`) is where the wire tests and the
   30-row live smoke run before every merge to master.
3. **Shared-module freeze on Crossle-wired modules until 1.0.9 ships** (`Identity`, `Auth*`, `Kvp`, `Core/Storage`,
   `Core/Database`) unless a downstream is blocked; hosted-not-wired modules (`Core/Cors`) stay free. After the release:
   a shared change to a Crossle-wired module ships with the **next** Crossle release; if that is more than four weeks
   away, it waits on a branch in dcm-web, not on `dev`.
4. **Release = the existing scripts**: `release.sh` (release branch in the 4 repos + submodule) → `auto_merge.sh`
   (`dev` → `master`) → `deploy_dcm.sh`. Re-read both before use; last used July.

## 3. Migration rehearsal (before the release, once)

1. Restore the most recent Dokploy daily backup into a local `dcm-mysql-container` (`dcm-docker/crossle-infra`).
2. Start dcm-web `dev` against it with `--env=local`: DbUp runs `0050`–`0054`; `0052` drops `user_accounts`.
3. Check on real rows: `POST api/user/get` (server tier) returns linked ids from `user_linked_accounts` for users that
   had `user_accounts` rows; `api/login/refresh` with a pre-release token (token continuity test exists);
   `LoginWireContractTest` + `UserWireContractTest`; identity-core's 30-row live smoke.
4. Record the result in `dcm-manager/implementations/release-1-0-9/session_progress.md`. If anything fails, the fix
   lands on `dev` and the rehearsal repeats from step 1 — that is the point of doing it on a copy.

## 4. Content of 1.0.9 (owner to confirm — feeds the triage in `shrinking-intros/` §6)

| In | State (dcm-manager) | Left |
|---|---|---|
| auth (unified, providers, email) | web ✅ client ✅ | ops config (Firebase service account, Google client id, SMTP via mail-provider), device smoke matrix |
| friends | web ✅ server ✅ client ✅ | editor pass, 2-device smoke |
| email-login | web ✅ client ✅ prefab ✅ | smoke matrix, polish, localization keys, SMTP |
| tutorial-system | client ✅ E2E in Editor | visual restyle, device smoke |
| art: app-icon, splash-screen, meta-art (World Tour art only if `meta` ships), font-decisions, asset-cleaning | in progress | the owner's "one month" |
| **Out** | webgl-support / webgl-page-design (behind define; `wss://` router open), meta Phase 2, teams, mini-games | park |

## 5. Docs

`dcm-manager/introduction.md` (after shrinking): a "Branches and releases" block of ≤ 8 lines with rule 1–4;
`general-manager/introduction.md` → Upstream ownership: rule 3 (shared changes ride the next Crossle release).

## 6. Decisions for Fatih

| # | Question | Proposal |
|---|---|---|
| D1 | Fast-forward `feature/friends` → `dev` now? | Yes, today. Nothing is lost, nothing is deployed by it. |
| D2 | Freeze Crossle-wired shared modules until 1.0.9? | Yes; exceptions only when hunter/flash/tapit is blocked, and then additive + contract-tested as before. |
| D3 | Stage environment | Dokploy stage services on `dev` for dcm-web + game server (target ports 20100/20101/20102 like prod, separate hostnames), or the VPS compose with `.env.subuntu`. Pick one and write it in the intro. |
| D4 | 1.0.9 content | §4 table; WebGL out. |
| D5 | Legacy 2303/2306 | Keep through 1.0.9; retire when `MinVersions` excludes every build that predates 20101/20102. |

Effort: rule 1 ten minutes; stage service ½ day; rehearsal ½ day; the rest is the art month.
