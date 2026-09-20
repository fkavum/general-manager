#!/usr/bin/env bash
# Golden test for what the launcher GENERATES - not for what it launches.
#
# test-panes.sh proves the panes open and run; nothing proved what was IN them.
# That gap shipped a real bug: run.sh kept its --app-env value in a variable
# called APP_ENV and wrote it to .run/env.sh, every pane sourced it, and docker
# compose resolves ${APP_ENV} from the environment BEFORE --env-file - so the
# client image baked appsettings..env.local.json and the build died. Against a
# golden file that bug is a one-line diff.
#
# Runs the real run.sh --dry-run against a throwaway fixture project, with stub
# docker/dotnet/flutter on PATH, so this needs no daemon, no SDKs and touches
# nothing outside its temp dir. Then it diffs .run/env.sh and every generated
# pane script against testdata/golden/, and enforces the env.sh export contract.
#
#   ./test-generate.sh            check; exits 1 on any diff
#   ./test-generate.sh --update   rewrite the goldens - then READ the diff
set -euo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOLDEN="$LIB/testdata/golden"
UPDATE=0
case "${1:-}" in
  --update)  UPDATE=1 ;;
  -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "")        ;;
  *)         echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
esac

PASS=0; FAIL=0
pass() { printf '\033[32mok\033[0m   %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '\033[31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }

# ---------------------------------------------------------------- fixture ----
# A project with every shape a real project.sh uses: shared infra + a wait, a
# dotnet service with both a Docker stack and a local project, an opt-in
# docker-only service with no env file, and a flutter-web client.
# cd/pwd, because $TMPDIR often ends in a slash and the launcher resolves its
# paths - a doubled slash here would leave raw temp paths in the golden files
ROOT="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/gm-golden.XXXXXX")" && pwd)"
trap 'rm -rf "$ROOT"' EXIT
ROOT_PHYS="$(cd "$ROOT" && pwd -P)"
RUNNER="$ROOT/manager/tools/bash/runner"

mkdir -p "$RUNNER" "$ROOT/infra" "$ROOT/api/Docker/Main" "$ROOT/api/Src/Main" \
         "$ROOT/extra" "$ROOT/client/Docker" "$ROOT/client/Resources/Configs" "$ROOT/bin"

echo 'MYSQL_PORT=20010' > "$ROOT/infra/.env.test"
# the variable the launcher must never shadow - a client image bakes
# appsettings.<APP_ENV>.json in, and compose reads it from THIS file
echo 'APP_ENV=local' > "$ROOT/client/Docker/.env.local"
echo 'APP_ENV=ci'    > "$ROOT/client/Docker/.env.ci"
echo '{ "API_BASE_URL": "http://localhost:20200/api" }' \
  > "$ROOT/client/Resources/Configs/appsettings.local.json"

cat > "$RUNNER/project.sh" <<'EOF'
# Fixture project for test-generate.sh. Not a real stack; it exists to pin the
# generated output of every gm_service shape.
PROJECT=fixture
gm_infra dir="$MANAGER_DIR/../infra" label="shared mysql"
gm_wait  mysql key=MYSQL_PORT default=20010
gm_service name=api container=fixture-api port=20200 waits=mysql \
           docker="$MANAGER_DIR/../api/Docker/Main" project="$MANAGER_DIR/../api/Src/Main"
gm_service name=extra container=fixture-extra port=20201 optional=1 env=- \
           docker="$MANAGER_DIR/../extra"
gm_service name=client kind=flutter-web container=fixture-client port=20221 waits=api \
           docker="$MANAGER_DIR/../client/Docker" project="$MANAGER_DIR/../client"
EOF

# docker info / command -v dotnet / command -v flutter, without any of them installed
for t in docker dotnet flutter; do printf '#!/bin/sh\nexit 0\n' > "$ROOT/bin/$t"; chmod +x "$ROOT/bin/$t"; done

