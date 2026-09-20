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
| `test-generate.sh` | golden test over what the launcher *generates* (`testdata/golden/`) |
| `waitport.sh` | blocks until a TCP port accepts, used between panes |
| `tailer.sh` | resolves a `%DATE%` glob, waits for it, then `tail -F` |

## How a project plugs in

`<project>-manager/tools/project.sh` is the only project-specific file. It
declares the infra stack and the services, and nothing else:

```bash
PROJECT=flash
WEB_REPO="${FLASH_WEB_REPO:-$MANAGER_DIR/../flash-web}"
CLIENT_REPO="${FLASH_CLIENT_REPO:-$MANAGER_DIR/../client}"
INFRA_REPO="${DCM_DOCKER_REPO:-$MANAGER_DIR/../../dcm-docker}"

gm_infra dir="$INFRA_REPO/common-infra" label="shared mysql"
gm_wait  mysql key=MYSQL_PORT default=20010

gm_service name=web container=flash-web-container port=20300 waits=mysql \
           docker="$WEB_REPO/Docker/Main" project="$WEB_REPO/Src/Main"
gm_service name=client kind=flutter-web container=flash-client port=20321 waits=web \
           docker="$CLIENT_REPO/Docker" project="$CLIENT_REPO"
```

* `MANAGER_DIR` is set for you, so paths stay relative to the checkout.
  Each repo location can be overridden with the env var shown in the `${…:-…}`.
* `project=` omitted (or `-`) means the service has no local build and runs from
  Docker in both modes.
* `kind=` is what manual mode runs from `project=`. `dotnet` (the default) is
  `dotnet run --launch-profile <profile>`; `flutter-web` is
  `flutter run -d <device> --web-port=<port>
  --dart-define-from-file=Resources/Configs/appsettings.<profile>.json`, i.e. the
  same command the client's own `tool/run.dart` issues. The device is `chrome`
  unless `--device=` (or `GM_WEB_DEVICE`) says otherwise; `web-server` serves on
  the port without opening a browser. Docker mode is `docker compose up` for
  every kind, so a client's `Docker/` folder needs a compose file that publishes
  the registry port and an `.env.local` naming the `APP_ENV` to bake in.
* `profile=` is the environment name in both kinds: a launchSettings profile for
  dotnet, an `appsettings.<profile>.json` for flutter-web (default `local`).
* `optional=1` makes a service **opt-in**, reached with `--with=<name>`.
* `env=` names a per-service compose env file; `-` means the stack has none.
* `waits=` lists `gm_wait` names and/or other services that must accept
  connections before this pane starts — a client waits for its API.

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

## Tests

Two, and they cover different halves:

| | what it proves | needs |
|---|---|---|
| `test-panes.sh` (a project's `tools/bash/runner/test.sh`) | panes really open and run, in whichever terminal | a terminal |
| `test-generate.sh` | what is *written into* those panes is what we expect | nothing |

```bash
general-manager/bash/lib/test-generate.sh            # check
general-manager/bash/lib/test-generate.sh --update   # accept a change, then read the diff
```

It runs the real `run.sh --dry-run` against a throwaway fixture project — stub
`docker`/`dotnet`/`flutter` on `PATH`, everything inside a temp dir — for three
cases (`docker`, `manual`, and `docker --with= --app-env= --no-build`), then
diffs `.run/env.sh` and every generated pane script against
`testdata/golden/*.txt`. Absolute paths, `$PATH` and `GM_OS` are flattened; the
rest is pinned byte for byte, so a changed `docker compose` line or a new export
shows up as a diff.

It also enforces the `env.sh` export contract directly: every exported name must
be `GM_`-prefixed or one of the reviewed legacy names. That check is the
`APP_ENV` bug written down as a test — it fails with the reason, not just a
diff.

**Run it after every change to `run.sh`/`tools.sh`.** A diff is not a failure by
itself; it is the change you made, shown to you. Re-run with `--update` and keep
the golden diff with the change.

Not covered: `stop.sh` (no dry run) and the whole of `../../cmd/lib`, which is
the same logic hand-mirrored in batch — `run.cmd` has a `--dry-run` too, so the
same test can be written there, from Windows.

## Conventions this code follows

* **Project env files are never restated.** Ports and bind paths are read from
  the compose env file that compose itself reads (`gm_env_get`), with the
  registry value from `PORTS.md` as the fallback — the same `${VAR:-default}`
  the compose files carry. Nothing from those files is exported into a pane,
  because a shell variable silently outranks `--env-file`.
* **The launcher's own variables are `GM_`-prefixed** for that same reason:
  `.run/env.sh` is sourced by every pane, so a bare name like `APP_ENV` would
  reach `docker compose` and win over the stack's `.env.local` (it did — it
  baked `appsettings..env.local.json` into a client image). The env-file
  selector is `GM_APP_ENV`; the flag stays `--app-env=`.
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
