#!/usr/bin/env bash
# Generic launcher shared by every <project>-manager/tools.
#   run.sh docker   - every service in Docker, attached
#   run.sh manual   - infra in Docker, the services built and run from source
# The project describes itself in tools/project.sh; nothing here is project specific.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.sh"
[ -n "${GM_TOOLS_DIR:-}" ] || { echo "run.sh must be invoked from a tools/ wrapper (GM_TOOLS_DIR unset)" >&2; exit 1; }
gm_init
MODE="${1:?usage: run.sh <docker|manual> [options]}"; shift

BUILD="--build"
WITH_INFRA=1
WATCH=0
WITH=""
APP_ENV=".env.local"
INFRA_ENV_OVERRIDE=""
for arg in "$@"; do
  gm_parse_common_arg "$arg" && continue
  case "$arg" in
    --no-build)    BUILD="" ;;
    --no-infra)    WITH_INFRA=0 ;;
    --watch)       WATCH=1 ;;
    --with=*)      WITH="$WITH $(printf '%s' "${arg#*=}" | tr ',' ' ')" ;;
    --infra-env=*) INFRA_ENV_OVERRIDE="${arg#*=}" ;;
    --app-env=*)   APP_ENV="${arg#*=}" ;;
    -h|--help)
      cat <<USAGE
usage: run-$MODE.sh [options]

  $( [ "$MODE" = docker ] \
       && echo "Every service in Docker, attached (no -d), one service per pane." \
       || echo "Infra in Docker; every service built and run from source, one per pane." )
  Panes come up together; each waits for the ports it needs before starting.

options:
  --no-infra        assume the shared infra is already running
  --with=a,b        also start these optional services (see tools/project.sh)
  --infra-env=F     infra env file (default: .env.mac on macOS, else .env.ubuntu/.env.win)
  --app-env=F       env file the app stacks use (default .env.local)
$( [ "$MODE" = docker ] \
     && echo "  --no-build        skip 'docker compose --build'" \
     || echo "  --watch           use 'dotnet watch' instead of 'dotnet run'" )
  --terminal=X      auto (default) | wezterm | tmux | os | none
  --wezterm | --tmux | --no-terminal
  --dry-run         print what each pane would run, launch nothing
USAGE
      exit 0 ;;
    *) gm_die "unknown option: $arg (try --help)" ;;
  esac
done

[ "$MODE" = docker ] || [ "$MODE" = manual ] || gm_die "mode must be docker or manual"

# shellcheck disable=SC1091
. "$TOOLS_DIR/project.sh"
: "${GM_SESSION_PREFIX:=${PROJECT:-tools}}"
[ -n "${INFRA_DIR:-}" ] || gm_die "project.sh did not call gm_infra"
[ "${#SVC_NAMES[@]}" -gt 0 ] || gm_die "project.sh declared no services"

INFRA_ENV_FILE="$(gm_pick_env_file "$INFRA_DIR" "$INFRA_ENV_OVERRIDE")"
gm_resolve_waits "$INFRA_DIR/$INFRA_ENV_FILE"

# ------------------------------------------------------- which services ----
PICKED=()
for i in "${!SVC_NAMES[@]}"; do
  if [ "${SVC_OPTIONAL[$i]}" = 1 ]; then
    case " $WITH " in *" ${SVC_NAMES[$i]} "*) ;; *) continue ;; esac
  fi
  PICKED+=("$i")
done
[ "${#PICKED[@]}" -gt 0 ] || gm_die "no services selected"

gm_check_docker
if [ "$MODE" = manual ]; then gm_check_dotnet; fi

CHECK=()
for i in "${PICKED[@]}"; do
  if [ "$MODE" = docker ] || [ "${SVC_PROJECT[$i]}" = "-" ]; then
    gm_check_paths "${SVC_DOCKER[$i]}"
  else
    gm_check_paths "${SVC_PROJECT[$i]}"
    for p in $(printf '%s' "${SVC_PORTS[$i]}" | tr ',' ' '); do CHECK+=("$p"); done
  fi
