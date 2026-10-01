#!/usr/bin/env bash
# Make every repo a project needs match origin/<branch> exactly — the "I just
# switched PCs" reset. Shared by every <project>-manager/tools/bash/sync/sync.sh;
# the project's repos are declared in repos.sh next to that wrapper.
#
# Per repo: fetch, report what would be lost, then abort any merge/rebase,
# reset --hard, clean -fd, checkout -B <branch> origin/<branch>, and the same
# for every submodule. A repo whose origin has no <branch> goes to its default
# branch instead. Ignored files (.env.*, Library/, bin/, node_modules/) are kept.
#
# The whole body is one function called on the last line, so resetting the
# general-manager repo itself mid-run cannot change the code being executed.
set -euo pipefail

gm_die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
gm_info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
gm_warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
usage: sync.sh <branch> [--yes] [--dry-run] [--only=a,b] [--no-fetch]

  Resets every repo of this project to origin/<branch> and updates submodules.
  Uncommitted changes and untracked (not ignored) files are DISCARDED.
  Local commits that are on no remote are kept on a backup/sync-<time> branch.

  First it fetches and prints, per repo, what would be lost; nothing is touched
  until you answer y. A repo that is missing is cloned from its url=.

  <branch>     the branch to land on; a repo whose origin lacks it uses its
               default branch (origin/HEAD) and says so
  --yes        do not ask
  --dry-run    only fetch and report
  --only=a,b   just these repos (names as printed: folder names)
  --no-fetch   use the remote refs already here (offline)
USAGE
}

# repos.sh calls this once per repo:  gm_repo <dir> [url=<clone url>]
REPO_DIRS=(); REPO_URLS=()
gm_repo() {
  local dir="$1" a url=""; shift
  for a in "$@"; do
    case "$a" in
      url=*) url="${a#url=}" ;;
      *) gm_die "gm_repo: unknown key '${a%%=*}'" ;;
    esac
  done
  REPO_DIRS+=("$dir"); REPO_URLS+=("$url")
}

# collapse ../.. ; a missing folder resolves through its parent
abs() {
  if [ -d "$1" ]; then (cd "$1" && pwd)
  elif [ -d "$(dirname "$1")" ]; then printf '%s/%s' "$(cd "$(dirname "$1")" && pwd)" "$(basename "$1")"
  else printf '%s' "$1"; fi
}

# the branch to land on: <branch> if origin has it, else origin's default
target_of() { # <dir> <branch>
  local d="$1" b="$2" head
  if git -C "$d" show-ref --verify --quiet "refs/remotes/origin/$b"; then printf '%s' "$b"; return; fi
  head="$(git -C "$d" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -z "$head" ]; then
    git -C "$d" remote set-head origin --auto >/dev/null 2>&1 || true
    head="$(git -C "$d" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  fi
  head="${head#origin/}"
  if [ -z "$head" ]; then
    for head in main master dev; do
      git -C "$d" show-ref --verify --quiet "refs/remotes/origin/$head" && break
      head=""
    done
  fi
  printf '%s' "$head"
}

# merge / rebase / cherry-pick / revert / am / bisect left half done
in_progress() { # <dir>
  local d="$1" gd ops=""
  gd="$(git -C "$d" rev-parse --absolute-git-dir)"
  [ -f "$gd/MERGE_HEAD" ] && ops="$ops merge"
  { [ -d "$gd/rebase-merge" ] || [ -d "$gd/rebase-apply" ]; } && ops="$ops rebase/am"
  [ -f "$gd/CHERRY_PICK_HEAD" ] && ops="$ops cherry-pick"
  [ -f "$gd/REVERT_HEAD" ] && ops="$ops revert"
  [ -f "$gd/BISECT_LOG" ] && ops="$ops bisect"
  printf '%s' "${ops# }"
}

# commits reachable from HEAD or the local <target> branch but from no remote
unpushed() { # <dir> <target>
  local d="$1" t="$2" refs="HEAD"
  git -C "$d" show-ref --verify --quiet "refs/heads/$t" && refs="$refs refs/heads/$t"
  # shellcheck disable=SC2086
  git -C "$d" rev-list --count $refs --not --remotes 2>/dev/null || echo 0
}

count_lines() { grep -c . || true; }

