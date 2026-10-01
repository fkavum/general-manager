# general-manager/bash/sync — put a machine on one branch

The "I switched PCs" reset. Every repo a project needs is made to match
`origin/<branch>` exactly: local work is thrown away, submodules follow, missing
repos are cloned.

```
<project>-manager/tools/bash/sync/sync.sh <branch> [--dry-run] [--yes] [--only=a,b] [--no-fetch]
dcm-manager/tools_v2/bash/sync/sync.sh dev      # DCM lives in tools_v2, tools/ is left alone
```

| wrapper | repos (`repos.sh`) |
|---|---|
| `dcm-manager/tools_v2/bash/sync` | general-manager, dcm-manager, dcm-docker, bash-scripts, dcm-web, dcm-game-server, dcm-generator, dcm-admin, dcm-dict, dcxstudios-website, dcm-client |
| `testapp/hunter-manager/tools/bash/sync` | general-manager, testapp, dcm-docker, dcm-web |
| `flash/flash-manager/tools/bash/sync` | general-manager, flash, dcm-docker, dcm-web, testapp |
| `tapit/tapit-manager/tools/bash/sync` | general-manager, tapit, dcm-docker, dcm-web, testapp |
| `racer/racer-manager/tools/bash/sync` | general-manager, racer, racer-web, dcm-docker, dcm-web |

dcm-web and testapp are in the app lists because `sync-dcm-features.sh` and
`sync-flutter-core.sh` read those checkouts. `dcm-docker` is the infra.

Submodules: dcm-game-server (`DcmGameServer/Src/Core/CommonClientGame`) and dcm-client
(`Assets/CommonClientGame`), both from `dcm-sub-client-game`. Any repo with a `.gitmodules` gets the
submodule steps; nothing is listed per repo.

## What it does

1. **Evaluate.** `git fetch --prune` each repo, then print per repo: current
   branch → target, and what will be lost — merge/rebase in progress, changed
   files, untracked files, changes inside submodules, commits on no remote.
   `--dry-run` stops here.
2. **Ask** `[y/N]` (skip with `--yes`).
3. **Nuke + sync**, per repo:
   - commits on no remote → `backup/sync-<time>-<sha>` branch (delete when sure)
   - abort merge / rebase / cherry-pick / revert / am / bisect
   - `reset --hard`, `clean -fd`, `checkout -f -B <branch> --track origin/<branch>`, `clean -fd`
   - `submodule sync --recursive`, `submodule update --init --recursive --force`,
     then `reset --hard` + `clean -fd` inside every submodule

A repo whose origin has no `<branch>` lands on its default branch (`origin/HEAD`) and
the report says so — `sync.sh dev` puts flash/tapit/general-manager on `main`.
There is no pull, so there are no merge conflicts: the local branch is moved onto
origin's tip.

**Ignored files are kept** (`clean -fd`, not `-fdx`): `.env.*`, Unity `Library/`,
`bin/obj`, `node_modules`, local appsettings survive. Stashes are not touched.

## Adding a repo

One line in the project's `repos.sh`; `url=` lets a fresh machine clone it.
Folders inside the same repo are synced once (the repo is named by its top folder).

```bash
gm_repo "$P/dcm-web" url=git@github.com-fkavum:fkavum/dcm-web.git
```

The script's body is one function called on its last line. general-manager itself
can be reset mid-run without changing the code that is running.

Shell only. There is no `cmd/` twin yet.
