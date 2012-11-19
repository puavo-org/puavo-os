#!/bin/sh

tapif=$1

killall -9 hostapd
ifconfig br.$tapif down
brctl delbr br.$tapif
