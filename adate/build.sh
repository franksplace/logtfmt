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

declare -a FULL_CMD=()

function objectCleanup() {
  if [ -f "${BASEDIR}/${APP_NAME}.o" ] && [ -z "$SAVE_BUILD_DATA" ]; then
    FULL_CMD=("rm" "-f" "${BASEDIR}/${APP_NAME}.o")
    # shellcheck disable=SC2068
    if out=$(${FULL_CMD[@]} 2>&1); then
      mlog SUCCESS "Succesfully deleted ${APP_NAME}.o object file"
      mlog DEBUG "rm Command=${FULL_CMD[*]}"
      mlog VERBOSE "rm Command=${FULL_CMD[*]}"
      [[ -n "$out" ]] && mlog DEBUG "$out"
    else
      mlog FATAL "Failed remove ${APP_NAME}.o\nrm Command=${FULL_CMD[*]}\n$out" 1
    fi
  fi
}

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

declare -a BOPTS=()
BOPTS=("-Ofast -DNDEBUG")
bcheck DEBUG && BOPTS=("-v")

if [ "$(uname -s)" == "Darwin" ]; then
  BOPTS+=("-no-pie")
  ARCH_FLAG="machO64"
elif [ "$(uname -s)" == "Linux" ]; then
  BOPTS+=("-static -static-libgcc -static-libstdc++ -no-pie")
  ARCH_FLAG="elf64"
else
  mlog FATAL "Currently compilation supported on Darwin (MacOS) and Linux" 1
fi

FULL_CMD=("nasm" "-f" "$ARCH_FLAG" "$BASEDIR/$APP_NAME.asm")
# shellcheck disable=SC2068
if out="$(${FULL_CMD[@]} 2>&1)"; then
  mlog SUCCESS "Successfully compiled $APP_NAME object"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"
else
  mlog FATAL "Failed to compile $APP_NAME\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

FULL_CMD=("$C_CMD" "${BOPTS[@]}" -o "bin/${APP_NAME}" -Wall "${BASEDIR}/$APP_NAME".o)
# shellcheck disable=SC2068
if out="$(${FULL_CMD[@]} 2>&1)"; then
  mlog SUCCESS "Successfully built $APP_NAME (binary installed at bin/$APP_NAME)"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"

  stripit "bin/${APP_NAME}"
else
  mlog FATAL "Failed to build $APP_NAME\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

if [ -n "$ONLY_STATIC" ] || [ "$(uname)" == "Darwin" ]; then
  objectCleanup
  exit
fi

BOPTS=("-Ofast -s -DNDEBUG -no-pie")
bcheck DEBUG && BOPTS=("-v -no-pie")

FULL_CMD=("$C_CMD" "${BOPTS[@]}" -o "bin/${APP_NAME}-dynlink" -Wall "${BASEDIR}/$APP_NAME".o)
# shellcheck disable=SC2068
if out=$(${FULL_CMD[@]} 2>&1); then
  mlog SUCCESS "Successfully built ${APP_NAME}-dynlib (binary installed at bin/${APP_NAME}-dynlink)"
  mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
  mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
  [[ -n "$out" ]] && mlog DEBUG "$out"

  stripit "bin/${APP_NAME}-dynlink"
else
  mlog FATAL "Failed to build ${APP_NAME}-dynlink\nCompilation Command=${FULL_CMD[*]}\n$out" 1
fi

objectCleanup
