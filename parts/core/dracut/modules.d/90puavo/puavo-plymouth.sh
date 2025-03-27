#!/bin/sh

grep -E -q '(^| )init=/sbin/init-puavo($| )' /proc/cmdline || exit 0

# Copy our plymouth theme configuration to /root,
# because it is also used at shutdown.
cp -p /etc/plymouth/plymouthd.conf "${NEWROOT}/etc/plymouth/plymouthd.conf"
