#!/usr/bin/env bash
# The Definition of done of a change to the shared Flutter packages (flutter-core P5): every package under
# testapp/packages/ (dcx_flutter_core, dcx_flutter_localization, …), their vendored copies, the byte-identical client
# files, and every Flutter client's analyze / test / theme gate (+ the l10n gate where the client localizes).
# Read-only: it syncs nothing.
#
#   bash general-manager/bash/flutter-core-check.sh [--fast]     (--fast skips flutter test)
#
# ci-gates' check-all.sh calls this for its Flutter part.
set -uo pipefail

PROJECT="$(cd "$(dirname "$0")/../.." && pwd)"
PACKAGES="$PROJECT/testapp/packages"
CORE="$PACKAGES/dcx_flutter_core"
CLIENTS=("testapp/client" "flash/client" "tapit/tapit-client")
FAST=0; [[ "${1:-}" == "--fast" ]] && FAST=1

failed=()
step() { # step <label> <dir> <command...>
  local label="$1" dir="$2"; shift 2
  printf '▶ %-45s ' "$label"
  local out
  if out="$(cd "$dir" && "$@" 2>&1)"; then
    echo "✔"
  else
    echo "✖"; echo "$out" | tail -25 | sed 's/^/    /'; failed+=("$label")
  fi
}

for pkg in "$PACKAGES"/*/; do
  name="$(basename "$pkg")"
  step "$name: pub get"  "$pkg" flutter pub get
  step "$name: analyze"  "$pkg" flutter analyze
  [[ $FAST == 1 ]] || step "$name: test" "$pkg" flutter test
done
step "vendored copies in sync"  "$CORE" bash tool/vendor.sh check
step "client templates in sync" "$CORE" bash tool/templates.sh check

for c in "${CLIENTS[@]}"; do
  dir="$PROJECT/$c"
  step "$c: pub get"     "$dir" flutter pub get
  # Infos are not fatal: Hunter carries ~128 pre-existing lint infos (2026-09-27); errors and warnings fail.
  step "$c: analyze"     "$dir" flutter analyze --no-fatal-infos
  [[ $FAST == 1 ]] || step "$c: test" "$dir" flutter test
  step "$c: theme gate"  "$dir" bash tool/check_theme.sh
  # Only clients that localize have the gate (dcx_flutter_localization in their pubspec).
  if grep -qE '^\s+dcx_flutter_localization:' "$dir/pubspec.yaml" 2>/dev/null; then
    step "$c: l10n gate" "$dir" bash tool/check_l10n.sh
  fi
done

echo
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "✖ ${#failed[@]} step(s) failed: ${failed[*]}"
  exit 1
fi
echo "✔ flutter-core gate green"
