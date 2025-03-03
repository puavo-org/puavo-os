#!/bin/sh
mkdir -p /run/puavo

for netconf in /run/net-*.conf; do
  test -e "$netconf" || continue
  . "$netconf"
  if [ -n "$ROOTSERVER" ]; then
    printf "%s\n" "$ROOTSERVER" > /run/puavo/nbd-server
    break
  fi
done
