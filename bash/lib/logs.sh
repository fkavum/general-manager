#!/usr/bin/env bash
# One pane per service, each following that service's logs. Read-only: nothing
# is started, stopped or rebuilt, so it is safe against a backend someone else
# started. Sources come from the project's tools/logs.conf.
set -euo pipefail
[ -n "${GM_TOOLS_DIR:-}" ] || { echo "logs.sh must be invoked from a tools/ wrapper" >&2; exit 1; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.sh"
gm_init

MODE=auto
SERVICES=""
WITH_INFRA=0
for arg in "$@"; do
  gm_parse_common_arg "$arg" && continue
  case "$arg" in
    --docker)     MODE=docker ;;
    --manual)     MODE=manual ;;
    --services=*) SERVICES="$(printf '%s' "${arg#*=}" | tr ',' ' ')" ;;
    --with-infra) WITH_INFRA=1 ;;
    --lines=*)    LOG_LINES_CLI="${arg#*=}" ;;
    -h|--help)
      cat <<'USAGE'
usage: logs.sh [options]

  Opens one pane per service, each following that service's logs. It only
  reads - nothing is started, stopped or rebuilt.

  --docker        follow the docker stacks' logs
  --manual        follow what the local dotnet processes write
                  (default: whichever one is actually running)
  --services=a,b  which services (default: every one in tools/project.sh)
  --with-infra    add a pane for the shared database
  --lines=N       existing lines to show first (default from logs.conf)
  --terminal=X    auto (default) | wezterm | tmux | os | none
  --dry-run       print what each pane would run, launch nothing

  Sources live in tools/logs.conf (override in tools/logs.local.conf).
USAGE
      exit 0 ;;
    *) gm_die "unknown option: $arg (try --help)" ;;
  esac
done

# shellcheck disable=SC1091
. "$TOOLS_DIR/project.sh"
: "${GM_SESSION_PREFIX:=${PROJECT:-tools}}"

for f in "$TOOLS_DIR/logs.conf" "$TOOLS_DIR/logs.local.conf"; do
  [ -f "$f" ] || continue
  # shellcheck disable=SC1090
  set -a; . "$f"; set +a
done
: "${LOG_LINES:=200}"
# logs.conf is sourced after the arguments, so a flag has to win over it
if [ -n "${LOG_LINES_CLI:-}" ]; then LOG_LINES="$LOG_LINES_CLI"; fi

_running() { docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$1"; }

if [ "$MODE" = auto ]; then
  MODE=manual
  for i in "${!SVC_NAMES[@]}"; do
    if _running "${SVC_CONTAINER[$i]}"; then MODE=docker; break; fi
  done
  gm_info "mode: $MODE (detected)"
else
  gm_info "mode: $MODE"
fi

[ -n "$SERVICES" ] || SERVICES="${SVC_NAMES[*]}"
# one pane per readiness target (mysql, redis, …) rather than a single "infra",
# because an infra stack can be more than one container
if [ "$WITH_INFRA" = 1 ]; then
  if [ "${#WAIT_NAMES[@]}" -gt 0 ]; then SERVICES="$SERVICES ${WAIT_NAMES[*]}"; else SERVICES="$SERVICES infra"; fi
fi

for svc in $SERVICES; do
  key="$(printf '%s_%s' "$MODE" "$svc" | tr '[:lower:]-' '[:upper:]_')"
  src="${!key-}"
  if [ -z "$src" ]; then
    gm_warn "$svc: no log source for $MODE mode ($key is empty in logs.conf) - skipped"
    continue
  fi
  case "$src" in
    docker:*)
      gm_add_pane "$svc" "$svc logs · ${src#docker:}" \
"docker logs -f --tail \"\$LOG_LINES\" ${src#docker:}"
      ;;
    *)
      gm_add_pane "$svc" "$svc logs · $src" \
"\"\$GM_TAILER\" $(gm_sq "$src") \"\$LOG_LINES\""
      ;;
  esac
done

if [ "${#PANE_NAMES[@]}" -eq 0 ]; then
  hint="  Add the shared database with --with-infra"
  [ "$MODE" = manual ] && hint="$hint, or follow the containers with --docker.
  In manual mode the services usually log to the console, so the run-manual.sh
  pane is the place to watch."
  gm_die "nothing to follow in $MODE mode - every selected service was skipped.
$hint"
fi

gm_write_env PROJECT LOG_LINES
gm_info "following ${#PANE_NAMES[@]} service(s) · $LOG_LINES lines of history"
gm_run_panes logs
