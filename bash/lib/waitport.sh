#!/usr/bin/env bash
# waitport.sh <label> <host> <port> [timeout-seconds]
# Blocks until a server is really answering on the TCP port. Returns 1 on
# timeout so the caller can decide whether that is fatal.
#
# "The port accepts a connection" is not enough: Docker Desktop's port forwarder
# (macOS and Windows) accepts on a published port as soon as the container
# starts, then closes the connection while the server inside is still booting -
# mysql takes ~5s of that. So a probe counts as up only when the connection
# survives: the server sends something (mysql's greeting) or keeps it open
# (redis, http wait for the client to speak). Closed at once (EOF) = not yet.
label="${1:?label}"; host="${2:?host}"; port="${3:?port}"
timeout="${4:-${GM_WAIT_TIMEOUT:-${DCM_WAIT_TIMEOUT:-180}}}"

probe() { # -> 0 up, 1 refused, 2 accepted but closed at once (forwarder only)
  # braces: the 2>/dev/null must not stick to the shell the way 'exec ... 2>' would
  { exec 3<>"/dev/tcp/$host/$port"; } 2>/dev/null || return 1
  local byte st
  IFS= read -r -t 1 -n 1 byte <&3; st=$?
  exec 3<&- 3>&-
  # 0 = got data, >128 = read timed out on an open connection; both mean a live
  # server. 1 = EOF: something accepted and hung up without a word.
  if [ "$st" -eq 1 ]; then return 2; fi
  return 0
}

printf 'waiting for %s (%s:%s) …' "$label" "$host" "$port"
# wall-clock, not iterations: on Windows a refused connect itself takes ~2s
SECONDS=0
seen_forwarder=0
while [ "$SECONDS" -lt "$timeout" ]; do
  probe; st=$?
  if [ "$st" -eq 0 ]; then
    printf ' up\n'
    exit 0
  fi
  if [ "$st" -eq 2 ]; then printf ':'; seen_forwarder=1; else printf '.'; fi
  sleep 1
done
printf '\n\033[33mwarn:\033[0m %s (%s:%s) did not come up within %ss - continuing anyway\n' "$label" "$host" "$port" "$timeout"
if [ "$seen_forwarder" = 1 ]; then
  printf '      the port accepted connections but closed them at once (shown as ":") - the\n'
  printf '      container is published but the server inside never started listening;\n'
  printf '      check that container'"'"'s own logs.\n'
fi
exit 1