# ------------------------------------------------------------ normalizing ----
# Absolute paths, $PATH and the host OS are the only things that differ between
# two correct runs, so they are the only things flattened. ($SHELL is pinned to
# bash in generate(), so the pane rc lines stay comparable.)
normalize() {
  sed -e "s|$ROOT_PHYS|<ROOT>|g" -e "s|$ROOT|<ROOT>|g" -e "s|$LIB|<LIB>|g" \
      -e 's|^export PATH=.*|export PATH=<PATH>|' \
      -e 's|^export GM_OS=.*|export GM_OS=<OS>|'
}

generate() { # <mode> [run.sh args…] - the launcher, exactly as a wrapper calls it
  rm -rf "$RUNNER/.run"
  local mode="$1"; shift
  env -i PATH="$ROOT/bin:/usr/bin:/bin:/usr/sbin:/sbin" HOME="$ROOT" SHELL=/bin/bash TERM=dumb \
      GM_TOOLS_DIR="$RUNNER" GM_MANAGER_DIR="$ROOT/manager" \
      "$LIB/run.sh" "$mode" --dry-run --no-terminal --infra-env=.env.test "$@" >/dev/null
}

capture() { # everything the run left behind, in one normalized stream
  local f
  {
    echo "=== .run/env.sh"
    cat "$RUNNER/.run/env.sh"
    for f in "$RUNNER"/.run/*-*.sh; do
      echo "=== .run/$(basename "$f")"
      cat "$f"
    done
  } | normalize
}

check() { # <golden name> <text>
  local name="$1" text="$2" file="$GOLDEN/$1.txt"
  printf '%s\n' "$text" > "$ROOT/$name.actual"
  if [ "$UPDATE" = 1 ]; then cp "$ROOT/$name.actual" "$file"; pass "$name.txt updated"; return 0; fi
  [ -f "$file" ] || { fail "$name: no golden yet - run --update and review the diff"; return 0; }
  if diff -u "$file" "$ROOT/$name.actual" > "$ROOT/$name.diff"; then
    pass "$name"
  else
    fail "$name: generated output changed"
    sed 's/^/    /' "$ROOT/$name.diff"
  fi
}

# --------------------------------------------------------------- the cases ----
# docker mode, defaults: the everyday command
generate docker;                                   DOCKER="$(capture)"
# manual mode: dotnet run + flutter run bodies, and the SDK checks
generate manual;                                   MANUAL="$(capture)"
# the flags that change what is generated: opt-in service, a different app env
# file, no --build
generate docker --with=extra --app-env=.env.ci --no-build; OPTS="$(capture)"

check docker "$DOCKER"
check manual "$MANUAL"
check docker-opts "$OPTS"

# ------------------------------------------------- the env.sh export contract --
# Panes source .run/env.sh, so every name exported there reaches docker compose
# and outranks --env-file. Only the launcher's own variables belong in it, and
# anything new must be GM_-prefixed. The bare names below are the reviewed
# legacy exceptions - do not add to them, add a GM_ one.
ALLOWED='^(GM_[A-Z0-9_]+|PATH|TOOLS_DIR|MANAGER_DIR|RUN_DIR|PROJECT|INFRA_DIR|INFRA_ENV_FILE|INFRA_LABEL)$'
generate docker
bad=""
while read -r name; do
  printf '%s' "$name" | grep -Eq "$ALLOWED" || bad="$bad $name"
done < <(grep '^export ' "$RUNNER/.run/env.sh" | sed 's/^export \([A-Za-z0-9_]*\)=.*/\1/')
if [ -z "$bad" ]; then
  pass "env.sh exports only launcher-owned names"
else
  fail "env.sh exports names a pane must not see:$bad
    Every pane sources env.sh, and docker compose resolves \${VAR} from the
    environment before --env-file - so a stack's own variable of that name is
    silently overridden (this is exactly how APP_ENV broke the client build).
    Prefix the launcher's variable with GM_ (see README, 'Conventions')."
fi

# ------------------------------------------------------------------ result ----
echo
if [ "$FAIL" = 0 ]; then
  printf '\033[36m==>\033[0m %s checks passed\n' "$PASS"
else
  printf '\033[31m==>\033[0m %s passed, %s failed\n' "$PASS" "$FAIL"
  echo "    Intended change? Re-run with --update and commit the golden diff."
  exit 1
fi
