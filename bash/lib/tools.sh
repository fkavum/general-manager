#!/usr/bin/env bash
# Shared launcher machinery for the per-project tools/ folders.
# Sourced by <project>-manager/tools/*.sh; see general-manager/lib/README.md.
#
# It owns the generic half - panes, terminals, readiness waits, env files -
# and knows nothing about any one project. Each tools/ script declares its own
# services with gm_add_pane and hands them to gm_run_panes.

# Everything printed is also appended (without colour) to $GM_LOG, which gm_init
# points at .run/<script>.log - one file to read or send when something breaks.
_gm_log() { if [ -n "${GM_LOG:-}" ]; then printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >> "$GM_LOG" 2>/dev/null; fi; return 0; }
gm_die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; _gm_log "error: $*"
            if [ -n "${GM_LOG:-}" ]; then printf '       (launcher log: %s)\n' "$GM_LOG" >&2; fi; exit 1; }
gm_info() { printf '\033[36m==>\033[0m %s\n' "$*"; _gm_log "info: $*"; }
gm_warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; _gm_log "warn: $*"; }
# extra detail: always in the log, on screen only with GM_DEBUG=1 (--debug)
gm_debug() { if [ "${GM_DEBUG:-0}" = 1 ]; then printf '\033[2mdebug: %s\033[0m\n' "$*" >&2; fi; _gm_log "debug: $*"; }

# set -e stops a script at the first failing command without saying which one.
# This trap names it: file, line, command and what the exit code usually means.
_gm_on_err() { # <status> <command> <file> <line>
  local st="$1" hint=""
  # inside $(...) a failure is often expected (grep finding nothing); only the
  # top-level shell's failures are the ones set -e actually stops on
  [ "${BASH_SUBSHELL:-0}" = 0 ] || return 0
  case "$st" in
    127) hint="command not found - the program is not installed or not on PATH" ;;
    126) hint="found but not executable (permissions, or Windows cannot run this file type)" ;;
    130) hint="interrupted (Ctrl-C)" ;;
    1)   hint="the command reported failure; its own message, if any, is just above" ;;
  esac
  printf '\033[31merror:\033[0m command failed with exit code %s\n       at %s:%s\n       command: %s\n' \
    "$st" "$3" "$4" "$2" >&2
  [ -n "$hint" ] && printf '       meaning: %s\n' "$hint" >&2
  _gm_log "error: exit $st at $3:$4: $2${hint:+ ($hint)}"
}

# single-quote a value so it can be pasted into a generated script
gm_sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

# --------------------------------------------------------------- config ----
# No config file lives here: values that belong to a project repo are read from
# that repo's own env files, never restated. The one thing a caller must give us
# is where its tools/ folder is - everything else is derived from that.

# read one KEY from an env file without sourcing it (values are never re-exported)
gm_env_get() { # <file> <key> <default>
  local v=""
  [ -f "$1" ] && v="$(sed -n "s/^[[:space:]]*$2[[:space:]]*=//p" "$1" | tail -1 | tr -d '\r')"
  printf '%s' "${v:-$3}"
}

gm_init() { # call once, first thing, from a tools/ script
  # TOOLS_DIR is the runner folder (…/tools/bash/runner): it owns project.sh,
  # logs.conf and .run/. MANAGER_DIR is the <project>-manager above tools/ and
  # is what project.sh resolves its repo paths against - the wrapper passes both,
  # because how deep a runner sits is a layout question, not a lib question.
  TOOLS_DIR="${GM_TOOLS_DIR:-$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)}"
  MANAGER_DIR="${GM_MANAGER_DIR:-$(cd "$TOOLS_DIR/.." && pwd)}"
  GM_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  RUN_DIR="$TOOLS_DIR/.run"

  GM_IS_WINDOWS=0
  case "$(uname -s)" in
    Darwin) GM_OS=mac ;;
    Linux)  GM_OS=linux ;;
    MINGW*|MSYS*|CYGWIN*) GM_OS=other; GM_IS_WINDOWS=1 ;;
    *)      GM_OS=other ;;
  esac

  : "${GM_TERMINAL:=auto}"
  : "${GM_WAIT_TIMEOUT:=180}"

  GM_WAIT="$GM_LIB_DIR/waitport.sh"
  GM_TAILER="$GM_LIB_DIR/tailer.sh"
  mkdir -p "$RUN_DIR"

  GM_LOG="$RUN_DIR/$(basename "$0" .sh).log"
  : > "$GM_LOG" 2>/dev/null || GM_LOG=""
  set -o errtrace
  trap '_gm_on_err "$?" "$BASH_COMMAND" "${BASH_SOURCE[0]:-?}" "$LINENO"' ERR
  _gm_report_platform
}

