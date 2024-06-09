#!/usr/bin/env bash
#shellcheck disable=SC2317

# Required Checks to use Script

if ! swift --version >/dev/null 2>&1; then
  if [ "$(uname)" == "Darwin" ]; then
    echo "Xcode Developer Tools are Required" && exit 1
  else
    echo "Swift Toolchain is required" && exit 1
  fi
fi
! jq --version >/dev/null 2>&1 && echo "jq is required" && exit 1

###########################
# Configurable Variables
###########################
if [ "$(uname)" == "Darwin" ]; then
  CODE_SIGNATURE="${BUILD_CODE_SIGNATURE:-$(id -F)}"
else
  CODE_SIGNATURE="${BUILD_CODE_SIGNATURE:-$(id -un)}"
fi
SAVE_BUILD_DATA="${BUILD_KEEP_COMPILATION:-false}"

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
PACKAGE_APP_NAME="$(cd "$BASEDIR" && swift package dump-package | jq -cr '.targets[].name')"

if [ "$(uname)" == "Darwin" ]; then
  BUILD_CMD=(swift build --package-path "$BASEDIR" --arch arm64 --arch x86_64 --sanitize thread -c release)
  APP_BUILT_BIN="${BASEDIR}/.build/apple/Products/Release/${PACKAGE_APP_NAME}"
else
  APP_BUILT_BIN="${BASEDIR}/.build/$(arch)-*/release/${PACKAGE_APP_NAME}"
  BUILD_CMD=(swift build "$BASEDIR" --arch "$(arch)" --static-swift-stdlib --sanitize thread -c release)
fi

APP_BIN="bin/${APP_NAME}"
#shellcheck disable=SC2089
COPY_CMD=(cp -rp "$APP_BUILT_BIN" "$APP_BIN")

###########################
# Main
###########################
if ! declare -f mlog >/dev/null 2>&1; then
  source "$BASEDIR/../build.sh"
fi

if $DEBUG; then
  mlog DEBUG "MODE ENABLED"
  mlog DEBUG "BASEDIR=$BASEDIR"
  mlog DEBUG "APP_NAME=$APP_NAME"
  mlog DEBUG "PACKAGE_APP_NAME=$PACKAGE_APP_NAME"
  mlog DEBUG "CODE_SIGNATURE=$CODE_SIGNATURE"
  mlog DEBUG "SAVE_BUILD_DATA=$SAVE_BUILD_DATA"
  mlog DEBUG "BUILD_CMD=${BUILD_CMD[*]}"
  mlog DEBUG "APP_BUILT_BIN=$APP_BUILT_BIN"
  mlog DEBUG "APP_BIN=$APP_BIN"
  mlog DEBUG "COPY_CMD=${COPY_CMD[*]}"
fi

if [ -d .build ] && ! $SAVE_BUILD_DATA; then
  mlog DEBUG "Removing previous build data .build directory"
  if ! rm -rf .build; then
    mlog FATAL "Unable to remove previous .build directory" 1
  fi
  mlog DEBUG "Creating .build directory"
  if ! mkdir -p .build; then
    mlog FATAL "Unable to create .build directory" 1
  fi
fi

mlog DEBUG "Running ${BUILD_CMD[*]}"

if ! out="$("${BUILD_CMD[@]}" 2>&1)"; then
  mlog FATAL "Failed to build unverisal binary $APP_NAME"
  mlog FATAL "Compilation Command: ${BUILD_CMD[*]}"
  if [ -n "$OUT" ]; then
    mlog FATAL "$out"
  fi
  exit 1
fi
if $DEBUG && [ -n "$out" ]; then
  mlog DEBUG "Compilation Command: ${BUILD_CMD[*]}"
  mlog DEBUG "Compilation Output:\n$out"
fi

if [ ! -f "$APP_BUILT_BIN" ]; then
  mlog FATAL "Unable to find $APP_BUILT_BIN" 1
fi

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory"
    if [ -n "$out" ]; then
      mlog FATAL "$out"
    fi
  fi
  exit
fi

mlog DEBUG "Running ${COPY_CMD[*]}"
if ! out="$(${COPY_CMD[@]} 2>&1)"; then
  mlog SUCCESS "Successfully built universal binary $APP_NAME"
  mlog FATAL "Failed to copy the built binary $PACKAGE_APP_NAME to $APP_BIN"
  if [ -n "$OUT" ]; then
    mlog FATAL "$out"
  fi
  eixt 1
fi

if ! $SAVE_BUILD_DATA; then
  mlog DEBUG "Removing "$BASEDIR/.build" directory"
  rm -rf "$BASEDIR/.build"
fi

mlog SUCCESS "Successfully built universal binary $APP_NAME which is found at $APP_BIN"

if [ "$(uname)" != "Darwin" ]; then
  mlog "INFO" "Code sign automation only completed for Darwin (MacOS), manual operation is needed"
  mlog "INFO" "Manual Operation -> 'cargo install apple-codesign --locked' ; rcodesign and Transporter"
  mlog "INFO" "Good Explanation -> https://gregoryszorc.com/docs/apple-codesign/0.12.0/apple_codesign_getting_started.html#installing"
  exit
fi

if ! out="$(signit "$APP_BIN" 2>&1)"; then
  mlog FATAL "Failed to sign $APP_NAME with ${CODE_SIGNATURE}'s signature"
  if [ -n "$out" ]; then
    mlog FATAL "$out"
  fi
  exit 1
else
  if $DEBUG && [ -n "$out" ]; then
    mlog DEBUG "Codesign Output\n$out"
  fi
  mlog SUCCESS "Successfully signed $APP_NAME with ${CODE_SIGNATURE}'s signature"
fi
