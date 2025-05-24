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

function fmtlist() {
  local LEFT=$1
  local RIGHT=$2

  printf "%-19s - %s" "$1" "$2"
}

declare -A CMD_LIST

CMD_LIST[bash]='bash -c "t=$EPOCHREALTIME; printf \"%(%FT%T)T.${t#*.}%(%z)T\n\" \"${t%.*}\""'
CMD_LIST[zsh]='zsh -c "print -rP \"%D{%FT%T.%6.%z}\""' 
CMD_LIST[Gnu]="$GDATE_CMD +%FT%T.%6N%z"

declare -A LIST=()

LIST[adate]="$(fmtlist "Assembly" "adate")"
LIST[adate_arm64]="$(fmtlist "Assembly (arm64)" "adate_arm64")"
LIST[adate_x86]="$(fmtlist "Assembly (x86-64)" "adate_x86")"
LIST[bash]="$(fmtlist "Bash" "Epoch Realtime")"
LIST[ccdate]="$(fmtlist "C++" "ccdate")"
LIST[ccdate-dynlink]="$(fmtlist "C++" "ccdate-dynlink")"
LIST[cdate]="$(fmtlist "C" "cdate")"
LIST[cdate-dynlink]="$(fmtlist "C" "cdate-dynlink")"
LIST[Gnu]="$(fmtlist "Gnu date" "date")"
LIST[godate]="$(fmtlist "Go" "godate")"
LIST[pldate]="$(fmtlist "Compiled Perl" "pldate")"
LIST[pydate]="$(fmtlist "Compiled Python" "pydate")"
LIST[rdate]="$(fmtlist "Rust" "rdate")"
LIST[sdate]="$(fmtlist "Swift" "sdate")"
LIST[zdate]="$(fmtlist "Zig" "zdate")"
LIST[zsh]="$(fmtlist "Zsh" "Epoch Realtime")"

declare -a HYPERFINE_CMD=(hyperfine -i -N)

#for key val in "${(@kv)LIST}"; do
#  if [ -n "${CMD_LIST[$key]}" ] ; then
#    HYPERFINE_CMD+=(-n "$val" "${CMD_LIST[$key]}")
#  else
#    [[ -x "bin/$key" ]] && HYPERFINE_CMD+=(-n "$val" bin/$key)
#  fi
#done
#
#
for key in "${(@ko)LIST}"; do
  if [ -n "${CMD_LIST[$key]}" ] ; then
    HYPERFINE_CMD+=(-n "${LIST[$key]}" "${CMD_LIST[$key]}")
  else
    [[ -x "bin/$key" ]] && HYPERFINE_CMD+=(-n "${LIST[$key]}" bin/$key)
  fi
done

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

for x in $(cd bin; ls -1 | sort) ; do
  printf "%-15s %-20s " "$x" "$(ls -lLk bin/$x | awk '{print $5}')kb" 
  bin/$x
done