# What this machine looks like, so a failure can be read against it. The full
# report goes to the log; on Windows the parts known not to work are said up front.
_gm_report_platform() {
  local t
  _gm_log "platform: uname=$(uname -s) GM_OS=$GM_OS windows=$GM_IS_WINDOWS bash=$BASH_VERSION"
  _gm_log "platform: SHELL=${SHELL:-unset} bash=$(command -v bash) TOOLS_DIR=$TOOLS_DIR"
  for t in docker dotnet wezterm tmux lsof ps netstat taskkill osascript; do
    _gm_log "platform: $t -> $(command -v "$t" 2>/dev/null || echo MISSING)"
  done

  case "$PATH" in
    *$'\n'*)
      local rc_hint=""
      [ -f "$HOME/.bashrc" ] && rc_hint="$(grep -n '^[[:space:]]*echo' "$HOME/.bashrc" | head -3 | sed 's/^/        ~\/.bashrc:/')"
      gm_warn "PATH contains a line break; its first entry is $(printf '%q' "${PATH%%:*}").
  Some shell startup file printed text while PATH was being assembled. env.sh copies
  PATH into every pane, so that broken entry (and the folder it hides) travels along.${rc_hint:+
  echo lines in your ~/.bashrc:
$rc_hint}" ;;
  esac

  [ "$GM_IS_WINDOWS" = 1 ] || return 0
  gm_warn "Windows detected (uname: $(uname -s)) - running under Git Bash / MSYS, GM_OS=other.
  This lib was written and tested on macOS/Linux. Git Bash emulates the shell, but
  the programs it starts (wezterm, docker, dotnet) are native Windows programs, so
  these assumptions do not hold here:
    - a .sh file can be executed directly      (Windows ignores the #! line)
    - paths look like /c/...                   (native programs want C:\\...)
    - lsof, 'ps -o', kill <pid>, tmux exist     (they do not, or see MSYS pids only)
  Each place that hits one of these explains itself below. Log: $GM_LOG"
}

# Infra compose env file: an explicit choice, else the one matching this machine.
# <dir> is the compose folder (e.g. dcm-docker/common-infra).
gm_pick_env_file() { # <dir> [explicit]
  local dir="$1" explicit="${2:-}"
  if [ -n "$explicit" ]; then
    [ -f "$dir/$explicit" ] || gm_die "no such env file: $dir/$explicit"
    printf '%s' "$explicit"; return 0
  fi
  local candidate
  case "$GM_OS" in
    mac)   for candidate in .env.mac .env.ubuntu; do
             [ -f "$dir/$candidate" ] && { printf '%s' "$candidate"; return 0; }
           done ;;
    linux) [ -f "$dir/.env.ubuntu" ] && { printf '%s' .env.ubuntu; return 0; } ;;
    *)     [ -f "$dir/.env.win" ] && { gm_debug "GM_OS=$GM_OS -> picked .env.win in $dir" >&2; printf '%s' .env.win; return 0; } ;;
  esac
  gm_die "no env file found in $dir (looked for .env.mac/.env.ubuntu/.env.win)
  Create one, or pass --infra-env=<name> - it is the file docker compose reads."
}

