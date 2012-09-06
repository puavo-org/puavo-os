#!/bin/bash -e

# Example log client

cat << EOF | nc -u localhost 1234
hostname:$(hostname)
date:$(date +%s)
EOF
