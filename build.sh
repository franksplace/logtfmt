#!/usr/bin/env bash
#shellcheck disable=SC2317,SC2120

###########################
# General Variables
###########################
DATELOG=true
# shellcheck disable=SC2164
ABSPATH="$(
  cd "${0%/*}" 2>/dev/null
  echo "$PWD"/"${0##*/}"
)"
BASEDIR="$(dirname "$ABSPATH")"
APP_NAME="$(basename "$BASEDIR")"

###########################
# Functions
###########################
declare -g -f LOGTFMT color mlog cecho signit

function LOGTFMT() {
  local t=$EPOCHREALTIME
  printf "%(%FT%T)T.${t#*.}%(%z)T" "${t%.*}"
}

function color {
  if ! $COLOR_FLAG 2>/dev/null ; then
    if [ -z "$CLICOLOR" ] ; then
      return
    fi
  fi

  declare -a codes
  while [[ $# -gt 0 ]]; do
    case "$1" in
    # see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    bold) codes+=(1) ;;
    faint) codes+=(2) ;;
    italic) codes+=(3) ;;
    underline) codes+=(4) ;;
    blink) codes+=(5) ;;
    invert) codes+=(7) ;;
    black) codes+=(30) ;;
    red) codes+=(31) ;;
    green) codes+=(32) ;;
    yellow) codes+=(33) ;;
    blue) codes+=(34) ;;
    magenta) codes+=(35) ;;
    cyan) codes+=(36) ;;
    white) codes+=(37) ;;
    gray) codes+=(90) ;;
    brightred) codes+=(91) ;;
    brightgreen) codes+=(92) ;;
    brightyellow) codes+=(93) ;;
    brightblue) codes+=(94) ;;
    brightmagenta) codes+=(95) ;;
    brightcyan) codes+=(96) ;;
    brightwhite) codes+=(97) ;;
    esac
    shift
  done
  declare IFS=';'
  echo -en '\033['"${codes[*]}"'m'
}

function cecho() {
  declare color="$1"
  shift
  color "$color"
  echo -en "$@"
  color
}

function mlog() {
  [[ -z "$1" ]] && return 1
  declare TYPE="$1" MSG="$2" CODE="$3"
  [[ -z "$MSG" ]] && MSG=$TYPE && TYPE=NORMAL
  TYPE=${TYPE^^}
  declare type_check_reg="^(SUCCESS|INFO|ERROR|FATAL|WARN|CRITICAL|NORMAL)$"
  if [[ ! "$TYPE" =~ $type_check_reg ]]; then
    if $DEBUG && [ "$TYPE" == "DEBUG" ]; then
      true
    else
      return
    fi
  fi

  declare TYPE_OUT=
  declare ERRFLAG=false
  case "$TYPE" in
  INFO | SUCCESS) TYPE_OUT=$(cecho green "$TYPE ") ;;
  WARN) TYPE_OUT=$(cecho yellow "$TYPE ") ;;
  DEBUG) TYPE_OUT=$(cecho magenta "$TYPE ") ;;
  FATAL | ERROR | CRITICAL)
    TYPE_OUT=$(cecho red "$TYPE ")
    ERRFLAG=true
    ;;
  *) TYPE_OUT="" ;;
  esac

  if $DATELOG; then
    OUT="$(printf "%-32s %-10s %-17s %-s\n" "$(LOGTFMT)" "$APP_NAME" "$TYPE_OUT" "$MSG")"
  else
    OUT="$(printf "%-10s %-17s %-s" "$APP_NAME" "$TYPE_OUT" "$MSG")"
  fi
  if $ERRFLAG; then
    echo -e "$OUT" >&2
  else
    echo -e "$OUT"
  fi

  [[ -n "$CODE" ]] && exit "$CODE"
}

function signit() {
  local APP=$1
  if [ -z "$APP" ] || [ ! -r "$APP" ]; then
    if [ -z "$APP" ]; then
      mlog ERROR "app needs to be defined and reable to signit"
    else
      mlog ERROR "app ($APP) needs to be reable to signit"
    fi
    return 1
  fi
  if codesign -f --sign "$CODE_SIGNATURE" --options=runtime --timestamp "$APP"; then
    if codesign --display --verbose=4 "$APP"; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

# Export the functions for children and when soucred
export -f mlog
export -f color
export -f cecho
export -f signit
export -f LOGTFMT
###########################
# Main
###########################
# If this script is being sorced for the functions don't include the main section
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return

if $DEBUG; then
  mlog DEBUG "MODE ENABLED"
  mlog DEBUG "BASEDIR=$BASEDIR"
  mlog DEBUG "APP_NAME=$APP_NAME"
fi

B_OPTS=("$(cd "$BASEDIR" && find . -type f -mindepth 2 -maxdepth 2 -name build.sh 2>/dev/null | xargs dirname | sed -e 's#./##g')")
if [ -z "$1" ]; then
  echo "Valid build targets are "
  for b in "${B_OPTS[@]}"; do
    echo "$b"
  done
  exit
fi

if [ "${1^^}" == "ALL" ]; then
  set -- ${B_OPTS[@]}
fi

for target in "$@"; do
  if [ ! -d "$target" ] && [ ! -x "$target/build.sh" ]; then
    mlog ERROR "$target is not a valid build target"
  else
    mlog INFO "Running build target $target"
    "$target"/build.sh
  fi
done