# A compose stack bind-mounts host paths named in its env file. Create them if we
# can; if we cannot, say so now instead of letting compose fail with a mount error.
# Every *_LOG_PATH / *_DATA_PATH / *_INIT_PATH in the file is a host path the
# stack will bind-mount, so they are discovered rather than listed per project.
gm_prepare_bind_paths() { # <env-file> <base-dir>
  local file="$1" base="$2"
  local key val path bad=""
  [ -f "$file" ] || return 0
  for key in $(grep -oE '^[[:space:]]*[A-Z0-9_]+_(LOG|DATA|INIT)_PATH[[:space:]]*=' "$file" | tr -d ' ='); do
    val="$(gm_env_get "$file" "$key" "")"
    [ -n "$val" ] || continue
    case "$val" in
      /*) path="$val" ;;
      *)  path="$base/$val" ;;   # relative paths resolve against the compose file
    esac
    gm_debug "bind path $(basename "$file"): $key=$val -> checking $path"
    case "$val" in
      [A-Za-z]:[\\/]*)
        gm_warn "$(basename "$file"): $key=$val is a Windows drive path, but this check only
  treats /... as absolute, so it is read as RELATIVE and resolved to:
    $path
  That creates an empty folder literally named '${val%%[\\/]*}' inside $base.
  Docker itself still reads the real $val, so the stack is unaffected -
  only this pre-check looks in (and creates) the wrong place." ;;
      /*)
        if [ "$GM_IS_WINDOWS" = 1 ]; then
          gm_warn "$(basename "$file"): $key=$val is a Unix path on Windows. Two different folders:
    Git Bash (this check, logs.sh) -> $(cygpath -w "$val" 2>/dev/null || echo '?')
    Docker Desktop (the container)  -> $val inside Docker's Linux VM, not on C:
  The mount works, but logs/data are not where the tools on this machine look."
        fi ;;
    esac
    [ -d "$path" ] && continue
    mkdir -p "$path" 2>/dev/null || bad="$bad
    $key=$val"
  done
  [ -z "$bad" ] && return 0
  gm_die "$(basename "$file") has host paths this machine cannot provide:$bad

  docker compose would fail with a mount error. Either create them once
  (sudo mkdir -p … && sudo chown \"\$(id -un)\" …), or give this machine its own
  env file next to the others - on macOS a .env.mac is picked up automatically."
}

# Panes get the tool's own variables only. Nothing that belongs to a project env
# file is re-exported here: docker compose reads those files itself, and a shell
# variable would silently outrank them.
gm_write_env() { # <VAR>…  (plus the ones every pane needs)
  local v
  {
    echo "# generated by $TOOLS_DIR - regenerated on every run"
    printf 'export PATH=%q\n' "$PATH"
    for v in GM_OS TOOLS_DIR MANAGER_DIR GM_LIB_DIR RUN_DIR GM_WAIT GM_TAILER GM_WAIT_TIMEOUT "$@"; do
      [ -n "${!v+set}" ] || continue
      printf 'export %s=%q\n' "$v" "${!v}"
    done
  } > "$RUN_DIR/env.sh"
}

# Fails early with a useful message instead of a broken pane five seconds later.
gm_check_paths() {
  local d
  for d in "$@"; do
    [ -d "$d" ] || gm_die "not found: $d
  Repos are resolved relative to the manager folder ($MANAGER_DIR).
  If your checkout differs, export the matching *_REPO / *_DIR variable
  (tools/README.md lists them) before running."
  done
}

gm_check_docker() {
  command -v docker >/dev/null 2>&1 || gm_die "docker is not on PATH"
  docker info >/dev/null 2>&1 || gm_die "docker daemon is not running (start Docker Desktop / dockerd)"
}

gm_check_dotnet() {
  command -v dotnet >/dev/null 2>&1 || gm_die "dotnet is not on PATH (the backends target net8.0)"
}

gm_check_flutter() {
  command -v flutter >/dev/null 2>&1 || gm_die "flutter is not on PATH (the clients are Flutter web PWAs)"
}

# Networks marked 'external' in an app compose file: on a server Dokploy (or the
# infra stack) creates them, on a laptop nobody does. Networks the infra compose
# declares itself are left alone, so compose keeps ownership of their labels.
gm_ensure_network() { # <name>…
  local n
  for n in "$@"; do
    docker network inspect "$n" >/dev/null 2>&1 && continue
    gm_info "creating missing external network: $n"
    docker network create "$n" >/dev/null
  done
}

# Manual mode binds the service ports on the host itself, so a docker stack
# still holding them is a hard stop - report who has them, not an
# "address already in use" stack trace three panes away.
gm_port_holder() { # <port> -> description, empty if free
  local port="$1" c who
  # A connect test is the only check that sees Docker Desktop's published ports
  # on macOS; lsof is used afterwards only to put a name on the holder.
  (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null || return 0
  exec 3>&- 2>/dev/null
  c="$(docker ps --filter "publish=$port" --format '{{.Names}}' 2>/dev/null | head -1)"
  if [ -n "$c" ]; then printf 'docker container %s' "$c"; return 0; fi
  if command -v lsof >/dev/null 2>&1; then
    who="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -Fc 2>/dev/null | sed -n 's/^c//p' | head -1)"
  elif [ "$GM_IS_WINDOWS" = 1 ]; then
    who="$(_gm_win_listeners "$port")"; who="${who:+$who (seen via netstat; lsof is not available on Windows)}"
  else
    who="another process (lsof not installed, so it cannot be named)"
  fi
  printf '%s' "${who:-another process}"
}

# Read-only, diagnostics only: who listens on <port> according to Windows itself.
# Windows pids are not MSYS pids - MSYS 'ps'/'kill' cannot see or signal them.
_gm_win_listeners() { # <port> -> "pid 1234 (dotnet.exe), …" or empty
  local pid name out=""
  for pid in $(netstat -ano -p tcp 2>/dev/null | tr -d '\r' \
               | awk -v p=":$1" '$4=="LISTENING" && substr($2, length($2)-length(p)+1)==p {print $5}' | sort -u); do
    name="$(tasklist //FI "PID eq $pid" //FO CSV //NH 2>/dev/null | tr -d '\r' | head -1 | cut -d'"' -f2)"
    out="${out:+$out, }pid $pid (${name:-?})"
  done
  printf '%s' "$out"
}

gm_check_ports_free() { # <port>…
  local p holder busy=""
  for p in "$@"; do
    holder="$(gm_port_holder "$p")"
    [ -n "$holder" ] && busy="$busy
    $p  <- $holder"
  done
  [ -z "$busy" ] && return 0
  gm_die "ports needed by the local builds are already taken:$busy

  Stop the docker stack first:  $TOOLS_DIR/stop.sh
  (it leaves the shared database up, which is exactly what manual mode needs.)"
}

# After the docker stacks are down, a forgotten `run-manual.sh` can still be
# holding the service ports. Only ports this project declares are touched, only
# when no container publishes them (compose owns those), and TERM comes before
# KILL so the app gets to shut down cleanly.
gm_kill_port_holders() { # <port>…
  if ! command -v lsof >/dev/null 2>&1; then
    gm_warn "lsof not found - skipped the leftover-process sweep on ports $*.
  What this step does: after 'docker compose down', find whatever still LISTENs on
  this project's ports (usually a forgotten run-manual.sh) and stop it, via
  lsof (pid of the listener) -> ps -o comm= (its name) -> kill (TERM, then KILL).
  Why it cannot run here: lsof ships with macOS/Linux and does not exist in Git Bash$(
    [ "$GM_IS_WINDOWS" = 1 ] && printf '%s' ".
  'ps -o' is not supported by MSYS ps either, and MSYS kill cannot signal native
  Windows processes such as dotnet.exe - the Windows tools are netstat + taskkill")."
    if [ "$GM_IS_WINDOWS" = 1 ]; then
      local p holders found=0
      for p in "$@"; do
        holders="$(_gm_win_listeners "$p")"
        [ -n "$holders" ] || continue
        found=1
        gm_warn "port $p is still held by $holders - NOT stopped (taskkill //PID <pid> //T //F does it by hand)"
      done
      [ "$found" = 1 ] || gm_info "netstat: nothing is listening on ports $* - no leftovers to stop anyway"
    fi
    gm_info "the docker stacks above are down; only this sweep was skipped (--keep-ports skips it on purpose)"
    return 0
  fi
  local p pid cmd pids survivors=""
  for p in "$@"; do
    # a published port belongs to a container; 'docker compose down' handles it
    if [ -n "$(docker ps --filter "publish=$p" --format '{{.Names}}' 2>/dev/null)" ]; then continue; fi
    pids="$(lsof -nP -iTCP:"$p" -sTCP:LISTEN -t 2>/dev/null || true)"
    [ -n "$pids" ] || continue
    for pid in $pids; do
      cmd="$(ps -p "$pid" -o comm= 2>/dev/null | sed 's|.*/||')"
      gm_info "port $p held by pid $pid (${cmd:-unknown}) - stopping it"
      kill "$pid" 2>/dev/null || true
      survivors="$survivors $pid"
    done
  done
  [ -n "$survivors" ] || return 0

  local i alive
  for i in 1 2 3 4 5; do
    alive=""
    for pid in $survivors; do if kill -0 "$pid" 2>/dev/null; then alive="$alive $pid"; fi; done
    [ -n "$alive" ] || { gm_info "local processes stopped"; return 0; }
    sleep 1
  done
  for pid in $alive; do
    gm_warn "pid $pid did not exit on TERM - sending KILL"
    kill -9 "$pid" 2>/dev/null || true
  done
}

