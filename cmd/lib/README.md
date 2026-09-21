# general-manager/cmd/lib — shared tooling, Windows half

The same launcher as `../../bash/lib`, for `cmd.exe`. Same concepts, same
`project.*` declarations, same generated panes — so a project describes itself
once per platform and gets the same behaviour on both.

| file | bash counterpart |
|---|---|
| `tools.cmd` | `tools.sh` — service table, env-file reading, preflights, pane launching |
| `run.cmd` | `run.sh` — `run.cmd docker\|manual` |
| `stop.cmd` | `stop.sh` |
| `logs.cmd` | `logs.sh` |
| `test-panes.cmd` | `test-panes.sh` |
| `test-generate.cmd` + `test-generate.ps1` | `test-generate.sh` — golden test over the generated panes |
| `waitport.cmd` | `waitport.sh` (PowerShell `TcpClient` instead of `/dev/tcp`) |
| `tailer.cmd` | `tailer.sh` (PowerShell `Get-Content -Wait` instead of `tail -F`) |

## How a project plugs in

`<project>-manager/tools/cmd/runner/project.cmd` is the only project-specific
file. Batch has no functions across files, so the calls go through `tools.cmd`:

```bat
call "%GM_LIB%\tools.cmd" infra dir="%INFRA_REPO%\common-infra" label="shared mysql"
call "%GM_LIB%\tools.cmd" wait mysql key=MYSQL_PORT default=20010
call "%GM_LIB%\tools.cmd" service name=web container=flash-web-container port=20300 waits=mysql ^
     docker="%WEB_REPO%\Docker\Main" project="%WEB_REPO%\Src\Main"
```

Keys are identical to the bash side (`name= docker= project= container= port=
ports= kind= profile= optional= env= waits=`), so the two `project.*` files stay
readable side by side. **Keep them in step** — nothing enforces it.
`kind=flutter-web` runs `flutter run -d <device> --web-port=<port>
--dart-define-from-file=Resources/Configs/appsettings.<profile>.json` in manual
mode (`flutter.bat` from PATH; `--device=` picks the device, default `chrome`).

The wrapper passes `GM_TOOLS_DIR` (the runner folder) and `GM_MANAGER_DIR` (the
`<project>-manager` above `tools/`), which is how shared code finds the right
`project.cmd`, `logs.conf` and `.run/`.

## Tests

Two, and they cover different halves:

| | what it proves | needs |
|---|---|---|
| `test-panes.cmd` (a project's `tools\cmd\runner\test.cmd`) | panes really open and run, in whichever terminal | a terminal |
| `test-generate.cmd` | what is *written into* those panes is what we expect | nothing |

```bat
general-manager\cmd\lib\test-generate.cmd            :: check
general-manager\cmd\lib\test-generate.cmd --update   :: accept a change, then read the diff
general-manager\cmd\lib\test-generate.cmd --keep     :: leave the temp fixture behind
```

It runs the real `run.cmd --dry-run` against a throwaway fixture project — stub
`docker`/`dotnet`/`flutter` on `PATH`, everything under `%TEMP%` — for three
cases (`docker`, `manual`, and `docker --with= --app-env= --no-build`), then
diffs `.run\env.cmd` and every generated pane script against
`testdata\golden\*.txt`. Only absolute paths are flattened; the rest is pinned
line for line, so a changed `docker compose` line or a new `set` shows up as a
diff. It also enforces the `env.cmd` contract directly: every name set there
must be `GM_`-prefixed or one of the reviewed legacy names — that check is the
`APP_ENV` bug written down as a test.

Two Windows details worth knowing before reading the script:

- The stubs are **compiled `.exe` files** (`Add-Type -OutputAssembly`), not
  `.cmd` shims. `run.cmd` runs `docker info` without `call`, so a batch file of
  that name on `PATH` would transfer control and never come back.
- The test itself is PowerShell, driven by a batch wrapper that maps `--update`
  onto `-Update`. Batch cannot diff text, and this lib already uses PowerShell
  for `waitport`, `tailer` and the port checks.

**The goldens are not in the repo yet** — they can only be produced by running
`run.cmd`, which needs Windows. First run there: `test-generate.cmd --update`,
read every line of `testdata\golden\*.txt` against
`..\..\bash\lib\testdata\golden\*.txt` (same fixture, same three cases —
the two should differ only where batch and shell legitimately differ), then keep
them. The bash goldens are the reference for what the output *should* say.

## Windows-specific behaviour

- Terminals: **WezTerm → Windows Terminal (`wt`) → one console window per
  service**. WezTerm gives the same 2×2 grid as on macOS/Linux.
- **Ctrl-C**: batch intercepts it with `Terminate batch job (Y/N)?`. Answer
  **N** and the pane continues to a `cmd /k` prompt, where the doskey macro `r`
  re-runs the pane. `doskey` cannot be pre-seeded into ↑ history, so `r` is the
  nearest equivalent of the bash side's "press ↑".
- `stop.cmd` clears leftover local processes the same way the shell half does,
  via `Get-NetTCPConnection` + `taskkill` instead of `lsof` + `kill`.
- Env files: `.env.win` is picked for the infra stack (`.env.ubuntu` as a
  fallback), against `.env.mac`/`.env.ubuntu` on the bash side.

## Status

**Written but not executed.** It was developed on macOS; there is no Windows
machine in the loop — `test-generate.cmd` included, which is why it ships
without goldens. The logic mirrors the bash half line for line and the known
batch traps are handled (no labels inside `( )` blocks, `call set` for indirect
expansion, goto-dispatch instead of delayed expansion, CRLF endings), but treat
the first run as a shakedown and start with `test.cmd --no-terminal`.
