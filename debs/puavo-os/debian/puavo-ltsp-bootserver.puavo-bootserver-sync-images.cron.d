SHELL=/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

00 20 * * * root sleep $(( RANDOM \% 7200 )) && /sbin/start --quiet puavo-bootserver-sync-images >/dev/null 2>&1
00 07 * * * root /sbin/stop --quiet puavo-bootserver-sync-images >/dev/null 2>&1
