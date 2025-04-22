#!/usr/bin/env zsh

if ! hyperfine --version >/dev/null 2>&1 ; then
  echo "hyperfine is required to run benchmark (https://github.com/sharkdp/hyperfine)"
  exit 1
fi
#
## shellcheck disable=SC2164
ABSPATH="$(
  cd "${0%/*}" 2>/dev/null
  echo "$PWD"/"${0##*/}"
)"
BASEDIR="$(dirname "$ABSPATH")"

if date --version >/dev/null 2>&1 ; then
  GDATE_CMD=date
else
  if type -p gdate >/dev/null 2>&1 ; then
    GDATE_CMD=gdate
  else
    echo "gnu date needs to be installed (on macos -> brew install coreutils)"
    exit 1
  fi
fi

HYPERFINE_CMD=(hyperfine -i -N \
  -n "Bash  - Epoch Realtime" 'bash -c "t=$EPOCHREALTIME; printf \"%(%FT%T)T.${t#*.}%(%z)T\n\" \"${t%.*}\""' \
  -n "Zsh   - Epoch Realtime" 'zsh -c "print -rP \"%D{%FT%T.%6.%z}\""' \
  -n "Gnu   - date" "$GDATE_CMD +%FT%T.%6N%z" \
)

[[ -x "bin/sdate"  ]] && HYPERFINE_CMD+=(-n "Swift - sdate" bin/sdate)
[[ -x "bin/cdate"  ]] && HYPERFINE_CMD+=(-n "C     - cdate" bin/cdate)
[[ -x "bin/cdate-dynlink" ]]  && HYPERFINE_CMD+=(-n "C     - cdate-dynlink" bin/cdate-dynlink)
[[ -x "bin/ccdate" ]] && HYPERFINE_CMD+=(-n "C++   - ccdate" bin/ccdate)
[[ -x "bin/ccdate-dynlink" ]] && HYPERFINE_CMD+=(-n "C++   - ccdate-dynlink" bin/ccdate-dynlink)
[[ -x "bin/pldate"  ]] && HYPERFINE_CMD+=(-n "Compiled Perl - pldate" bin/pldate)
[[ -x "bin/pydate"  ]] && HYPERFINE_CMD+=(-n "Compiled Python - pydate" bin/pydate)
[[ -x "bin/godate"  ]] && HYPERFINE_CMD+=(-n "Go - godate" bin/godate)
[[ -x "bin/zdate"  ]] && HYPERFINE_CMD+=(-n "Zig    - zdate" bin/zdate)
[[ -x "bin/adate"  ]] && HYPERFINE_CMD+=(-n "Assembly -  adate" bin/adate)


${HYPERFINE_CMD[*]} 2>/dev/null

echo
printf "%s\n" "General output for each logtfmt command"
printf "%-15s %-20s %s\n" "Cmd" "File Size" "Cmd Output"
printf "%-15s %-20s " "Bash"  "$(whence -c bash | xargs -I {} ls -lLk {} | awk '{print $5}')kb" 
bash -c 't=$EPOCHREALTIME; printf "%(%FT%T)T.${t#*.}%(%z)T\n" "${t%.*}"'

printf "%-15s %-20s " "Zsh"   "$(whence -c bash | xargs -I {} ls -lLk {} | awk '{print $5}')kb" 
zsh -c 'print -rP "%D{%FT%T.%6.%z}"'

printf "%-15s %-20s " "$GDATE_CMD" "$(whence -c $GDATE_CMD | xargs -I {} ls -lLk {} | awk '{print $5}')kb" 
$GDATE_CMD +%FT%T.%6N%z

if [ -x "bin/sdate" ] ; then
  printf "%-15s %-20s " "sdate" "$(ls -lLk bin/sdate | awk '{print $5}')kb" 
  bin/sdate
fi

if [ -x "bin/cdate" ] ; then
  printf "%-15s %-20s " "cdate" "$(ls -lLk bin/cdate | awk '{print $5}')kb" 
  bin/cdate
fi

if [ -x "bin/cdate-dynlink" ] ; then
  printf "%-15s %-20s " "cdate-dynlink" "$(ls -lLk bin/cdate-dynlink | awk '{print $5}')kb" 
  bin/cdate-dynlink
fi

if [ -x "bin/ccdate" ] ; then
  printf "%-15s %-20s " "ccdate" "$(ls -lLk bin/ccdate | awk '{print $5}')kb" 
  bin/ccdate
fi

if [ -x "bin/ccdate-dynlink" ] ; then
  printf "%-15s %-20s " "ccdate-dynlink" "$(ls -lLk bin/ccdate-dynlink | awk '{print $5}')kb" 
  bin/ccdate-dynlink
fi


if [ -x "bin/pldate" ] ; then
  printf "%-15s %-20s " "pldate" "$(ls -lLk bin/pldate | awk '{print $5}')kb" 
  bin/pldate
fi

if [ -x "bin/pydate" ] ; then
  printf "%-15s %-20s " "pydate" "$(ls -lLk bin/pydate | awk '{print $5}')kb" 
  bin/pydate
fi

if [ -x "bin/godate" ] ; then
  printf "%-15s %-20s " "godate" "$(ls -lLk bin/godate | awk '{print $5}')kb" 
  bin/godate
fi

if [ -x "bin/zdate" ] ; then
  printf "%-15s %-20s " "zdate" "$(ls -lLk bin/zdate | awk '{print $5}')kb" 
  bin/zdate
fi

if [ -x "bin/adate" ] ; then
  printf "%-15s %-20s " "adate" "$(ls -lLk bin/adate | awk '{print $5}')kb" 
  bin/adate
fi


