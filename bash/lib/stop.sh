#!/usr/bin/env bash
# 'docker compose down' for every stack this project's tools/ can start.
# Local dotnet processes live in their own panes - close those.
set -euo pipefail
[ -n "${GM_TOOLS_DIR:-}" ] || { echo "stop.sh must be invoked from a tools/ wrapper" >&2; exit 1; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.sh"
gm_init

STOP_INFRA=0    # the infra is shared between projects; never taken down by default
KILL_PORTS=1    # also clear leftovers from a forgotten run-manual.sh
VOLUMES=""
GM_APP_ENV=".env.local"   # namespaced like run.sh: never shadow a stack's own APP_ENV
INFRA_ENV_OVERRIDE=""
WITH=""
for arg in "$@"; do
  case "$arg" in
    --stop-infra)  STOP_INFRA=1 ;;
    --keep-infra)  STOP_INFRA=0 ;;   # accepted for symmetry; already the default
    --keep-ports)  KILL_PORTS=0 ;;
    --volumes)     VOLUMES="--volumes" ;;
    --with=*)      WITH="$WITH $(printf '%s' "${arg#*=}" | tr ',' ' ')" ;;
    --app-env=*)   GM_APP_ENV="${arg#*=}" ;;
    --infra-env=*) INFRA_ENV_OVERRIDE="${arg#*=}" ;;
    -h|--help)
      cat <<'USAGE'
usage: stop.sh [--stop-infra] [--volumes] [--with=a,b] [--app-env=F] [--infra-env=F]

  Runs 'docker compose down' in each service folder - the same command you
  would run by hand there. The shared database is LEFT RUNNING by default:
  the other projects (flash / hunter / tapit / racer) use the same instance.

  After the stacks are down it also checks the ports this project declares and
  stops anything still listening on them - typically a run-manual.sh you forgot
  about. Ports a container publishes are left to compose.

  --stop-infra   also take the shared database down (affects every project)
  --keep-ports   do not touch leftover local processes
  --volumes      also drop the app stacks' anonymous volumes
  --with=a,b     also stop these optional services
USAGE
      exit 0 ;;
    *) gm_die "unknown option: $arg (try --help)" ;;
  esac
done

# shellcheck disable=SC1091
. "$TOOLS_DIR/project.sh"
gm_check_docker

down() { # <label> <dir> [compose args…]
  local label="$1" dir="$2"; shift 2
  [ -d "$dir" ] || { gm_warn "skipping $label - $dir not found"; return 0; }
  gm_info "docker compose down: $label"
  ( cd "$dir" && docker compose "$@" down $VOLUMES ) || gm_warn "$label: down failed"
}

# services first, infra last - the apps depend on it
for ((i=${#SVC_NAMES[@]}-1; i>=0; i--)); do
  if [ "${SVC_OPTIONAL[$i]}" = 1 ]; then
    case " $WITH " in *" ${SVC_NAMES[$i]} "*) ;; *) continue ;; esac
  fi
  down "${SVC_NAMES[$i]}" "${SVC_DOCKER[$i]}" --env-file "$GM_APP_ENV"
done

if [ "$STOP_INFRA" = 1 ]; then
  gm_warn "$INFRA_LABEL is shared with the other projects - taking it down affects them too"
  INFRA_ENV_FILE="$(gm_pick_env_file "$INFRA_DIR" "$INFRA_ENV_OVERRIDE")"
  down infra "$INFRA_DIR" --env-file "$INFRA_ENV_FILE"
else
  gm_info "left running: $INFRA_LABEL (shared - pass --stop-infra to take it down)"
fi

# --- leftovers from a manual run -------------------------------------------
if [ "$KILL_PORTS" = 1 ]; then
  PORTS=()
  for i in "${!SVC_NAMES[@]}"; do
    for p in $(printf '%s' "${SVC_PORTS[$i]}" | tr ',' ' '); do
      if [ -n "$p" ]; then PORTS+=("$p"); fi
    done
  done
  if [ "${#PORTS[@]}" -gt 0 ]; then gm_kill_port_holders "${PORTS[@]}"; fi
fi
