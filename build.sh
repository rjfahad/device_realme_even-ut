#!/bin/bash
set -xe

cd "$(dirname "$0")"

[ -d build ] || git clone https://gitlab.com/ubports/community-ports/halium-generic-adaptation-build-tools -b halium-11 build

# AOSP gcc ships binutils 2.27 `as` which rejects -mcpu=cortex-a55 (added by the
# kernel Makefile when CC=clang) -> scripts/mod dies with "Makefile:671: scripts Error 2".
# build/build.sh skips an existing toolchain dir, so pre-clone it here with the
# system binutils `as` swapped in; re-clones are re-swapped automatically.
GCC=workdir/downloads/aarch64-linux-android-4.9
if [ ! -d "$GCC" ] || { [ -f "$GCC/bin/aarch64-linux-android-as" ] && [ ! -L "$GCC/bin/aarch64-linux-android-as" ]; }; then
    SYS_AS="$(command -v aarch64-linux-gnu-as)" || { echo "ERROR: aarch64-linux-gnu-as not found (install binutils-aarch64-linux-gnu)" >&2; exit 1; }
    mkdir -p workdir
    [ -d "$GCC" ] || git -C workdir clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b pie-gsi --depth 1
    mv "$GCC/bin/aarch64-linux-android-as" "$GCC/bin/aarch64-linux-android-as.2.27.bak"
    ln -s "$SYS_AS" "$GCC/bin/aarch64-linux-android-as"
fi

# default to persistent workdir (downloads + staging) unless caller passes args
if [ $# -eq 0 ]; then
    set -- -b workdir
fi
./build/build.sh "$@"