# -------------------------------------------------------- service table ----
# A project's tools/project.sh describes itself with these three calls and
# nothing else. Arguments are key=value so a project only spells out what it
# actually has. Indexed arrays only - macOS still ships bash 3.2, which has no
# associative arrays.
SVC_NAMES=(); SVC_DOCKER=(); SVC_PROJECT=(); SVC_CONTAINER=()
SVC_PORT=(); SVC_PORTS=(); SVC_PROFILE=(); SVC_OPTIONAL=(); SVC_ENV=(); SVC_WAITS=(); SVC_KIND=()
WAIT_NAMES=(); WAIT_KEYS=(); WAIT_DEFAULTS=(); WAIT_PORTS=()

# collapse ../.. in a declared path when it exists, so messages and pane scripts
# show the real location
_gm_abs() { if [ -d "$1" ]; then (cd "$1" && pwd); else printf '%s' "$1"; fi; }

# gm_infra dir=<compose folder> [label=infra]
gm_infra() {
  local a k v label=infra dir=""
  for a in "$@"; do
    k="${a%%=*}"; v="${a#*=}"
    case "$k" in
      dir)   dir="$v" ;;
      label) label="$v" ;;
      *) gm_die "gm_infra: unknown key '$k'" ;;
    esac
  done
  [ -n "$dir" ] || gm_die "gm_infra: dir= is required"
  INFRA_DIR="$(_gm_abs "$dir")"; INFRA_LABEL="$label"
}

# gm_wait <name> key=<ENV KEY> default=<port>
# A readiness target a service can name in waits=. The port is read from the
# infra env file when the launcher resolves it, falling back to default=.
gm_wait() {
  local name="$1"; shift
  local a k v key="" def=""
  for a in "$@"; do
    k="${a%%=*}"; v="${a#*=}"
    case "$k" in
      key)     key="$v" ;;
      default) def="$v" ;;
      *) gm_die "gm_wait: unknown key '$k'" ;;
    esac
  done
  WAIT_NAMES+=("$name"); WAIT_KEYS+=("$key"); WAIT_DEFAULTS+=("$def"); WAIT_PORTS+=("$def")
}

