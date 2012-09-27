#!/bin/sh

# Run from parent directory!

FILES="logrelay/Makefile logrelay/README.md logrelay/server.rb logrelay/config.rb-dist logrelay/debian/"

set -eu

# Remove previous build
rm -rf logrelay_build/ || true

mkdir logrelay_build

cp -r $FILES logrelay_build/

cd logrelay_build/

debuild -us -uc

