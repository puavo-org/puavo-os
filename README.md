[![Build Status](https://travis-ci.org/opinsys/puavo-logrelay.png?branch=master)](https://travis-ci.org/opinsys/puavo-logrelay)

# puavo-logrelay

Buffering log relay.

## Installation

Dependencies: node.js

    make
    sudo make install

## Usage

Logrelay will listen to the UDP port specified in /etc/logrelay.json
and will relay the UDP packets to given target as JSON HTTP POST.

    sudo puavo-logrelay

## Packet format

The packet is constructed from multiple key-value pairs separated by line
breaks:

    <key>:<value | [comma separated list of values between square brackets]>

Key `type` is required for every packet.  If it is defined as `log` Logrelay
will just log it and won't relay it.  Useful for debugging.

Example

    type:example
    key1:foo
    key2:[foo,bar]

See `stream_test_packets.sh` for netcat based examples

## See also

  - [school-status](https://github.com/opinsys/school-status)
  - [puavo-monitor](https://github.com/opinsys/puavo-monitor)
