#!/bin/sh

# deps: sudo apt-get install tftp-hpa stress

# Setup:
# dd if=/dev/urandom of=test/tftpboot/medium bs=1048576 count=5
# dd if=/dev/urandom of=test/tftpboot/big bs=1048576 count=10
# cp README.md test/tftpboot
# sudo ./puavo-tftpd  -u nobody -r test/tftpboot/

# Run: time test/speed.sh

# Optional: Add io stress: stress --io 10 --hdd 10

for i in $(seq 20)
do
    (
        tftp localhost -c get medium
        tftp localhost -c get big
        tftp localhost -c get README.md
        tftp localhost -c get README.md
    ) &
done
wait

