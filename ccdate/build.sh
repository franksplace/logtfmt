#!/usr/bin/env bash

###########################
# General Variables
###########################
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

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

BOPTS="-Ofast -s -DNDEBUG"
$DEBUG && BOPTS="-v"

c++VerCheck
if [ -z "$CC_CMD" ]; then # check extra santity to make sure c++VerCheck set it
  mlog FATAL "GCC 14+ version not installed" 1
fi

if [ "$(uname)" == "Linux" ]; then
  BOPTS+=" -static -static-libgcc -static-libstdc++ "
fi

FULL_CMD="$CC_CMD -std=c++20 -o "bin/${APP_NAME}" $BOPTS -Wall -pedantic "${BASEDIR}/$APP_NAME".cc"
if out="$($FULL_CMD 2>&1)"; then
  mlog SUCCESS "Successfully build $APP_NAME (binary installed at bin/$APP_NAME)"
  if [ -n "$out" ] && $DEBUG; then
    mlog DEBUG "Compilation Command=$FULL_CMD"
    mlog DEBUG "$out"
  fi
else
  mlog ERROR "Failed to build $APP_NAME\nCompilation Command=$FULL_CMD\n$out"
fi

if [ -n "$ONLY_STATIC" ] || [ "$(uname)" == "Darwin" ]; then
  exit
fi

BOPTS="-Ofast -s -DNDEBUG"
$DEBUG && BOPTS="-v"

FULL_CMD="$CC_CMD -std=c++20 -o "bin/${APP_NAME}-dynlink" $BOPTS -Wall -pedantic "${BASEDIR}/$APP_NAME".cc"
if out="$($FULL_CMD 2>&1)"; then
  mlog SUCCESS "Successfully build ${APP_NAME}-dynlink (binary installed at bin/${APP_NAME}-dynlink)"
  if [ -n "$out" ] && $DEBUG; then
    mlog DEBUG "Compilation Command=$FULL_CMD"
    mlog DEBUG "$out"
  fi
else
  mlog ERROR "Failed to build ${APP_NAME}-dynlink\nCompilation Command=$FULL_CMD\n$out"
fi
