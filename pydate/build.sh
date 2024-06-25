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

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

if ! cython --version >/dev/null 2>&1; then
  if ! pip install cython >/dev/null 2>&1; then
    if ! pipx install cython >/dev/null 2>&1; then
      mlog FATAL 'Unable to install cython' 2
    fi
  fi
fi

if ! cython "${BASEDIR}/pydate.py" --embed -3 -f; then
  mlog FATAL "Failed to generate C source code (${BASEDIR}/pydate.c)" 3
fi

export C_INCLUDE_PATH=/usr/local/Frameworks/Python.framework/Versions/Current/Headers:/Library/Frameworks/Python.framework/Versions/Current/Headers
PYTHONLIBVER=python$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')$(python3-config --abiflags)
# shellcheck disable=SC2046,SC2086
if ! gcc -Os $(python3-config --includes) "${BASEDIR}/pydate.c" -o "bin/${APP_NAME}" $(python3-config --ldflags) -l$PYTHONLIBVER; then
  mlog FATAL "Failed to create binary pydate" 4
fi

if ! rm -f "${APP_NAME}/pydate.c"; then
  mlog WARN "Unable to clean up pydate C source file (${APP_NAME}/pydate.c)"
fi

mlog SUCCESS "Successfully built ${APP_NAME} (binary installed at bin/${APP_NAME})"
