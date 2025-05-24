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
CWD=$(pwd)
APP_BIN="${CWD}/bin/${APP_NAME}"

if ! declare -f mlog >/dev/null 2>&1; then
  source "$BASEDIR/../build.sh"
fi

! cargo --version >/dev/null 2>&1 && mlog ERROR "cargo is required" 1

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

cd "$BASEDIR" || mlog ERROR "Unable to change to $BASEDIR" 1

FULL_CMD=("cargo" "build" "--release")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully built ${APP_NAME}"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed to build ${APP_NAME}\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

FULL_CMD=("cp" "-p" "${BASEDIR}/target/release/${APP_NAME}" "$APP_BIN")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully copied ${APP_NAME} to $APP_BIN"
  mlog DEBUG "Copy Command=${FULL_CMD[*]}"
  mlog VERBOSE "Copy Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed copy ${APP_NAME} to binary dir\nCopy Command=${FULL_CMD[*]}\n$out" 1
fi
