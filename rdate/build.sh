#!/usr/bin/env bash
#
# Copyright 2025 Frank Stutz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

exit 0
