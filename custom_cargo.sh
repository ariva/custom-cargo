#!/bin/bash

DEFAULT_BUILD_VERSION="1.58.1"
BUILD_WITH_CARGO="1.58.1"

[ -z $BUILD_VERSION ] && BUILD_VERSION=${1:-$DEFAULT_BUILD_VERSION}
echo "CUSTOM VERSION: $BUILD_VERSION"

TOOLCHAIN_PATH=~/.rustup/toolchains/$BUILD_VERSION-x86_64-unknown-linux-gnu

abort()
{
  [ -e $TOOLCHAIN_PATH/bin/cargo_bak ] && cp $TOOLCHAIN_PATH/bin/cargo_bak $TOOLCHAIN_PATH/bin/cargo && rm $TOOLCHAIN_PATH/bin/cargo_bak
  echo "error occurred, exiting..."
  exit 1
}

trap 'abort' 0

set -e

# current cargo build requires this version:
rustup install $BUILD_VERSION
rustup default $BUILD_WITH_CARGO

cargo build --release

# Switch to currect version which will be patched
rustup default $BUILD_VERSION

# Install WASM
rustup target add wasm32-unknown-unknown

[ ! -f $TOOLCHAIN_PATH/bin/cargo_bak ] && cp $TOOLCHAIN_PATH/bin/cargo $TOOLCHAIN_PATH/bin/cargo_bak

if [ ! -z `pidof cargo` ]; then
    echo "Cargo is in use! Killing it..."
    pkill cargo
fi

[ -f ./target/release/cargo ] && echo "copying ./target/release/cargo" && cp ./target/release/cargo $TOOLCHAIN_PATH/bin/cargo

CUSTOM_BUILD_NAME="custom-$BUILD_VERSION"

# rm ~/.rustup/toolchains/$CUSTOM_BUILD_NAME
if [ ! -e ~/.rustup/toolchains/$CUSTOM_BUILD_NAME ]; then
  echo "--- setup custom build: $CUSTOM_BUILD_NAME"
  rustup toolchain link $CUSTOM_BUILD_NAME ~/.rustup/toolchains/$BUILD_VERSION-x86_64-unknown-linux-gnu
fi

rustup default $CUSTOM_BUILD_NAME

echo "done"

trap : 0

exit 0

