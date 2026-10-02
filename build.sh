#!/bin/bash
set -xe

[ -d build ] || git clone https://gitlab.com/ubports/community-ports/halium-generic-adaptation-build-tools -b halium-11 build
# default to persistent workdir (downloads + staging) unless caller passes args
if [ $# -eq 0 ]; then
    set -- -b workdir
fi
./build/build.sh "$@"
