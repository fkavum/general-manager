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
machine in the loop. The logic mirrors the bash half line for line and the known
batch traps are handled (no labels inside `( )` blocks, `call set` for indirect
expansion, goto-dispatch instead of delayed expansion, CRLF endings), but treat
the first run as a shakedown and start with `test.cmd --no-terminal`.