# gm_service name=… docker=… [project=…] container=… port=… [ports=a,b]
#            [kind=dotnet|flutter-web] [profile=local] [optional=1]
#            [env=.env.local|-] [waits=a,b]
#   project=   omitted (or "-") means the service has no local build: it runs
#              from docker in both modes.
#   kind=      what manual mode runs from project=:
#                dotnet       (default)  dotnet run --launch-profile <profile>
#                flutter-web  flutter run -d <device> --web-port=<port>
#                             --dart-define-from-file=Resources/Configs/appsettings.<profile>.json
#              In docker mode every kind is 'docker compose up' in docker=.
#   profile=   the environment name: a launchSettings profile for dotnet, an
#              appsettings.<profile>.json for flutter-web.
#   ports=     every port the service binds; port= is the primary one.
#   env=       compose env file for this stack; "-" means it has none.
#   waits=     gm_wait names and/or other service names to come up first.
gm_service() {
  local a k v
  local name="" docker="" project="-" container="" port="" ports="" profile=local optional=0 env="" waits="" kind=dotnet
  for a in "$@"; do
    k="${a%%=*}"; v="${a#*=}"
    case "$k" in
      name|docker|project|container|port|ports|profile|optional|env|waits|kind) eval "$k=\$v" ;;
      *) gm_die "gm_service: unknown key '$k'" ;;
    esac
  done
  [ -n "$name" ]   || gm_die "gm_service: name= is required"
  [ -n "$docker" ] || gm_die "gm_service $name: docker= is required"
  [ -n "$ports" ]  || ports="$port"
  [ -n "$port" ]   || port="${ports%%,*}"
  case "$kind" in dotnet|flutter-web) ;; *) gm_die "gm_service $name: kind must be dotnet or flutter-web (got '$kind')" ;; esac

  SVC_NAMES+=("$name"); SVC_DOCKER+=("$(_gm_abs "$docker")")
  if [ "$project" = "-" ] || [ -z "$project" ]; then SVC_PROJECT+=("-"); else SVC_PROJECT+=("$(_gm_abs "$project")"); fi
  SVC_CONTAINER+=("$container"); SVC_PORT+=("$port"); SVC_PORTS+=("$ports")
  SVC_PROFILE+=("$profile"); SVC_OPTIONAL+=("$optional"); SVC_ENV+=("$env"); SVC_WAITS+=("$waits"); SVC_KIND+=("$kind")
}

# the env file a flutter-web service compiles in, relative to its project dir
gm_flutter_config() { # <profile>
  printf 'Resources/Configs/appsettings.%s.json' "$1"
}

# Resolve every gm_wait target's port from the infra env file (once, after the
# launcher has chosen that file).
gm_resolve_waits() { # <infra env file>
  local i
  for i in "${!WAIT_NAMES[@]}"; do
    WAIT_PORTS[$i]="$(gm_env_get "$1" "${WAIT_KEYS[$i]}" "${WAIT_DEFAULTS[$i]}")"
  done
}

# a waits= token is either a gm_wait name or another service's name
gm_wait_port() { # <token> -> port, empty if unknown
  local t="$1" i
  for i in "${!WAIT_NAMES[@]}"; do
    [ "${WAIT_NAMES[$i]}" = "$t" ] && { printf '%s' "${WAIT_PORTS[$i]}"; return 0; }
  done
  for i in "${!SVC_NAMES[@]}"; do
    [ "${SVC_NAMES[$i]}" = "$t" ] && { printf '%s' "${SVC_PORT[$i]}"; return 0; }
  done
  return 1
}

# ----------------------------------------------------------- pane table ----
PANE_NAMES=(); PANE_TITLES=(); PANE_CMDS=(); PANE_FILES=()

gm_add_pane() { # <name> <title> <command block>
  PANE_NAMES+=("$1"); PANE_TITLES+=("$2"); PANE_CMDS+=("$3")
}

# When the service stops - Ctrl-C included - the pane must NOT close: it drops
# into an interactive shell, in the service's own directory, with the command
# already in history so Up re-runs it. Writes a per-pane rc file to seed that
# history, after sourcing the user's own rc so the shell feels normal.
_gm_write_pane_rc() { # <pane-file-stem> <command> -> the exec line to append
  local stem="$1" cmd="$2" rcdir="$RUN_DIR/rc/$stem"
  mkdir -p "$rcdir"
  case "$(basename "${SHELL:-/bin/bash}")" in
    zsh)
      {
        echo "# generated by $TOOLS_DIR - regenerated on every run"
        echo '[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"'
        echo 'ZDOTDIR="$HOME"          # nested shells get the normal config back'
        printf 'print -s %s\n' "$(gm_sq "$cmd")"
      } > "$rcdir/.zshrc"
      printf 'ZDOTDIR=%q exec zsh -i' "$rcdir"
      ;;
    bash)
      {
        echo "# generated by $TOOLS_DIR - regenerated on every run"
        echo '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
        printf 'history -s %s\n' "$(gm_sq "$cmd")"
      } > "$rcdir/bashrc"
      printf 'exec bash --rcfile %q -i' "$rcdir/bashrc"
      ;;
    *)
      # unknown shell: no history seeding, but still an interactive prompt
      # called inside $(...), so a variable would not survive: warn once via a file
      if [ ! -e "$RUN_DIR/rc/.shell-warned" ]; then
        : > "$RUN_DIR/rc/.shell-warned"
        gm_warn "SHELL=$SHELL: its name '$(basename "${SHELL:-/bin/bash}")' matches neither 'bash' nor 'zsh'$(
          case "$SHELL" in *.exe) printf ' (the .exe suffix Git Bash adds)' ;; esac),
  so panes get a plain '$SHELL -i' after the service stops: no rc file, and ↑ will
  not re-run the service." >&2
      fi
      printf 'exec %q -i' "${SHELL:-/bin/bash}"
      ;;
  esac
}

