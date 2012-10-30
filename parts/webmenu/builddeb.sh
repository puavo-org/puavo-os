#!/bin/sh

# Run from parent directory!

FILES="webmenu/Makefile webmenu/lib/ webmenu/content/ webmenu/*.coffee webmenu/*.js webmenu/*.json webmenu/bin/ webmenu/routes/ webmenu/*.md webmenu/node_modules/ webmenu/debian/"

set -eu

# Remove previous build
rm -rf webmenu_build/ || true
rm -rf webmenu_1.0-1_i386.build || true
rm -rf webmenu_build.orig || true

mkdir webmenu_build

cp -r $FILES webmenu_build/

cp -a webmenu_build/ webmenu_build.orig
cd webmenu_build/

debuild -us -uc

