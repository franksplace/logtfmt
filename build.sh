#!/usr/bin/env bash
#shellcheck disable=SC2317,SC2120

###########################
# General Variables
###########################
[[ -n "$CODE_DEBUG" ]] && set -x
trap "set +x" HUP INT QUIT TERM EXIT

declare -g -x GCC_MIN_VER=8
declare -g -x GCC_VENDOR='' # if we want to at some future date require GNU set it like the CPP_VENDOR
declare -g -x CPP_MIN_VER=14
declare -g -x CPP_VENDOR='Free Software Foundation'

declare -g -x DATELOG=true
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
declare -g -f LOGTFMT bcheck color mlog cecho signit gccVerCheck c++VerCheck stripit

# little function to mimic boolean checks if user did not properly set 0/false or 1/true
function bcheck() {
  local out=''

  [[ -z "$1" ]] && echo "Usage:bcheck <variable> (without \$)" && return 2
  # if variable is not defined automatically false
  if ! out=$(typeset -p "$1" 2>/dev/null >&1); then
    return 1
  fi

  local var=''
  var="$(echo "${out,,}" | cut -d= -f2- | tr -d \")"
  if [[ "$var" =~ ^(true|1)$ ]]; then
    return 0
  fi
  # everything else is considered false (thus name=asdf, name=111 , etc)
  return 1
}

function LOGTFMT() {
  local t=$EPOCHREALTIME
  printf "%(%FT%T)T.${t#*.}%(%z)T" "${t%.*}"
}

function color {
  if ! $COLOR_FLAG 2>/dev/null; then
    if [ -z "$CLICOLOR" ]; then
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
    if bcheck DEBUG && [ "$TYPE" == "DEBUG" ]; then
      true
    elif bcheck VERBOSE && [ "$TYPE" == "VERBOSE" ]; then
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
  VERBOSE) TYPE_OUT=$(cecho brightcyan "$TYPE") ;;
  FATAL | ERROR | CRITICAL)
    TYPE_OUT=$(cecho red "$TYPE ")
    ERRFLAG=true
    ;;
  *) TYPE_OUT="" ;;
  esac

  if [[ $MSG == *$'\n'* ]]; then
    BIFS=$IFS
    IFS=$'\n'
    for x in $MSG; do
      mlog "$TYPE" "$x"
    done
    IFS=$BIFS
  else
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
  fi

  [[ -n "$CODE" ]] && exit "$CODE"
}

function signit() {
  declare -x APP=$1
  if [ -z "$APP" ] || [ ! -r "$APP" ]; then
    if [ -z "$APP" ]; then
      mlog ERROR "app needs to be defined and reable to signit"
    else
      mlog ERROR "app ($APP) needs to be reable to signit"
    fi
    return 1
  fi

  declare -a FULL_CMD=()
  declare -x out=''

  local FULL_CMD=(codesign -f --sign "$CODE_SIGNATURE" --options=runtime --timestamp "$APP")

  mlog VERBOSE "Code Sign Command:${FULL_CMD[*]}"
  mlog DEBUG "Code Sign Command:${FULL_CMD[*]}"
  if out="$("${FULL_CMD[@]}" 2>&1)"; then
    FULL_CMD=(codesign --display --verbose=4 "$APP")
    mlog SUCCESS "Successfully signed $APP with ${CODE_SIGNATURE}'s signature"
    mlog VERBOSE "Code Sign Verify Command:${FULL_CMD[*]}"
    mlog DEBUG "Code Sign Verify Command:${FULL_CMD[*]}"
    if out="$("${FULL_CMD[@]}" 2>&1)"; then
      mlog SUCCESS "Successfully verified code signature for $APP"
      [[ -n "$out" ]] && mlog DEBUG "Code Sign Output\n$out"
      return 0
    else
      mlog ERROR "Failed to verify code signature for $APP"
      [[ -n "$out" ]] && mlog ERROR "Code Sign Output\n$out"
      return 1
    fi
  else
    mlog FATAL "Failed to sign $APP with ${CODE_SIGNATURE}'s signature"
    [[ -n "$out" ]] && mlog FATAL "Code Sign Output\n$out"
    return 1
  fi
}

