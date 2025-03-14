#!/bin/sh

# Todo: Duplicated
for x in $(cat /proc/cmdline); do
    if [ "$x" = "init=/sbin/init-puavo" ]; then
        BOOT=puavo
        break
    fi
done

test "$BOOT" = "puavo" || exit 0

# Todo: Duplicated
rootmnt="/sysroot"

# Copy our plymouth theme configuration to /root,
# because it is also used at shutdown.
cp -p /etc/plymouth/plymouthd.conf "${rootmnt}/etc/plymouth/plymouthd.conf"
