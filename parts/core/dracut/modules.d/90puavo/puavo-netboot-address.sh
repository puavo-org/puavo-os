#!/bin/sh

# The initramfs DHCP address is installed with the lease
# lifetime and nothing renews the lease after switch root,
# so the kernel would drop the address when the lease
# expires. Make the address permanent.

[ -e /run/puavo/nbd-server ] || exit 0

ip -4 -o addr show scope global \
  | while read -r _ interface _ address _; do
      ip addr change "$address" dev "$interface" \
        valid_lft forever preferred_lft forever
    done
