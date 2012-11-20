#!/bin/sh

tapif=$1

. /usr/share/puavo-wlanap/common.sh

ifconfig $tapif up

echo 1 > /proc/sys/net/ipv4/ip_forward
brctl addbr br.$tapif
brctl setfd br.$tapif 0
ifconfig br.$tapif up

brctl addif br.$tapif $tapif

killall -9 hostapd
killall -9 hostapd_cli
sleep 2

puavo_wlanap_write_hostapd_conf $tapif

hostapd -B /etc/puavo-wlanap/hostapd.conf
sleep 2

while true
do
    hostapd_cli -B -a puavo-wlanap-send-event
    if [ $? -eq 0 ]
    then
	break
    fi
    sleep 1
done
