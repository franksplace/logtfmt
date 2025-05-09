#!/usr/bin/env bash

###########################
# General Variables
###########################
[[ -n "$BUILD_DEBUG" ]] && set -x
trap "set +x" HUP INT QUIT TERM EXIT

# shellcheck disable=SC2164
ABSPATH="$(
  cd "${0%/*}" 2>/dev/null
  echo "$PWD"/"${0##*/}"
)"
BASEDIR="$(dirname "$ABSPATH")"
APP_NAME="$(basename "$BASEDIR")"

if ! declare -f mlog >/dev/null 2>&1; then
  source "$BASEDIR/../build.sh"
fi
cVerCheck
if ! type -afp nasm >/dev/null 2>&1; then
  mlog FATAL "Assembly compiled nasm not installed or not in PATH.\nFailed to compile $APP_NAME" 1
fi

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

if bcheck DEBUG; then
  export _DEBUG=1
else
  export _DEBUG=0
fi

if bcheck VERBOSE; then
  export _VERBOSE=1
else
  export _VERBOSE=0
fi

declare -a FULL_CMD=()
declare UNAME_S UNAME_M

UNAME_S=$(uname -s)
UNAME_M=$(uname -m)
if [ "$UNAME_S" == "Darwin" ] && [ "$UNAME_M" == "arm64" ]; then
  COMPILE_SUCCESS_INFO="${APP_NAME}_arm64, ${APP_NAME}_x86, and ${APP_NAME}_universal binaries"
  MOVE_SUCCESS_INFO="${APP_NAME} unverisal binary"
  FULL_CMD=("make" "-C" "${BASEDIR}" "macos-arm64" "macos-x86_64" "universal")
  MOVE_CMD=("mv" "${BASEDIR}/${APP_NAME}_universal" "bin/${APP_NAME}")
elif [ "$UNAME_S" == "Darwin" ]; then
  COMPILE_SUCCESS_INFO="${APP_NAME}_x86 binary"
  MOVE_SUCCESS_INFO="${APP_NAME} x86 binary"
  FULL_CMD=("make" "-C" "${BASEDIR}")
  MOVE_CMD=("mv" "${BASEDIR}/${APP_NAME}_x86_64" "bin/${APP_NAME}")
elif [ "${UNAME_S}" == "Linux" ]; then
  COMPILE_SUCCESS_INFO="${APP_NAME}_linux binary"
  MOVE_SUCCESS_INFO="${APP_NAME} linux binary"
  FULL_CMD=("make" "-C" "${BASEDIR}")
  MOVE_CMD=("mv" "${BASEDIR}/${APP_NAME}_linux" "bin/${APP_NAME}")
else
  mlog FATAL "Currently compilation supported on Darwin (MacOS) and Linux" 1
fi

# shellcheck disable=SC2068
if out="$(${FULL_CMD[@]} 2>&1)"; then
  mlog SUCCESS "Successfully compiled $COMPILE_SUCCESS_INFO"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed to compile $APP_NAME\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

# shellcheck disable=SC2068
if out="$(${MOVE_CMD[@]} 2>&1)"; then
  mlog SUCCESS "Successfully built ${MOVE_SUCCESS_INFO}, and final version is bin/${APP_NAME}"
  mlog DEBUG "Move Command=${MOVE_CMD[*]}"
  mlog VERBOSE "Move Command=${MOVE_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"

  stripit "bin/${APP_NAME}"
else
  mlog FATAL "Failed to build $APP_NAME\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

if [ -z "$SAVE_BUILD_DATA" ]; then
  FULL_CMD=("make" "-C" "${BASEDIR}" "clean")
  # shellcheck disable=SC2068
  if out=$(${FULL_CMD[@]} 2>&1); then
    mlog SUCCESS "Succesfully cleaned up object & intermediate binaries files"
    mlog DEBUG "Cleanup Command=${FULL_CMD[*]}"
    mlog VERBOSE "Cleanup Command=${FULL_CMD[*]}"
    [[ -n "$out" ]] && mlog DEBUG "$out"
  else
    mlog FATAL "Failed Cleanup\nClean Command=${FULL_CMD[*]}\n$out" 1
  fi
fi

exit 0
