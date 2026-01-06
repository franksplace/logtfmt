#!/usr/bin/env bash
#
# Copyright 2024-2026 Frank Stutz
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

goVerCheck

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

declare -a BOPTS=()
BOPTS=('-ldflags="-w -s"')
bcheck DEBUG && BOPTS=("-v")

if [ "$(uname)" == "Linux" ]; then
  BOPTS=('-ldflags="-w -s -extldflags=-static"')
fi

declare -a FULL_CMD=()
FULL_CMD=("$GO_CMD" build -C "$BASEDIR" "${BOPTS[*]}" -o "../bin/${APP_NAME}" godate.go)
declare FINAL_CMD="eval ${FULL_CMD[*]}"
if ! out="$(${FINAL_CMD} 2>&1)"; then
  mlog FATAL "Unable to build $APP_NAME\nComplication Command=${FULL_CMD[*]}\n$out" 1
fi

# shellcheck disable=SC2068
mlog DEBUG "Compilation Command=${FULL_CMD[*]}"
mlog VERBOSE "Compilation Command=${FULL_CMD[*]}"
[[ -n "$out" ]] && mlog DEBUG "$out"
mlog SUCCESS "Successfully built $APP_NAME (binary installed at bin/${APP_NAME})"

stripit "bin/${APP_NAME}"

exit 0
