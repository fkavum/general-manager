#!/usr/bin/env bash
# Central control for every Flutter client's app icon. See README.md next to this file.
#
#   ./icons.sh list                 apps, clients and the artwork each one has here
#   ./icons.sh apply <app|all>      push script + artwork into the client, generate, overlay hand-drawn, install
#   ./icons.sh check [app|all]      is each client in sync with this folder? (exit 1 if not)
#
# Artwork lives here, per app: <app>/source.png (+ optional hand-drawn masters <app>/icon_*.png).
# Needs bash and swift (Xcode command-line tools); runs on macOS.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"          # /Users/fkavum/Documents/project
SCRIPT="$HERE/app_icons.swift"
REGISTRY="$HERE/apps.txt"

die() { echo "✗ $*" >&2; exit 1; }

# Registry lines "<app> <client>" without comments / blanks.
entries() { grep -vE '^[[:space:]]*(#|$)' "$REGISTRY"; }

client_of() {
  local app="$1" line
  line=$(entries | awk -v a="$app" '$1 == a { print $2 }')
  [ -n "$line" ] || die "unknown app '$app' — add it to apps.txt (known: $(entries | awk '{print $1}' | xargs))"
  echo "$ROOT/$line"
}

# Expands "all" to every registered app.
apps_for() {
  if [ "${1:-all}" = "all" ]; then entries | awk '{print $1}'; else echo "$1"; fi
}

overrides_of() { find "$HERE/$1" -maxdepth 1 -name 'icon_*.png' 2>/dev/null | sort; }

cmd_list() {
  entries | while read -r app client; do
    local n; n=$(overrides_of "$app" | wc -l | tr -d ' ')
    local src="missing"
    [ -f "$HERE/$app/source.png" ] && src=$(sips -g pixelWidth -g pixelHeight "$HERE/$app/source.png" |
      awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w "x" h}')
    printf "%-10s %-24s source %-10s hand-drawn %s\n" "$app" "$client" "$src" "$n"
  done
}

cmd_apply() {
  local app="$1" client icons
  client=$(client_of "$app")
  icons="$client/Resources/AppIcon"
  [ -f "$client/pubspec.yaml" ] || die "$app: $client is not a Flutter client"
  [ -f "$HERE/$app/source.png" ] || die "$app: missing $HERE/$app/source.png"
  # Reject a wrong-sized hand-drawn master before touching the client (icon_<N>x<N>… must be N×N).
  local f name want have
  for f in $(overrides_of "$app"); do
    name=$(basename "$f")
    want=$(echo "$name" | sed -nE 's/.*_([0-9]+)x([0-9]+)(_opaque)?\.png$/\1x\2/p')
    have=$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w "x" h}')
    [ -n "$want" ] || die "$app: $name has no <N>x<N> size in its name"
    [ "$want" = "$have" ] || die "$app: $name is $have, expected $want"
  done

  echo "• $app → $client"
  mkdir -p "$client/tool" "$icons"
  cp "$SCRIPT" "$client/tool/app_icons.swift"
  cp "$HERE/$app/source.png" "$icons/source.png"
  (cd "$client" && swift tool/app_icons.swift generate)

  # Hand-drawn masters replace the generated ones; a name the script does not generate is a typo.
  for f in $(overrides_of "$app"); do
    name=$(basename "$f")
    [ -f "$icons/$name" ] || die "$app: $name is not a master the script generates (see $icons/README.md)"
    cp "$f" "$icons/$name"
    echo "  hand-drawn $name"
  done
  (cd "$client" && swift tool/app_icons.swift install)
}

cmd_check() {
  local app="$1" client icons ok=0 f
  client=$(client_of "$app")
  icons="$client/Resources/AppIcon"
  same() { cmp -s "$1" "$2" || { echo "  ✗ $3"; ok=1; }; }
  same "$SCRIPT" "$client/tool/app_icons.swift" "tool/app_icons.swift differs from the master"
  same "$HERE/$app/source.png" "$icons/source.png" "Resources/AppIcon/source.png differs from $app/source.png"
  for f in $(overrides_of "$app"); do
    same "$f" "$icons/$(basename "$f")" "Resources/AppIcon/$(basename "$f") differs from the hand-drawn one"
  done
  if [ $ok -eq 0 ]; then echo "✓ $app in sync"; else echo "✗ $app out of sync — run ./icons.sh apply $app"; fi
  return $ok
}

case "${1:-}" in
  list) cmd_list ;;
  apply)
    [ -n "${2:-}" ] || die "usage: ./icons.sh apply <app|all>"
    for a in $(apps_for "$2"); do cmd_apply "$a"; done ;;
  check)
    rc=0
    for a in $(apps_for "${2:-all}"); do cmd_check "$a" || rc=1; done
    exit $rc ;;
  *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
