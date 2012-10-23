#!/bin/sh

set -eu

rootdir=$1

echo "Configuring ttyS0.conf"

cat << EOF > $rootdir/etc/init/ttyS0.conf
# ttyS0 - getty
#
# This service maintains a getty on ttyS0 from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty -L 115200 ttyS0 xterm
EOF

cp $rootdir/usr/share/zoneinfo/Europe/Helsinki $rootdir/etc/localtime
