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
c++VerCheck

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

declare -a BOPTS=()
BOPTS=("-Ofast -s -DNDEBUG")
bcheck DEBUG && BOPTS+=("-v")

if [ "$(uname)" == "Linux" ]; then
  BOPTS+=("-static -static-libgcc -static-libstdc++")
fi

declare -a FULL_CMD=()

FULL_CMD=("$CC_CMD" "${BOPTS[@]}" -std=c++20 -o "bin/${APP_NAME}" -Wall -pedantic "${BASEDIR}/$APP_NAME".cc)
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully built $APP_NAME (binary installed at bin/$APP_NAME)"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"

  stripit "bin/${APP_NAME}"
else
  mlog ERROR "Failed to build $APP_NAME\nCompilation Command=${FULL_CMD[*]}\n$out"
fi

if [ -n "$ONLY_STATIC" ] || [ "$(uname)" == "Darwin" ]; then
  exit
fi

BOPTS=("-Ofast -s -DNDEBUG")
bcheck DEBUG && BOPTS+=("-v")

FULL_CMD=("$CC_CMD" "${BOPTS[@]}" -std=c++20 -o "bin/${APP_NAME}-dynlink" -Wall -pedantic "${BASEDIR}/$APP_NAME".cc)
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully built ${APP_NAME}-dynlink (binary installed at bin/${APP_NAME}-dynlink)"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"

  stripit "bin/${APP_NAME}-dynlink"
else
  mlog ERROR "Failed to build ${APP_NAME}-dynlink\nCompilation Command=${FULL_CMD[*]}\n$out"
fi
