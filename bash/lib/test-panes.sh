#!/usr/bin/env bash
# Exercise the pane launcher with dummy services - no docker, no dotnet.
# Each pane writes a marker file, so this reports whether the panes actually
# RAN, not just whether a window opened.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools.sh"
gm_init

PANES=4
HOLD=60
KEEP=0
TIMEOUT=30
for arg in "$@"; do
  gm_parse_common_arg "$arg" && continue
  case "$arg" in
    --panes=*)   PANES="${arg#*=}" ;;
    --hold=*)    HOLD="${arg#*=}" ;;
    --timeout=*) TIMEOUT="${arg#*=}" ;;
    --keep)      KEEP=1 ;;
    -h|--help)
      cat <<'USAGE'
usage: test.sh [options]

  Launches N dummy panes through the same code path the run-* scripts use,
  waits for every pane to check in, prints the resulting layout, then closes
  them again. Invoked as <project>-manager/tools/test.sh.

options:
  --panes=N       how many panes to open (default 4, the real service count)
  --terminal=X    auto (default) | wezterm | tmux | os | none
  --wezterm       same as --terminal=wezterm
  --tmux          same as --terminal=tmux
  --no-terminal   just write the pane scripts and print their paths
  --hold=SEC      how long each pane stays alive (default 60)
  --timeout=SEC   how long to wait for the panes to check in (default 30)
  --keep          leave the panes open instead of closing them

examples:
  ./test.sh                        # 4 panes, whichever terminal auto picks
  ./test.sh --wezterm --panes=6    # check the tiling past the 2x2
  ./test.sh --tmux --keep          # leave the session up: tmux attach -t dcm-test
USAGE
      exit 0 ;;
    *) gm_die "unknown option: $arg (try --help)" ;;
  esac
done

case "$PANES" in ''|*[!0-9]*) gm_die "--panes must be a number" ;; esac
[ "$PANES" -ge 1 ] || gm_die "--panes must be at least 1"

gm_write_env

MARKER_DIR="$RUN_DIR/test-markers"
rm -rf "$MARKER_DIR"; mkdir -p "$MARKER_DIR"

i=1
while [ "$i" -le "$PANES" ]; do
  gm_add_pane "p$i" "test pane $i of $PANES" \
"echo \"pane $i alive · \$(date '+%H:%M:%S') · shell \$BASH_VERSION\"
echo \"cwd: \$PWD\"
echo \"env.sh reached me: TOOLS_DIR=\$TOOLS_DIR\"
: > \"$MARKER_DIR/p$i\"
echo \"holding for $HOLD s…\"
sleep $HOLD"
  i=$((i + 1))
done

gm_info "test mode · $PANES panes · terminal: $GM_TERMINAL"
GM_TMUX_NO_ATTACH=1 gm_run_panes test

if [ "${GM_DRY_RUN:-0}" = 1 ] || [ "$GM_TERMINAL" = none ]; then
  rm -rf "$MARKER_DIR"
  exit 0
fi

# ------------------------------------------------------------- check in ----
printf '\033[36m==>\033[0m waiting for %s panes to check in' "$PANES"
waited=0
while [ "$waited" -lt "$TIMEOUT" ]; do
  got="$(find "$MARKER_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
  [ "$got" -ge "$PANES" ] && break
  printf '.'
  sleep 1
  waited=$((waited + 1))
done
got="$(find "$MARKER_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
echo

# ---------------------------------------------------------------- layout ----
if [ -n "${GM_PANE_IDS:-}" ] && [ -n "${GM_WEZTERM_BIN:-}" ]; then
  echo
  printf '  %-8s %-9s %s\n' "PANE" "SIZE" "TITLE"
  for id in $GM_PANE_IDS; do
    "$GM_WEZTERM_BIN" cli list | awk -v id="$id" '$3==id {
      t=""; for (i=6; i<=NF; i++) if ($i !~ /^file:\/\//) t = t $i " ";  # drop the CWD column
      printf "  %-8s %-9s %s\n", $3, $5, t
    }'
  done
  echo
elif [ -n "${GM_TMUX_SESSION:-}" ]; then
  echo
  tmux list-panes -t "$GM_TMUX_SESSION":0 -F '  #{pane_id}  #{pane_width}x#{pane_height}  #{pane_title}'
  echo
fi

# ---------------------------------------------------------------- verdict ---
if [ "$got" -ge "$PANES" ]; then
  printf '\033[32mPASS\033[0m  %s/%s panes started and ran their command\n' "$got" "$PANES"
  rc=0
else
  printf '\033[31mFAIL\033[0m  only %s/%s panes checked in within %ss\n' "$got" "$PANES" "$TIMEOUT"
  printf '      pane scripts are in %s - run one by hand to see why\n' "$RUN_DIR"
  rc=1
fi

# ---------------------------------------------------------------- cleanup ---
if [ "$KEEP" = 1 ]; then
  if [ -n "${GM_TMUX_SESSION:-}" ]; then
    gm_info "left open · tmux attach -t $GM_TMUX_SESSION"
  else
    gm_info "left open · close the panes yourself when done"
  fi
else
  if [ -n "${GM_PANE_IDS:-}" ] && [ -n "${GM_WEZTERM_BIN:-}" ]; then
    for id in $GM_PANE_IDS; do "$GM_WEZTERM_BIN" cli kill-pane --pane-id "$id" 2>/dev/null || true; done
    gm_info "closed the test panes"
  elif [ -n "${GM_TMUX_SESSION:-}" ]; then
    tmux kill-session -t "$GM_TMUX_SESSION" 2>/dev/null || true
    gm_info "killed tmux session $GM_TMUX_SESSION"
  else
    gm_warn "separate terminal windows were opened - close them yourself"
  fi
fi

rm -rf "$MARKER_DIR"
exit "$rc"
