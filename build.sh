#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120

###########################
# General Variables
###########################
[[ -n "$BUILD_DEBUG" ]] && set -x
trap "set +x" HUP INT QUIT TERM EXIT

declare -g -x C_MIN_VER=8
declare -g -x C_VENDOR='' # if we want to at some future date require GNU set it like the C_VENDOR
declare -g -x C_APP_SEARCH='cc clang clang-18 gcc gcc-14 gcc-15'
declare -g -x CPP_MIN_VER=14
declare -g -x CPP_VENDOR='Free Software Foundation' # i.e. GNU C++
declare -g -x CPP_APP_SEARCH="c++ c++${CPP_MIN_VER} c++14 c++-14 c++15 c++-15"
declare -g -x SWIFT_MIN_VER=5.10

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
declare -g -f LOGTFMT bcheck color mlog cecho signit cVerCheck
declare -g -f c++VerCheck swiftVerCheck stripit compareSemanticVersions

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
    elif bcheck BUILD_DEBUG && [ "$TYPE" == "BUILD_DEBUG" ]; then
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
  BUILD_DEBUG) TYPE_OUT=$(cecho brightgreen "$TYPE") ;;
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

  declare -x out=''
  declare -a FULL_CMD=()
  FULL_CMD=(codesign -f --sign "$CODE_SIGNATURE" --options=runtime --timestamp "$APP")

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

function compareSemanticVersions() {
  # return 0 is equal
  # return 1 is >
  # return 2 is <
  if [ $# -lt 2 ]; then
    mlog FATAL "can't compare Semantic Versions if variables are not passed"
    mlog FATAL "Usage: compareSemanticVersions var1 var2 " 10
  fi

  mlog BUILD_DEBUG "Semantic Compare $1 to $2"

  if [[ "$1" == "$2" ]]; then
    return 0
  fi

  local IFS=.
  # Everything after the first character not in [^0-9.] is compared
  # shellcheck disable=SC2206
  local i a=(${1%%[^0-9.]*}) b=(${2%%[^0-9.]*})
  # shellcheck disable=SC2295
  local arem=${1#${1%%[^0-9.]*}} brem=${2#${2%%[^0-9.]*}}
  for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
    if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
      return 2
    elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
      return 1
    fi
  done
  if [ "$arem" '<' "$brem" ]; then
    return 2
  elif [ "$arem" '>' "$brem" ]; then
    return 1
  fi
  return 0
}

function swiftVerCheck() {
  declare -g SWIFT_CMD=''
  declare x='' y='' swift_ver=''
  for x in $(type -afp swift 2>/dev/null); do
    swift_ver="$(for y in $($x --version 2>/dev/null); do [[ "$y" =~ ^\(swift ]] && cut -d- -f2 <<<"$y" && break; done 2>&1)"
    if [ -n "$swift_ver" ] && [[ $swift_ver =~ ^-?[0-9.\-]+$ ]]; then
      compareSemanticVersions "$swift_ver" "$SWIFT_MIN_VER"
      if [ $? -le 1 ]; then
        SWIFT_CMD="$x"
        break
      fi
    fi
  done
  if [ -z "$SWIFT_CMD" ]; then
    mlog FATAL "Swift version ${SWIFT_MIN_VER}+ is not installed (or not found in PATH)" 1
  fi
  mlog DEBUG "Swift command:$SWIFT_CMD"
  mlog VERBOSE "Swift command:$SWIFT_CMD"
  mlog VERBOSE "Swift version:$swift_ver"
}

function cVerCheck() {
  declare -g C_CMD=''
  declare x='' c_ver='' c_dist=''

  # shellcheck disable=SC2086
  for x in $(type -afp ${C_APP_SEARCH} 2>/dev/null); do
    if ! c_dist=$($x --version 2>/dev/null) && [ -n "$C_VENDOR" ]; then
      continue
    fi

    if [ -n "$C_VENDOR" ]; then
      if [[ ! "$c_dist" =~ $C_VENDOR ]]; then
        continue
      fi
    fi

    c_ver=$($x -dumpversion 2>/dev/null | cut -d. -f1)
    if [ -n "$c_ver" ] && [[ $c_ver =~ ^-?[0-9.\-]+$ ]]; then
      compareSemanticVersions "$c_ver" "$C_MIN_VER"
      if [ $? -le 1 ]; then
        C_CMD="$x"
        break
      fi
    fi
  done
  if [ -z "$C_CMD" ]; then
    mlog FATAL "$C_VENDOR c rev ${C_MIN_VER}+ is not installed (or not found in PATH)" 1
  fi
  mlog DEBUG "C command:$C_CMD"
  mlog DEBUG "C version:$c_ver"
  mlog DEBUG "C vendor: $c_dist"
  mlog VERBOSE "C command:$C_CMD"
  mlog VERBOSE "C version:$c_ver"
  mlog VERBOSE "C vendor: $c_dist"
}

function c++VerCheck() {
  declare -g CC_CMD=''
  declare x='' cpp_ver='' cpp_dist=''

  # shellcheck disable=SC2086
  for x in $(type -afp ${CPP_APP_SEARCH} 2>/dev/null); do
    if ! cpp_dist=$($x --version 2>/dev/null) && [ -n "$CPP_VENDOR" ]; then
      continue
    fi

    if [ -n "$CPP_VENDOR" ]; then
      if [[ ! "$cpp_dist" =~ $CPP_VENDOR ]]; then
        continue
      fi
    fi

    cpp_ver=$($x -dumpversion 2>/dev/null | cut -d. -f1)
    if [ -n "$cpp_ver" ] && [[ $cpp_ver =~ ^-?[0-9]+$ ]]; then
      compareSemanticVersions "$cpp_ver" "$CPP_MIN_VER"
      if [ $? -le 1 ]; then
        CC_CMD="$x"
        break
      fi
    fi
  done
  if [ -z "$CC_CMD" ]; then
    mlog FATAL "$CPP_VENDOR C++ ver ${CPP_MIN_VER}+ is not installed (or not found in PATH)" 1
  fi
  mlog DEBUG "C++ command:$CC_CMD"
  mlog DEBUG "C++ version:$cpp_ver"
  mlog DEBUG "C++ vendor:$cpp_dist"

  mlog VERBOSE "C++ command:$CC_CMD"
  mlog VERBOSE "C++ version:$cpp_ver"
  mlog VERBOSE "C++ vendor:$cpp_dist"
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
    # If .note.ABI-TAG is set and sometimes need, thus don't remove that note section
    STRIP_CMD="strip --strip-all --remove-section=.gnu.build* --remove-section=.note.[a-z]* --remove-section=.note.[B-Z]* ${FILE}"
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
export -f cVerCheck
export -f c++VerCheck
export -f swiftVerCheck
export -f stripit
export -f compareSemanticVersions
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

# shellcheck disable=SC2038
B_OPTS=("$(cd "$BASEDIR" && find . -mindepth 2 -maxdepth 2 -name build.sh -exec dirname {} \; 2>/dev/null | xargs -I{} basename '{}')")
if [ -z "$1" ]; then
  echo "Valid build targets are "
  echo "all"
  for b in "${B_OPTS[@]}"; do
    echo "$b"
  done
  exit
fi

if [ "${1^^}" == "ALL" ]; then
  # shellcheck disable=SC2068
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
