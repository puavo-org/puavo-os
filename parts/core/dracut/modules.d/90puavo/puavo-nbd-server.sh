#!/bin/sh

mkdir -p /run/puavo

netroot=''
for x in $(getargs netroot=); do
  case "$x" in
    nbd:*)
      netroot="$x"
      break
      ;;
  esac
done

[ -n "$netroot" ] || exit 0

nroot=${netroot#nbd:}
server=${nroot%%:*}

printf "%s\n" "$server" > /run/puavo/nbd-server
