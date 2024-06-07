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

BOPTS=''
$DEBUG && BOPTS="-v"

if ! c++-14 --version >/dev/null 2>&1; then
  mlog FATAL "gnu gcc is not installed" 1
fi

if out=$(c++-14 -std=c++20 -o "bin/${APP_NAME}" $BOPTS -Wall -pedantic "${BASEDIR}"/"$APP_NAME".cc 2>&1); then
  mlog SUCCESS "Successfully build $APP_NAME (binary installed at bin/$APP_NAME)"
  if [ -n "$out" ] && $DEBUG; then
    mlog DEBUG "$out"
  fi
else
  mlog ERROR "Failed to build $APP_NAME\n$out"
fi