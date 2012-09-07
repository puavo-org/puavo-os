#!/bin/bash -e

# Example log client

cat << EOF | nc -u _eventlog 3858
hostname:$(hostname)
date:$(date +%s)
EOF
