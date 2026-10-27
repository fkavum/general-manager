#!/usr/bin/env bash
# sync-upstream.sh — make a twin repo byte-identical to its Crossle upstream, except the paths in its exclude manifest.
#
# Master: general-manager/docs/twin/sync-upstream.sh (card-platform P1d, 2026-10-27).
# Copies (byte-identical): <twin repo>/twin/sync-upstream.sh — card/card-backend, card/batak-client, every later twin.
#
# A twin is a full copy of its upstream working tree (dcm-web → card-backend/web, dcm-game-server → card-backend/game-server,
# dcm-client → batak-client). Every sync overwrites and deletes freely, except:
#   - the paths listed in twin/<kind>.exclude — the manifest IS the definition of "game-specific": not copied from the
#     upstream, never deleted on the twin. A twin-only file must live under one of these paths or the next sync removes it.
#   - what the upstream gitignores (bin/, obj/, Library/ …): never copied, never deleted.
#   - git submodules (CommonClientGame): not copied; the twin pins the same commit itself (--check compares the commits).
#   - .git, .gitmodules, .idea, twin/: never touched.
#
# usage: twin/sync-upstream.sh [--check | --init] [--allow-dirty] [--upstream-root DIR] [kind ...]
#   kind                 web | game-server | client …: one per twin/<kind>.exclude; default = every manifest in twin/
#   (no flag)            sync: refuses a dirty upstream (sharing-hygiene H1), rsync --delete, writes twin/upstream.lock.md
#   --check              dry run with checksums; prints every path that differs from the upstream; exit 1 if any (build gate)
#   --init               first sync into an empty destination; a missing twin/<kind>.exclude is copied from
#                        general-manager/docs/twin/<kind>.exclude; prints the per-app paths still to write
#   --allow-dirty        sync from an uncommitted upstream; the lock row says DIRTY(<n paths>)
#   --upstream-root DIR  the folder holding dcm-web, dcm-game-server, dcm-client (default: the first ancestor of the twin
#                        repo that contains dcm-web; a twin outside the project tree must pass it)
#
# twin/<kind>.exclude: rsync exclude patterns, one per line, anchored at the upstream root with a leading "/"; "#" comments;
# header directives  #@upstream=<upstream folder name>   #@dest=<folder inside the twin repo, "." = the repo root>.
# twin/upstream.lock.md: one row per kind — upstream branch, commit, clean/DIRTY, submodule commits, time, manifest md5.

set -euo pipefail

die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"
lock="$here/upstream.lock.md"

mode=sync; allow_dirty=0; upstream_root=""; kinds=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode=check ;;
    --init) mode=init ;;
    --allow-dirty) allow_dirty=1 ;;
    --upstream-root) shift; upstream_root="${1:-}" ;;
    --upstream-root=*) upstream_root="${1#*=}" ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) kinds+=("$1") ;;
  esac
  shift
done

if [ -z "$upstream_root" ]; then
  d="$repo"
  while [ "$d" != "/" ]; do
    if [ -d "$d/dcm-web" ]; then upstream_root="$d"; break; fi
    d="$(dirname "$d")"
  done
  [ -n "$upstream_root" ] || die "no ancestor of $repo contains dcm-web; pass --upstream-root DIR"
fi
upstream_root="$(cd "$upstream_root" && pwd)"
masters="$upstream_root/general-manager/docs/twin"