gm_write_panes() { # <mode>
  local mode="$1" i file stem main execline
  PANE_FILES=()
  rm -f "$RUN_DIR/${mode}-"*.sh   # stale panes from a run with a different --no-* set
  rm -rf "$RUN_DIR/rc" "$RUN_DIR/alive"
  mkdir -p "$RUN_DIR/alive"
  for i in "${!PANE_NAMES[@]}"; do
    stem="${mode}-$((i+1))-${PANE_NAMES[$i]}"
    file="$RUN_DIR/$stem.sh"
    # the service itself is the last line of the block; the readiness waits and
    # the cd above it have already happened by the time the shell takes over
    main="$(printf '%s\n' "${PANE_CMDS[$i]}" | grep -v '^[[:space:]]*$' | tail -1)"
    execline="$(_gm_write_pane_rc "$stem" "$main")"
    {
      echo '#!/usr/bin/env bash'
      echo "# generated by $TOOLS_DIR - regenerated on every run"
      # first thing: prove the terminal could start this script (see _gm_verify_panes)
      printf ': > %q\n' "$RUN_DIR/alive/$stem"
      printf '. %q\n' "$RUN_DIR/env.sh"
      # closing the pane sends SIGHUP; take the child (dotnet/compose) down with us
      echo "trap 'trap - HUP TERM; kill 0' HUP TERM"
      # a non-empty handler, so Ctrl-C reaches the child but leaves this script
      # alive - an ignored trap ('' ) would be inherited and swallow Ctrl-C
      echo "trap ':' INT"
      printf 'printf "\\033]0;%%s\\007" %s\n' "$(gm_sq "${PANE_TITLES[$i]}")"
      printf 'echo "───── %s ─────"\n' "${PANE_TITLES[$i]}"
      printf '%s\n' "${PANE_CMDS[$i]}"
      echo '__st=$?'
      echo 'echo'
      printf 'echo "[%s] stopped (status $__st) · ↑ re-runs it · exit closes the pane"\n' "${PANE_NAMES[$i]}"
      echo 'trap - INT HUP TERM'
      printf '%s\n' "$execline"
    } > "$file"
    chmod +x "$file"
    PANE_FILES+=("$file")
  done
}

