# general-manager/bash/lib — shared tooling, shell half

One implementation of the local-run tooling, used by `flash-manager`,
`hunter-manager`, `tapit-manager`, `racer-manager` and `dcm-manager/tools_v2`.
Each of those has a runner folder that is **only** wrappers plus a description
of itself; everything executable lives here.

The Windows half is `../../cmd/lib` — same concepts, same declarations.

```
general-manager/
  bash/lib/      <- you are here
  cmd/lib/       <- the same thing for cmd.exe

<project>-manager/tools/
  bash/runner/   <- wrappers + project.sh + logs.conf
  cmd/runner/    <- wrappers + project.cmd + logs.conf
```

New tooling that is not the runner gets its own folder beside `runner/` on each
side, and its shared code its own folder beside `lib/`.

(`dcm-manager/tools` — the v1 layout — deliberately keeps its own private copy,
for the side-by-side comparison in `dcm-manager/tools_v2/README.md`.)

## Layout

| file | what it is |
|---|---|
| `tools.sh` | the machinery: panes, terminals, env-file reading, readiness waits, preflight checks |
| `run.sh` | `run.sh docker\|manual` — the launcher both `run-*.sh` wrappers call |
| `stop.sh` | `docker compose down` for each declared stack |
| `logs.sh` | one pane per service, following its logs |
| `test-panes.sh` | launches dummy panes to check the terminal plumbing |
| `waitport.sh` | blocks until a TCP port accepts, used between panes |
| `tailer.sh` | resolves a `%DATE%` glob, waits for it, then `tail -F` |

## How a project plugs in

`<project>-manager/tools/project.sh` is the only project-specific file. It
declares the infra stack and the services, and nothing else:

```bash
PROJECT=flash
WEB_REPO="${FLASH_WEB_REPO:-$MANAGER_DIR/../flash-web}"
INFRA_REPO="${DCM_DOCKER_REPO:-$MANAGER_DIR/../../dcm-docker}"

gm_infra "$INFRA_REPO/common-infra" "mysql" MYSQL_PORT 20010

#          name  docker-dir              project-dir (- = docker only)  container            port  profile [opt] [env-file]
gm_service web   "$WEB_REPO/Docker/Main" "$WEB_REPO/Src/Main"           flash-web-container  20300 local
```

* `MANAGER_DIR` is set for you, so paths stay relative to the checkout.
  Each repo location can be overridden with the env var shown in the `${…:-…}`.
* `project-dir` of `-` means the service has no local build and runs from Docker
  in both modes.
* 7th field `1` makes a service **opt-in**, reached with `--with=<name>`.
* 8th field names a per-service compose env file; `-` means the stack has none.

Wrappers pass two paths: `GM_TOOLS_DIR` (the runner folder — it owns `.run/`,
`project.sh` and `logs.conf`) and `GM_MANAGER_DIR` (the `<project>-manager` that
`project.sh` resolves its repo paths against). How deep a runner sits is a
layout question, not a lib question:

```bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manager="$(cd "$here/../../.." && pwd)"        # …/tools/bash/runner -> …-manager
GM_TOOLS_DIR="$here" GM_MANAGER_DIR="$manager" \
  exec "$manager/../../general-manager/bash/lib/run.sh" docker "$@"
```

## Conventions this code follows

* **Project env files are never restated.** Ports and bind paths are read from
  the compose env file that compose itself reads (`gm_env_get`), with the
  registry value from `PORTS.md` as the fallback — the same `${VAR:-default}`
  the compose files carry. Nothing from those files is exported into a pane,
  because a shell variable silently outranks `--env-file`.
* **No `-p`**: every stack keeps the compose project name derived from its own
  folder, so the panes drive the same containers as running compose by hand.
* **`stop.sh` clears leftover local processes** after the stacks are down:
  anything listening on a port the project declares gets TERM, then KILL if it
  hangs on. Ports a container publishes are skipped, since compose owns those.
* **The shared database is never stopped by default.** `common-infra` backs all
  four projects; `stop.sh` leaves it up unless you pass `--stop-infra`.
* **Ctrl-C stops a service without closing its pane** — you land in an
  interactive shell with the command in history, so `↑` re-runs it.

Shell only. The `.bat` half of this exists in `dcm-manager/tools` if a Windows
machine ever needs these four.
