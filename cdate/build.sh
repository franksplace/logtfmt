#!/usr/bin/env bash
#
# Copyright 2024-2025 Frank Stutz
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

if ! declare -f mlog >/dev/null 2>&1; then
  source "$BASEDIR/../build.sh"
fi
cVerCheck

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

if [ "$(uname)" == "Linux" ]; then
  BOPTS+=("-static -static-libgcc -static-libstdc++")
fi

declare -a FULL_CMD=()

FULL_CMD=("$C_CMD" "${BOPTS[@]}" -o "bin/${APP_NAME}" -Wall "${BASEDIR}/$APP_NAME".c)

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
  exit 0
fi

BOPTS=("-Ofast -s -DNDEBUG")
bcheck DEBUG && BOPTS=("-v")

FULL_CMD=("$C_CMD" "${BOPTS[@]}" -o "bin/${APP_NAME}-dynlink" -Wall "${BASEDIR}/$APP_NAME".c)
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

exit 0
