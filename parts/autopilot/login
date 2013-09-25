#!/bin/sh

set -eu

if [ $# -ne 2 ]; then
    echo "E: wrong number of arguments" >&2
    echo "Usage: $0 USERNAME PASSWORD" >&2
    exit 1
fi

username=$1
password=$2

switch-to-login-vt

## The "Guest Session" widget might be the active one, click up arrow to
## activate the normal login widget.
xte 'key Up'
sleep 1

## The login widget might be dirty, click esc to clear it.
xte 'key Escape'
sleep 1

xte "str ${username}"
xte 'key Return'
sleep 2 ## Password widget activates slowly.

xte "str ${password}"
xte 'key Return'
