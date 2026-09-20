#!/usr/bin/env bash
# tailer.sh <glob-with-%DATE%> [lines]
# Waits for the files to exist, lists what it found, then follows them.
# Kept separate so a pane can be re-run with Up after Ctrl-C.
tpl="${1:?glob}"
lines="${2:-200}"
pattern="${tpl//%DATE%/$(date +%Y%m%d)}"

files=()
while :; do
  files=()
  for f in $pattern; do [ -f "$f" ] && files+=("$f"); done   # unquoted: glob on purpose
  [ "${#files[@]}" -gt 0 ] && break
  printf '\rno file matching %s yet · waiting…' "$pattern"
  sleep 3
done

printf '\rfollowing %s file(s):\n' "${#files[@]}"
printf '  %s\n' "${files[@]}"
echo
exec tail -n "$lines" -F "${files[@]}"