sync_one() { # <dir> <target> <stamp>
  local d="$1" t="$2" stamp="$3" sha short
  # keep commits no remote has; a branch costs nothing and survives gc
  for sha in $( (git -C "$d" rev-parse HEAD; git -C "$d" rev-parse --verify --quiet "refs/heads/$t") | sort -u); do
    [ "$(git -C "$d" rev-list --count "$sha" --not --remotes)" = 0 ] && continue
    short="$(git -C "$d" rev-parse --short "$sha")"
    git -C "$d" branch -f "backup/sync-$stamp-$short" "$sha" || return 1
    printf '   saved %s on backup/sync-%s-%s\n' "$short" "$stamp" "$short"
  done
  git -C "$d" merge --abort       >/dev/null 2>&1
  git -C "$d" rebase --abort      >/dev/null 2>&1
  git -C "$d" cherry-pick --abort >/dev/null 2>&1
  git -C "$d" revert --abort      >/dev/null 2>&1
  git -C "$d" am --abort          >/dev/null 2>&1
  git -C "$d" bisect reset        >/dev/null 2>&1
  git -C "$d" reset --hard --quiet &&
  git -C "$d" clean -fd --quiet &&
  git -C "$d" checkout --quiet --force -B "$t" --track "origin/$t" &&
  git -C "$d" clean -fd --quiet || return 1
  if [ -f "$d/.gitmodules" ]; then
    git -C "$d" submodule sync --quiet --recursive &&
    git -C "$d" submodule update --init --recursive --force &&
    git -C "$d" submodule foreach --quiet --recursive 'git reset --hard --quiet && git clean -fd --quiet' || return 1
  fi
  printf '   at %s\n' "$(git -C "$d" log -1 --format='%h %s')"
}

