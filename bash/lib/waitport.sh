#!/usr/bin/env bash
# waitport.sh <label> <host> <port> [timeout-seconds]
# Blocks until the TCP port accepts a connection. Returns 1 on timeout so the
# caller can decide whether that is fatal.
label="${1:?label}"; host="${2:?host}"; port="${3:?port}"; timeout="${4:-${DCM_WAIT_TIMEOUT:-180}}"

printf 'waiting for %s (%s:%s) …' "$label" "$host" "$port"
i=0
while [ "$i" -lt "$timeout" ]; do
  if (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; then
    exec 3>&- 2>/dev/null
    printf ' up\n'
    exit 0
  fi
  printf '.'
  sleep 1
  i=$((i + 1))
done
printf '\n\033[33mwarn:\033[0m %s (%s:%s) did not come up within %ss - continuing anyway\n' "$label" "$host" "$port" "$timeout"
exit 1
