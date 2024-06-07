#!/usr/bin/env zsh

if ! hyperfine --version >/dev/null 2>&1 ; then
  echo "hyperfine is required to run benchmark"
  exit 1
fi
#
## shellcheck disable=SC2164
ABSPATH="$(
  cd "${0%/*}" 2>/dev/null
  echo "$PWD"/"${0##*/}"
)"
BASEDIR="$(dirname "$ABSPATH")"

hyperfine -i -N \
  -n "Bash  - Epoch Realtime" 'bash -c "t=$EPOCHREALTIME; printf \"%(%FT%T)T.${t#*.}%(%z)T\n\" \"${t%.*}\""' \
  -n "Zsh   - Epoch Realtime" 'zsh -c "print -rP \"%D{%FT%T.%6.%z}\""' \
  -n "Gnu   - gdate" 'gdate +%FT%T.%6N%z' \
  -n "Swift - sdate" bin/sdate \
  -n "C     - cdate" bin/cdate \
  -n "C++   - ccdate" bin/ccdate \
  2>/dev/null

echo
printf "%s\n" "General Output for each Benchmarked Commands"
printf "%-8s %-20s %s\n" "Cmd" "File Size" "Cmd Output"
printf "%-8s %-20s " "Bash"  "$(whence -c bash | xargs -I {} ls -lLk {} | awk '{print $5}')kb" 
bash -c 't=$EPOCHREALTIME; printf "%(%FT%T)T.${t#*.}%(%z)T\n" "${t%.*}"'

printf "%-8s %-20s " "Zsh"   "$(whence -c bash | xargs -I {} ls -lLk {} | awk '{print $5}')kb" 
zsh -c 'print -rP "%D{%FT%T.%6.%z}"'

printf "%-8s %-20s " "gdate" "$(whence -c gdate | xargs -I {} ls -lLk {} | awk '{print $5}')kb" 
gdate +%FT%T.%6N%z

printf "%-8s %-20s " "sdate" "$(ls -lLk bin/sdate | awk '{print $5}')kb" 
bin/sdate

printf "%-8s %-20s " "cdate" "$(ls -lLk bin/cdate | awk '{print $5}')kb" 
bin/cdate

printf "%-8s %-20s " "ccdate" "$(ls -lLk bin/ccdate | awk '{print $5}')kb" 
bin/ccdate


