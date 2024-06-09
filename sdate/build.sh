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
SAVE_LOGS="${BUILD_KEEP_LOGS:-false}"
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

BUILD_LOG=".build-logs/build_$(LOGTFMT).out"
if [ "$(uname)" == "Darwin" ]; then
  BUILD_CMD=(swift build --arch arm64 --arch x86_64 --sanitize undefined -c release)
else
  BUILD_CMD=(swift build --arch "$(arch)" --sanitize undefined -c release)
fi

APP_BUILT_BIN="${BASEDIR}/.build/apple/Products/Release/${PACKAGE_APP_NAME}"
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
  mlog DEBUG "SAVE_LOGS=$SAVE_LOGS"
  mlog DEBUG "SAVE_BUILD_DATA=$SAVE_BUILD_DATA"
  mlog DEBUG "BUILD_LOG=$BUILD_LOG"
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
if [ ! -d .build-logs ]; then
  mlog DEBUG "Creating .build-logs directory"
  if ! mkdir -p .build-logs; then
    mlog FATAL "Unable to create .build-logs directory" 1
  fi
fi

(
  echo -e "##########################################################################"
  echo -e "# Starting Build"
  echo -e " # CMD: ${BUILD_CMD[*]}"
  echo -e "##########################################################################"
) >>"$BUILD_LOG"

mlog DEBUG "Running ${BUILD_CMD[*]}"

if [ "$(
  cd "$BASEDIR" &&
    "${BUILD_CMD[@]}" >>"$BUILD_LOG" 2>&1
  echo $?
)" -ne 0 ]; then
  mlog FATAL "Failed to build unverisal binary $APP_NAME"
  mlog FATAL "See $BUILD_LOG for details" 1
fi

if [ ! -f "$APP_BUILT_BIN" ]; then
  mlog FATAL "Unable to find $APP_BUILT_BIN" 1
fi

if [ ! -d "bin" ]; then
  mlog INFO "Creating bin directory"
  #  out=$(mkdir bin 2>&1)
  if ! out=$(mkdir bin 2>&1); then
    mlog FATAL "Unable to bin directory\n$out" 1
  fi
fi

(
  echo -e "##########################################################################"
  echo -e "# Starting Copying Built Binary"
  echo -e "# CMD: ${COPY_CMD[*]}"
  echo -e "##########################################################################"
) >>"$BUILD_LOG"

mlog DEBUG "Running ${COPY_CMD[*]}"
if [ "$(
  "${COPY_CMD[@]}" >>"$BUILD_LOG" 2>&1
  echo $?
)" -ne 0 ]; then
  mlog SUCCESS "Successfully built universal binary $APP_NAME"
  mlog FATAL "Failed to copy the built binary $PACKAGE_APP_NAME to $APP_BIN"
  mlog FATAL "See $BUILD_LOG for details" 1
fi

if ! $SAVE_BUILD_DATA; then
  mlog DEBUG "Removing .build directory"
  rm -rf .build
fi
mlog SUCCESS "Successfully built universal binary $APP_NAME which is found at $APP_BIN"
if [ "$(uname)" != "Darwin" ]; then
  mlog "INFO" "Code sign automation only completed for Darwin (MacOS), manual operation is needed"
  mlog "INFO" "Manual Operation -> 'cargo install apple-codesign --locked' ; rcodesign and Transporter"
  mlog "INFO" "Good Explanation -> https://gregoryszorc.com/docs/apple-codesign/0.12.0/apple_codesign_getting_started.html#installing"
  exit
fi

if signit "$APP_BIN" >>"$BUILD_LOG" 2>&1; then
  mlog SUCCESS "Successfully signed $APP_NAME with ${CODE_SIGNATURE}'s signature"
  if ! $SAVE_LOGS; then
    mlog DEBUG "Removing .build-logs directory"
    rm -rf .build-logs
  fi
else
  mlog FATAL "Failed to sign $APP_NAME with ${CODE_SIGNATURE}'s signature"
  mlog FATAL "See $BUILD_LOG for details" 1
fi
