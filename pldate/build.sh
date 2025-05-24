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

if ! type -a pp >/dev/null 2>&1; then
  mlog FATAL "PAR::Packer (pp) not installed" 1
fi

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

if ! pp -o "bin/${APP_NAME}" "${BASEDIR}/pdate".pl; then
  mlog FATAL "Unable to build $APP_NAME" 1
fi

mlog SUCCESS "Successfully built $APP_NAME (binary installed at bin/${APP_NAME})"
exit 0