function gccVerCheck() {
  declare -g C_CMD=''
  declare x='' gcc_ver=''
  for x in $(type -afp gcc); do
    if [ -n "$GCC_VENDOR" ]; then
      if ! $x --version 2>/dev/null | grep "$GCC_VENDOR" >/dev/null 2>&1; then
        continue
      fi
    fi

    gcc_ver=$($x -dumpversion 2>/dev/null | cut -d. -f1)
    if [ -n "$gcc_ver" ] && [[ $gcc_ver =~ ^-?[0-9]+$ ]] && [ "$gcc_ver" -ge $GCC_MIN_VER ]; then
      C_CMD="$x"
      break
    fi
  done
  if [ -z "$C_CMD" ]; then
    mlog FATAL "GNU gcc rev ${GCC_MIN_VER}+ is required" 1
  fi
  mlog DEBUG "C_CMD=$C_CMD"
}

function c++VerCheck() {
  declare -g CC_CMD=''
  declare x='' cpp_ver=''
  for x in $(type -afp c++ c++${CPP_MIN_VER} c++14 c++-14 c++15 c++15 2>/dev/null >&1); do
    if [ -n "$CPP_VENDOR" ]; then
      if ! $x --version 2>/dev/null | grep "$CPP_VENDOR" >/dev/null 2>&1; then
        continue
      fi
    fi

    cpp_ver=$($x -dumpversion 2>/dev/null | cut -d. -f1)
    if [ -n "$cpp_ver" ] && [[ $cpp_ver =~ ^-?[0-9]+$ ]] && [ "$cpp_ver" -ge $CPP_MIN_VER ]; then
      CC_CMD="$x"
      break
    fi
  done
  if [ -z "$CC_CMD" ]; then
    mlog FATAL "GNU gcc ver ${CPP_MIN_VER}+ is not installed" 1
  fi
  mlog DEBUG "CC_CMD=$CC_CMD"
}

function stripit() {
  local FILE=$1
  local STRIP_CMD='' out=''

  [[ -z "$FILE" ]] && mlog ERROR "stripit function requries a file" && return 1
  [[ ! -r "$FILE" ]] && mlog ERROR "stripit function requires a file to readable " && return 1

  bcheck DEBUG && mlog DEBUG "We don't strip when DEBUG mode is enabled" && return 0 # we don't strip on debug binaries

  if [ "$(uname)" == "Darwin" ]; then
    STRIP_CMD="strip -x -S -D -no_code_signature_warning ${FILE}"
  else
    STRIP_CMD="strip --strip-all --remove-section=.note* --remove-section=.gnu.build* ${FILE}"
  fi
  mlog VERBOSE "Strip command:$STRIP_CMD"
  if out="$($STRIP_CMD 2>&1)"; then
    mlog SUCCESS "Successfully stripped $FILE"
  else
    mlog ERROR "Failed to strip $FILE"
    [[ -n "$out" ]] && mlog ERROR "$out"
  fi
}

# Export the functions for children and when soucred
export -f bcheck
export -f mlog
export -f color
export -f cecho
export -f signit
export -f LOGTFMT
export -f gccVerCheck
export -f c++VerCheck
export -f stripit
###########################
# Main
###########################
# If this script is being sorced for the functions don't include the main section
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return

if bcheck DEBUG; then
  mlog DEBUG "MODE ENABLED"
  mlog DEBUG "BASEDIR=$BASEDIR"
  mlog DEBUG "APP_NAME=$APP_NAME"
fi

B_OPTS=("$(cd "$BASEDIR" && find . -type f -mindepth 2 -maxdepth 2 -name build.sh 2>/dev/null | xargs dirname | sed -e 's#./##g')")
if [ -z "$1" ]; then
  echo "Valid build targets are "
  echo "all"
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