# -------------------------------------------------------------- wezterm ----
gm_find_wezterm() {
  if command -v wezterm >/dev/null 2>&1; then command -v wezterm; return 0; fi
  local c
  for c in "/Applications/WezTerm.app/Contents/MacOS/wezterm" \
           "$HOME/Applications/WezTerm.app/Contents/MacOS/wezterm" \
           "/usr/local/bin/wezterm" "/opt/homebrew/bin/wezterm"; do
    [ -x "$c" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

_gm_wezterm_mux_up() { # <wezterm bin>
  "$1" cli list >/dev/null 2>&1 && return 0
  gm_info "starting WezTerm…"
  if [ "$GM_OS" = mac ] && [ -d /Applications/WezTerm.app ]; then
    open -a WezTerm
  else
    ("$1" start --always-new-process >/dev/null 2>&1 &)
  fi
  local i
  for i in $(seq 1 60); do
    "$1" cli list >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  return 1
}

# Balanced tiling for any number of panes: always split the pane with the most
# screen area, along its longer axis. Terminal cells are ~2:1, so a region looks
# square when cols == 2*rows; sizes are read from the real window, not assumed.
# Four panes come out as the 2x2 grid; a fifth or sixth stays readable instead of
# being stacked into a 2-row sliver.
_gm_launch_wezterm() {
  local wez; wez="$(gm_find_wezterm)" || { GM_LAUNCH_WHY="wezterm not found"; return 1; }
  _gm_wezterm_mux_up "$wez" || { GM_LAUNCH_WHY="WezTerm mux did not come up"; gm_warn "$GM_LAUNCH_WHY"; return 1; }

  local ids=() w=() h=() i best bi dir pid
  for i in "${!PANE_FILES[@]}"; do
    gm_debug "wezterm pane $((i+1)): program = ${PANE_FILES[$i]}"
    if [ "$i" -eq 0 ]; then
      pid="$("$wez" cli spawn --new-window -- "${PANE_FILES[$i]}")" || { GM_LAUNCH_WHY="'wezterm cli spawn' failed"; return 1; }
      ids+=("$pid")
      # real cell size of the new window, so the split choices match what you see
      local size; size="$("$wez" cli list 2>/dev/null | awk -v id="$pid" '$3==id {print $5}')"
      w+=("${size%%x*}"); h+=("${size##*x}")
      [ -n "${w[0]}" ] && [ -n "${h[0]}" ] || { w[0]=160; h[0]=48; }
      continue
    fi

    best=-1; bi=0
    local j area
    for j in "${!ids[@]}"; do
      area=$(( w[j] * h[j] ))
      if [ "$area" -gt "$best" ]; then best="$area"; bi="$j"; fi
    done

    if [ "${w[$bi]}" -ge $(( h[bi] * 2 )) ]; then dir=--right; else dir=--bottom; fi
    pid="$("$wez" cli split-pane --pane-id "${ids[$bi]}" "$dir" --percent 50 -- "${PANE_FILES[$i]}")" || { GM_LAUNCH_WHY="'wezterm cli split-pane' failed"; return 1; }
    ids+=("$pid")
    if [ "$dir" = --right ]; then
      w+=($(( w[bi] / 2 ))); h+=(${h[$bi]}); w[$bi]=$(( w[bi] - w[bi] / 2 ))
    else
      w+=(${w[$bi]}); h+=($(( h[bi] / 2 ))); h[$bi]=$(( h[bi] - h[bi] / 2 ))
    fi
  done

  "$wez" cli activate-pane --pane-id "${ids[0]}" >/dev/null 2>&1 || true
  GM_PANE_IDS="${ids[*]}"   # so callers (tools/test.sh) can inspect or close them
  GM_WEZTERM_BIN="$wez"
  gm_info "launched ${#PANE_FILES[@]} panes in WezTerm (pane ids: ${ids[*]})"
}

# A terminal reporting "pane created" only means it tried. Every pane script
# writes .run/alive/<stem> as its first line; a missing marker means the terminal
# could not run the script at all - say which pane, what it was told to run, and
# (WezTerm) what the pane itself shows.
_gm_verify_panes() { # <launcher>
  local launcher="$1" i stem waited=0 missing=() ids=()
  read -r -a ids <<< "${GM_PANE_IDS:-}"
  while :; do
    missing=()
    for i in "${!PANE_FILES[@]}"; do
      stem="$(basename "${PANE_FILES[$i]}" .sh)"
      [ -e "$RUN_DIR/alive/$stem" ] || missing+=("$i")
    done
    if [ "${#missing[@]}" -eq 0 ]; then gm_info "all ${#PANE_FILES[@]} panes started their scripts"; return 0; fi
    [ "$waited" -ge 8 ] && break
    sleep 0.5; waited=$((waited + 1))
  done

  gm_warn "${#missing[@]} of ${#PANE_FILES[@]} panes never started their script (no marker in $RUN_DIR/alive after 4s)."
  local shown
  for i in "${missing[@]}"; do
    gm_warn "pane $((i+1)) [${PANE_NAMES[$i]}]: the terminal was told to run ${PANE_FILES[$i]}"
    if [ "$launcher" = wezterm ] && [ -n "${ids[$i]:-}" ] && [ -n "${GM_WEZTERM_BIN:-}" ]; then
      shown="$("$GM_WEZTERM_BIN" cli get-text --pane-id "${ids[$i]}" 2>/dev/null | grep -v '^[[:space:]]*$' | head -4 | sed 's/^/        | /' || true)"
      if [ -n "$shown" ]; then
        printf '      WezTerm pane %s shows:\n%s\n' "${ids[$i]}" "$shown" >&2
        _gm_log "pane ${ids[$i]} shows: $shown"
      fi
    fi
  done
  if [ "$GM_IS_WINDOWS" = 1 ]; then
    gm_warn "Why (Windows): the terminal starts the pane program with Windows' CreateProcess.
  It was handed a .sh file at an MSYS path (/c/...). Windows cannot execute a .sh
  file (the #! line means nothing to it) and does not know /c/... paths, so the
  process fails at once (exit 1) - before the script's first line runs. Git Bash
  translates this only for programs it runs itself, not for what WezTerm starts.
  What does work: running it through bash, e.g.  bash.exe C:\...\.run\<pane>.sh"
  fi
  gm_die "pane launch failed - the services were NOT started"
}

# ----------------------------------------------------------------- tmux ----
_gm_launch_tmux() { # <session>
  command -v tmux >/dev/null 2>&1 || { GM_LAUNCH_WHY="tmux is not installed"; return 1; }
  local session="$1" i
  if tmux has-session -t "$session" 2>/dev/null; then
    gm_warn "replacing existing tmux session '$session'"
    tmux kill-session -t "$session"
  fi
  tmux new-session -d -s "$session" -n panes "${PANE_FILES[0]}"
  for i in "${!PANE_FILES[@]}"; do
    [ "$i" -eq 0 ] && continue
    tmux split-window -t "$session":0 "${PANE_FILES[$i]}"
    tmux select-layout -t "$session":0 tiled >/dev/null
  done
  tmux select-pane -t "$session":0.0
  GM_TMUX_SESSION="$session"
  gm_info "tmux session '$session' is up"
  [ "${GM_TMUX_NO_ATTACH:-0}" = 1 ] && return 0   # tools/test.sh needs to keep going
  if [ -n "${TMUX:-}" ]; then tmux switch-client -t "$session"; else tmux attach -t "$session"; fi
}

# ------------------------------------------------- plain terminal windows ---
_gm_launch_os() {
  local f
  case "$GM_OS" in
    mac)
      for f in "${PANE_FILES[@]}"; do
        osascript -e "tell application \"Terminal\" to do script \"$f\"" >/dev/null
      done
      osascript -e 'tell application "Terminal" to activate' >/dev/null
      gm_info "opened ${#PANE_FILES[@]} Terminal.app windows"
      ;;
    linux)
      local term=""
      for t in gnome-terminal konsole xfce4-terminal x-terminal-emulator xterm; do
        command -v "$t" >/dev/null 2>&1 && { term="$t"; break; }
      done
      [ -n "$term" ] || { GM_LAUNCH_WHY="no gnome-terminal/konsole/xfce4-terminal/xterm found"; return 1; }
      for f in "${PANE_FILES[@]}"; do
        case "$term" in
          gnome-terminal) gnome-terminal --tab -- "$f" ;;
          konsole)        konsole -e "$f" & ;;
          *)              "$term" -e "$f" & ;;
        esac
      done
      gm_info "opened ${#PANE_FILES[@]} $term windows"
      ;;
    *) GM_LAUNCH_WHY="no plain-terminal launcher for GM_OS=$GM_OS (only mac: Terminal.app, linux: gnome-terminal/konsole/xterm)"
       return 1 ;;
  esac
}