if [ ${#kinds[@]} -eq 0 ]; then
  for m in "$here"/*.exclude; do [ -e "$m" ] && kinds+=("$(basename "$m" .exclude)"); done
  [ ${#kinds[@]} -gt 0 ] || die "no twin/<kind>.exclude manifest in $here; run --init <kind>"
fi

md5_of() { if command -v md5 >/dev/null 2>&1; then md5 -q "$1"; else md5sum "$1" | cut -d' ' -f1; fi; }

# kind upstream branch commit tree subs md5 — rewrites this kind's row, keeps the others
write_lock_row() {
  local tmp="$lock.tmp"
  {
    echo "# upstream lock — written by twin/sync-upstream.sh, do not edit by hand"
    echo
    echo "| kind | upstream | branch | commit | tree | submodules | synced (UTC) | manifest md5 |"
    echo "|---|---|---|---|---|---|---|---|"
    if [ -f "$lock" ]; then grep '^| ' "$lock" | grep -v '^| kind |' | grep -v "^| $1 |" || true; fi
    echo "| $1 | $2 | $3 | $4 | $5 | $6 | $(date -u +%Y-%m-%dT%H:%M:%SZ) | $7 |"
  } > "$tmp"
  mv "$tmp" "$lock"
}

rc=0
for kind in "${kinds[@]}"; do
  manifest="$here/$kind.exclude"
  if [ ! -f "$manifest" ]; then
    [ "$mode" = init ] || die "twin/$kind.exclude missing (run --init $kind)"
    [ -f "$masters/$kind.exclude" ] || die "no manifest template $masters/$kind.exclude"
    cp "$masters/$kind.exclude" "$manifest"
    info "$kind: manifest copied from $masters/$kind.exclude — review its game lines"
  fi
  up_name="$(sed -n 's/^#@upstream=//p' "$manifest" | head -1)"
  dest_rel="$(sed -n 's/^#@dest=//p' "$manifest" | head -1)"
  { [ -n "$up_name" ] && [ -n "$dest_rel" ]; } || die "$kind: manifest needs '#@upstream=' and '#@dest=' header lines"
  src="$upstream_root/$up_name"
  [ -e "$src/.git" ] || die "$kind: upstream $src is not a git checkout"
  if [ "$dest_rel" = "." ]; then dest="$repo"; else dest="$repo/$dest_rel"; fi

  branch="$(git -C "$src" rev-parse --abbrev-ref HEAD)"
  commit="$(git -C "$src" rev-parse --short HEAD)"
  dirty_list="$(git -C "$src" status --porcelain --ignore-submodules=none)"
  dirty=0; [ -n "$dirty_list" ] && dirty="$(printf '%s\n' "$dirty_list" | wc -l | tr -d ' ')"
  tree=clean; [ "$dirty" -gt 0 ] && tree="DIRTY($dirty)"
  sub_paths=()
  if [ -f "$src/.gitmodules" ]; then
    while read -r _ p; do sub_paths+=("$p"); done < <(git config -f "$src/.gitmodules" --get-regexp 'submodule\..*\.path')
  fi
  subs="-"
  for p in "${sub_paths[@]:-}"; do
    [ -n "$p" ] || continue
    c="$(git -C "$src/$p" rev-parse --short HEAD 2>/dev/null || echo '?')"
    if [ "$subs" = "-" ]; then subs="$p@$c"; else subs="$subs $p@$c"; fi
  done

  if [ "$mode" != check ] && [ "$dirty" -gt 0 ] && [ "$allow_dirty" -eq 0 ]; then
    printf '%s\n' "$dirty_list" >&2
    die "$kind: $up_name has $dirty uncommitted paths (above); commit them or pass --allow-dirty"
  fi
  [ "$branch" = dev ] || warn "$kind: $up_name is on '$branch', not dev"

  if [ "$mode" = init ]; then
    # empty apart from the twin's own twin/ and .git (a root-level twin runs --init from inside itself)
    if [ -e "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null | grep -v -x -e twin -e .git -e .gitmodules -e .idea -e .DS_Store)" ]; then
      die "$kind: --init needs an empty destination; $dest is not empty"
    fi
    mkdir -p "$dest"
  else
    [ -d "$dest" ] || die "$kind: destination $dest does not exist (run --init $kind first)"
  fi

  # never copied, never deleted: the twin's own git/IDE/twin files, submodules, and everything the upstream gitignores
  ign="$(mktemp)"
  {
    printf '%s\n' '/.git' '/.gitmodules' '.git' '/twin' '/.idea' '.DS_Store'
    for p in "${sub_paths[@]:-}"; do [ -n "$p" ] && printf '/%s\n' "$p"; done
    git -C "$src" status --ignored --porcelain=v1 | sed -n 's|^!! |/|p'
  } > "$ign"
  rsync_args=(-rlt --delete --exclude-from="$manifest" --exclude-from="$ign")

  case "$mode" in
    check)
      diff_lines="$(rsync "${rsync_args[@]}" --checksum --dry-run --itemize-changes "$src/" "$dest/" | grep -v '^\.[df]' || true)"
      for p in "${sub_paths[@]:-}"; do
        [ -n "$p" ] || continue
        if [ "$dest_rel" = "." ]; then tp="$p"; else tp="$dest_rel/$p"; fi
        up_c="$(git -C "$src/$p" rev-parse HEAD 2>/dev/null || echo '?')"
        tw_c="$(git -C "$repo/$tp" rev-parse HEAD 2>/dev/null || echo 'missing')"
        [ "$up_c" = "$tw_c" ] || diff_lines="$(printf '%s\n%s' "$diff_lines" "submodule $tp: twin ${tw_c:0:7} vs upstream ${up_c:0:7}")"
      done
      diff_lines="$(printf '%s\n' "$diff_lines" | sed '/^$/d')"
      if [ -n "$diff_lines" ]; then
        printf '%s\n' "$diff_lines"
        n="$(printf '%s\n' "$diff_lines" | wc -l | tr -d ' ')"
        warn "$kind: $n paths differ from $up_name@$commit ($tree) outside twin/$kind.exclude — run twin/sync-upstream.sh $kind"
        rc=1
      else
        info "$kind: identical to $up_name@$commit ($tree) outside twin/$kind.exclude"
      fi
      ;;
    sync|init)
      info "$kind: $up_name@$commit ($branch, $tree) → $dest"
      changed="$(rsync "${rsync_args[@]}" --itemize-changes "$src/" "$dest/" | grep -v '^\.[df]' || true)"
      n=0; [ -n "$changed" ] && n="$(printf '%s\n' "$changed" | wc -l | tr -d ' ')"
      write_lock_row "$kind" "$up_name" "$branch" "$commit" "$tree" "$subs" "$(md5_of "$manifest")"
      info "$kind: $n paths written or deleted; twin/upstream.lock.md updated"
      if [ "$mode" = init ]; then
        echo
        echo "$kind: per-app paths (twin/$kind.exclude) — the twin writes these itself, they are never synced:"
        grep -v '^[[:space:]]*#' "$manifest" | grep -v '^[[:space:]]*$' | sed 's/^/    /'
        for p in "${sub_paths[@]:-}"; do
          [ -n "$p" ] || continue
          if [ "$dest_rel" = "." ]; then tp="$p"; else tp="$dest_rel/$p"; fi
          url="$(git -C "$src/$p" remote get-url origin 2>/dev/null || git config -f "$src/.gitmodules" --get "submodule.$p.url")"
          c="$(git -C "$src/$p" rev-parse HEAD 2>/dev/null || echo '<commit>')"
          echo "$kind: submodule to add to the twin repo (same commit as the upstream):"
          printf '    git submodule add -b dev %s %s && git -C %s checkout %s\n' "$url" "$tp" "$tp" "$c"
        done
      fi
      ;;
  esac
  rm -f "$ign"
done
exit $rc
