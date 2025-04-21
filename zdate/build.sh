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

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

cd "$BASEDIR" || mlog ERROR "Unable to change to $BASEDIR" 1

declare -a FULL_CMD=()
FULL_CMD=("zig" "fetch" "--save" "git+https://github.com/FObersteiner/zdt")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully fetched zdt module with zig "
  mlog DEBUG "zig Command=${FULL_CMD[*]}"
  mlog VERBOSE "zig Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed fetch zdt with zig\nzig Cmmand=${FULL_CMD[*]}\n$out" 1
fi

FULL_CMD=("zig" "build" "install" "--prefix" "." "--prefix-exe-dir" "bin" "--release=small")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully built ${APP_NAME} (binary installed at bin/${APP_NAME})"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"

  stripit "bin/${APP_NAME}"
else
  mlog FATAL "Failed to build ${APP_NAME}\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

FULL_CMD=("diff" "-q" "$BASEDIR/bin/$APP_NAME" "$APP_BIN")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog VERBOSE "diff Command=${FULL_CMD[*]}"
  mlog "VERBOSE" "freshly built $APP_BIN is identical to final binary directory, no copy operation need"
  exit 0
else
  mlog VERBOSE "diff Command=${FULL_CMD[*]}"
  mlog "VERBOSE" "freshly built $APP_BIN is not identical to final binary, copy operation needed"
  [[ -n "$out" ]] && mlog DEBUG "$out"
fi

FULL_CMD=(cp -rp "$BASEDIR/bin/$APP_NAME" "$APP_BIN")
mlog DEBUG "Running ${FULL_CMD[*]}"
if ! out="$("${FULL_CMD[@]}" 2>&1)"; then
  mlog VERBOSE "Copy Command=${FULL_CMD[*]}"
  mlog FATAL "Failed to copy the built binary $APP_NAME to $APP_BIN"
  if [ -n "$OUT" ]; then
    mlog FATAL "$out"
  fi
  exit 1
fi