_gm_launch_none() {
  echo
  gm_info "run each of these in its own terminal, in this order:"
  local f
  for f in "${PANE_FILES[@]}"; do printf '  %s\n' "$f"; done
  echo
}

gm_run_panes() { # <mode>
  local mode="$1" session="${GM_SESSION_PREFIX:-tools}-$1"
  # arguments are parsed after gm_init, so the flag is applied here, last
  [ -n "${GM_TERMINAL_CLI:-}" ] && GM_TERMINAL="$GM_TERMINAL_CLI"
  gm_write_panes "$mode"

  if [ "${GM_DRY_RUN:-0}" = 1 ]; then
    local i
    echo
    for i in "${!PANE_NAMES[@]}"; do
      printf '\033[1m── pane %s: %s\033[0m\n' "$((i+1))" "${PANE_TITLES[$i]}"
      printf '%s\n\n' "${PANE_CMDS[$i]}"
    done
    gm_info "dry run - scripts written to $RUN_DIR, nothing launched"
    return 0
  fi

  case "$GM_TERMINAL" in
    wezterm)
      gm_find_wezterm >/dev/null || gm_die "WezTerm not found (not on PATH, and no /Applications/WezTerm.app)"
      _gm_launch_wezterm || gm_die "WezTerm launch failed: ${GM_LAUNCH_WHY:-see log}"
      _gm_verify_panes wezterm ;;
    tmux)
      command -v tmux >/dev/null 2>&1 || gm_die "tmux is not installed (brew install tmux)"
      _gm_launch_tmux "$session" || gm_die "tmux launch failed" ;;
    os)      _gm_launch_os || gm_die "no usable terminal emulator found: ${GM_LAUNCH_WHY:-}"
             _gm_verify_panes os ;;
    none)    _gm_launch_none ;;
    auto)
      # try each in turn; say why one was skipped instead of falling through silently
      GM_LAUNCH_WHY=""
      if _gm_launch_wezterm 2>>"${GM_LOG:-/dev/null}"; then _gm_verify_panes wezterm; return 0; fi
      gm_info "terminal: WezTerm not used - ${GM_LAUNCH_WHY:-see log}"; GM_LAUNCH_WHY=""
      if _gm_launch_tmux "$session"; then return 0; fi
      gm_info "terminal: tmux not used - ${GM_LAUNCH_WHY:-tmux launch failed}"; GM_LAUNCH_WHY=""
      if _gm_launch_os; then _gm_verify_panes os; return 0; fi
      gm_info "terminal: OS terminal windows not used - ${GM_LAUNCH_WHY:-launch failed}"
      _gm_launch_none
      ;;
    *) gm_die "unknown GM_TERMINAL '$GM_TERMINAL' (auto|wezterm|tmux|os|none)" ;;
  esac
}

# --------------------------------------------------------- arg handling ----
gm_parse_common_arg() { # returns 0 if the arg was consumed
  case "$1" in
    --dry-run)      GM_DRY_RUN=1 ;;
    --debug)        GM_DEBUG=1 ;;
    --terminal=*)   GM_TERMINAL_CLI="${1#*=}"; GM_TERMINAL="$GM_TERMINAL_CLI" ;;
    --wezterm)      GM_TERMINAL_CLI=wezterm; GM_TERMINAL=wezterm ;;
    --tmux)         GM_TERMINAL_CLI=tmux;    GM_TERMINAL=tmux ;;
    --no-terminal)  GM_TERMINAL_CLI=none;    GM_TERMINAL=none ;;
    *) return 1 ;;
  esac
  return 0
}
