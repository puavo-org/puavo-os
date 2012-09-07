#!/bin/bash -e

# Example log client

nc -q 1 -u 127.0.0.1 3858 << EOF
hostname:$(hostname)
date:$(date +%s)
EOF