done
if [ "$WITH_INFRA" = 1 ]; then gm_check_paths "$INFRA_DIR"; fi

if [ "${GM_DRY_RUN:-0}" != 1 ]; then
  if [ "$MODE" = manual ] && [ "${#CHECK[@]}" -gt 0 ]; then gm_check_ports_free "${CHECK[@]}"; fi
  gm_ensure_network ${GM_EXTERNAL_NETWORKS:-dokploy-network}
  if [ "$WITH_INFRA" = 1 ]; then
    gm_prepare_bind_paths "$INFRA_DIR/$INFRA_ENV_FILE" "$INFRA_DIR"
  fi
  for i in "${PICKED[@]}"; do
    [ "$MODE" = docker ] || [ "${SVC_PROJECT[$i]}" = "-" ] || continue
    svc_env="${SVC_ENV[$i]:-$APP_ENV}"
    [ "$svc_env" = "-" ] && continue
    gm_prepare_bind_paths "${SVC_DOCKER[$i]}/$svc_env" "${SVC_DOCKER[$i]}"
  done
fi

gm_write_env PROJECT INFRA_DIR INFRA_ENV_FILE INFRA_LABEL APP_ENV

# ---------------------------------------------------------------- panes ----
# No -p anywhere: each stack keeps the project name compose derives from its own
# folder, so these panes drive the same containers as running compose by hand.
INFRA_TITLE=""
for i in "${!WAIT_NAMES[@]}"; do
  [ -n "$INFRA_TITLE" ] && INFRA_TITLE="$INFRA_TITLE, "
  INFRA_TITLE="$INFRA_TITLE${WAIT_NAMES[$i]} ${WAIT_PORTS[$i]}"
done
[ -n "$INFRA_TITLE" ] || INFRA_TITLE="$INFRA_LABEL"

if [ "$WITH_INFRA" = 1 ]; then
  gm_add_pane infra "infra · $INFRA_TITLE" \
"cd $(gm_sq "$INFRA_DIR")
docker compose --env-file \"\$INFRA_ENV_FILE\" up"
fi

DOTNET_CMD="dotnet run"
if [ "$WATCH" = 1 ]; then DOTNET_CMD="dotnet watch"; fi

svc_env=""; env_arg=""
for i in "${PICKED[@]}"; do
  name="${SVC_NAMES[$i]}"
  # each service waits only for what it declared, so all panes can start at once
  wait_line=""
  for dep in $(printf '%s' "${SVC_WAITS[$i]}" | tr ',' ' '); do
    dep_port="$(gm_wait_port "$dep")" || gm_die "service $name: waits=$dep is neither a gm_wait target nor a service"
    [ -n "$dep_port" ] || gm_die "service $name: waits=$dep has no port"
    if [ -n "$wait_line" ]; then wait_line="$wait_line
"; fi
    wait_line="$wait_line\"\$GM_WAIT\" $dep 127.0.0.1 $dep_port || true"
  done

  if [ "$MODE" = docker ] || [ "${SVC_PROJECT[$i]}" = "-" ]; then
    # a service can carry its own env file; "-" means the stack has none
    svc_env="${SVC_ENV[$i]:-$APP_ENV}"
    if [ "$svc_env" = "-" ]; then env_arg=""; else env_arg="--env-file $(gm_sq "$svc_env")"; fi
    body="cd $(gm_sq "${SVC_DOCKER[$i]}")
docker compose $env_arg up $BUILD"
    title="$name · :${SVC_PORTS[$i]} (docker)"
  else
    body="cd $(gm_sq "${SVC_PROJECT[$i]}")
$DOTNET_CMD --launch-profile ${SVC_PROFILE[$i]}"
    title="$name · :${SVC_PORTS[$i]} (--env=${SVC_PROFILE[$i]})"
  fi
  if [ -n "$wait_line" ]; then body="$wait_line
$body"; fi
  gm_add_pane "$name" "$title" "$body"
done

gm_info "$MODE mode · ${PROJECT:-project} · ${#PANE_NAMES[@]} panes"
gm_run_panes "$MODE"