main() {
  local BRANCH="" YES=0 DRY=0 FETCH=1 ONLY="" arg
  for arg in "$@"; do
    case "$arg" in
      --yes|-y)   YES=1 ;;
      --dry-run)  DRY=1 ;;
      --no-fetch) FETCH=0 ;;
      --only=*)   ONLY=" $(printf '%s' "${arg#*=}" | tr ',' ' ') " ;;
      -h|--help)  usage; exit 0 ;;
      -*)         gm_die "unknown option: $arg (try --help)" ;;
      *) [ -z "$BRANCH" ] || gm_die "one branch only (got '$BRANCH' and '$arg')"; BRANCH="$arg" ;;
    esac
  done
  [ -n "$BRANCH" ] || { usage >&2; exit 1; }
  [ -n "${GM_SYNC_DIR:-}" ] || gm_die "sync.sh must be invoked from a tools/bash/sync wrapper"
  MANAGER_DIR="${GM_MANAGER_DIR:?}"
  command -v git >/dev/null || gm_die "git not found"

  # shellcheck disable=SC1091
  . "$GM_SYNC_DIR/repos.sh"
  [ "${#REPO_DIRS[@]}" -gt 0 ] || gm_die "repos.sh declared no repos"

  # ------------------------------------------------- resolve + dedupe ----
  # Several declared folders can live in one repo (flash-web and client are
  # both in flash/); the repo is synced once, under its top-level folder name.
  local NAMES=() DIRS=() URLS=() i d top name seen
  for ((i=0; i<${#REPO_DIRS[@]}; i++)); do
    d="$(abs "${REPO_DIRS[$i]}")"
    top="$d"
    if [ -d "$d" ]; then
      top="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
      [ -n "$top" ] || { gm_warn "skipping $d — not a git repo"; continue; }
    fi
    seen=0
    for d in "${DIRS[@]+"${DIRS[@]}"}"; do [ "$d" = "$top" ] && seen=1; done
    [ "$seen" = 0 ] || continue
    name="$(basename "$top")"
    if [ -n "$ONLY" ]; then case "$ONLY" in *" $name "*) ;; *) continue ;; esac; fi
    NAMES+=("$name"); DIRS+=("$top"); URLS+=("${REPO_URLS[$i]}")
  done
  [ "${#DIRS[@]}" -gt 0 ] || gm_die "nothing to sync${ONLY:+ (--only=$ONLY matched no repo)}"

  # ----------------------------------------------------------- evaluate ----
  # OK: 1 sync, 2 clone first then sync, 0 skip
  local TARGETS=() OK=() risky=0 tgt cur ops dirty untracked ahead sub status
  for ((i=0; i<${#DIRS[@]}; i++)); do
    d="${DIRS[$i]}"; name="${NAMES[$i]}"
    TARGETS+=(""); OK+=(0)
    if [ ! -e "$d" ]; then
      if [ -n "${URLS[$i]}" ]; then
        printf '\n\033[1m%s\033[0m  missing  →  clone %s, then origin/%s (or its default branch)\n' "$name" "${URLS[$i]}" "$BRANCH"
        OK[$i]=2
      else
        gm_warn "$name: $d missing and repos.sh gives no url= — skipped"
      fi
      continue
    fi

    if [ "$FETCH" = 1 ]; then
      git -C "$d" fetch --prune --quiet origin || { gm_warn "$name: fetch failed — skipped"; continue; }
    fi
    tgt="$(target_of "$d" "$BRANCH")"
    [ -n "$tgt" ] || { gm_warn "$name: origin has neither '$BRANCH' nor a default branch — skipped"; continue; }
    TARGETS[$i]="$tgt"; OK[$i]=1

    cur="$(git -C "$d" symbolic-ref --quiet --short HEAD || echo "detached@$(git -C "$d" rev-parse --short HEAD)")"
    ops="$(in_progress "$d")"
    status="$(git -C "$d" status --porcelain --ignore-submodules=all)"
    read -r dirty untracked <<<"$(printf '%s\n' "$status" | awk '/^\?\?/{u++; next} /./{d++} END{print d+0, u+0}')"
    ahead="$(unpushed "$d" "$tgt")"
    sub=0
    if [ -f "$d/.gitmodules" ]; then
      sub="$( (git -C "$d" submodule foreach --quiet --recursive 'git status --porcelain' 2>/dev/null || true) | count_lines)"
    fi

    printf '\n\033[1m%s\033[0m  %s  →  origin/%s' "$name" "$cur" "$tgt"
    [ "$tgt" = "$BRANCH" ] || printf '  \033[33m(no %s on origin — default branch)\033[0m' "$BRANCH"
    printf '\n'
    if [ -z "$ops$status" ] && [ "$ahead" = 0 ] && [ "$sub" = 0 ]; then
      printf '   clean — %s\n' "$(git -C "$d" rev-list --count "HEAD..origin/$tgt") commit(s) to pull"
      continue
    fi
    risky=1
    [ -z "$ops" ]          || printf '   \033[31m%s in progress — will be aborted\033[0m\n' "$ops"
    [ "$dirty" = 0 ]       || printf '   \033[31m%s changed file(s) — discarded\033[0m\n' "$dirty"
    [ "$untracked" = 0 ]   || printf '   \033[31m%s untracked file(s) — deleted\033[0m\n' "$untracked"
    [ "$sub" = 0 ]         || printf '   \033[31m%s change(s) inside submodules — discarded\033[0m\n' "$sub"
    [ "$ahead" = 0 ]       || printf '   \033[33m%s unpushed commit(s) — kept on a backup/sync-* branch\033[0m\n' "$ahead"
    [ -z "$status" ]       || printf '%s\n' "$status" | head -15 | sed 's/^/     /'
    [ "$(printf '%s\n' "$status" | count_lines)" -le 15 ] || printf '     …\n'
  done
  printf '\n'

  [ "$DRY" = 0 ] || { gm_info "dry run — nothing changed"; exit 0; }
  if [ "$YES" = 0 ]; then
    local n=0
    for ((i=0; i<${#OK[@]}; i++)); do [ "${OK[$i]}" = 0 ] || n=$((n+1)); done
    [ "$n" -gt 0 ] || gm_die "nothing to sync"
    local q="sync $n repo(s) to the targets above?"
    [ "$risky" = 0 ] || q="DISCARD the local work listed above and $q"
    printf '%s [y/N] ' "$q"
    local reply=""; read -r reply || true
    case "$reply" in y|Y|yes) ;; *) gm_info "aborted — nothing changed"; exit 1; esac
  fi

  # ------------------------------------------------------------- nuke ----
  local stamp failed=0
  stamp="$(date +%Y%m%d-%H%M%S)"
  for ((i=0; i<${#DIRS[@]}; i++)); do
    d="${DIRS[$i]}"; name="${NAMES[$i]}"; tgt="${TARGETS[$i]}"
    if [ "${OK[$i]}" = 2 ]; then
      gm_info "$name: cloning ${URLS[$i]}"
      mkdir -p "$(dirname "$d")"
      git clone --quiet "${URLS[$i]}" "$d" || { gm_warn "$name: clone failed"; failed=1; continue; }
      tgt="$(target_of "$d" "$BRANCH")"
      [ -n "$tgt" ] && OK[$i]=1
    fi
    [ "${OK[$i]}" = 1 ] || continue
    gm_info "$name → origin/$tgt"
    # commands are &&-chained: set -e does not apply inside a tested function
    if ! sync_one "$d" "$tgt" "$stamp"; then
      gm_warn "$name: sync failed — see the git output above"; failed=1
    fi
  done

  [ "$failed" = 0 ] || gm_die "some repos did not sync"
  gm_info "done"
}

main "$@"; exit
