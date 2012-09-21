#!/bin/sh

while true
do

nc -v -w 1 -u eventlog 3858 << EOF
type:wlan
hostname:$(hostname)
date:$(date +%s)
wlaninterface:wlan0
event:AP-STA-CONNECTED
mac:testmac
EOF

sleep 3

nc -v -w 1 -u eventlog 3858 << EOF
type:wlan
hostname:$(hostname)
date:$(date +%s)
wlaninterface:wlan0
event:AP-STA-DISCONNECTED
mac:testmac
EOF

sleep 3

done
