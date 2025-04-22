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
FULL_CMD=("cp" "${BASEDIR}/build.zig.zon" "${BASEDIR}/build.zig.zon.orig")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog DEBUG "Made copy of build.zig.zon"
  mlog DEBUG "cp Command=${FULL_CMD[*]}"
  mlog VERBOSE "cp Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed copy build.zig.zon\ncp Cmmand=${FULL_CMD[*]}\n$out" 1
fi

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

FULL_CMD=("mv" "${BASEDIR}/build.zig.zon.orig" "${BASEDIR}/build.zig.zon")
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog DEBUG "Restoring build.zig.zon to original"
  mlog DEBUG "mv Command=${FULL_CMD[*]}"
  mlog VERBOSE "mv Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed move build.zig.zon.orig\nmv Cmmand=${FULL_CMD[*]}\n$out" 1
fi

if [ -d "${BASEDIR}/.zig-cache" ] && [ -z "$SAVE_BUILD_DATA" ]; then
  FULL_CMD=("rm" "-rf" "${BASEDIR}/.zig-cache")
  # shellcheck disable=SC2068
  if out=$(${FULL_CMD[@]} 2>&1); then
    mlog SUCCESS "Succesfully deleted .zig-cache directory"
    mlog DEBUG "rm Command=${FULL_CMD[*]}"
    mlog VERBOSE "rm Command=${FULL_CMD[*]}"
    [[ -n "$out" ]] && mlog DEBUG "$out"
  else
    mlog FATAL "Failed remove .zig-chache\nrm Command=${FULL_CMD[*]}\n$out" 1
  fi
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
