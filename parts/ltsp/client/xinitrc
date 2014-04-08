#!/bin/sh

. /usr/share/ltsp/ltsp_config

PUAVO_HOSTTYPE=$(cat /etc/puavo/hosttype)

case  "$PUAVO_HOSTTYPE" in
  fatclient|thinclient)
    xbacklight -set 100 
    ;;
  laptop)
    xbacklight -set 50
    ;;
esac

exec /usr/share/ltsp/xinitrc
