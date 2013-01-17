# puavo-logrelay

Buffering log relay.


## See also

  - [school-status](https://github.com/opinsys/school-status)
  - [puavo-monitor](https://github.com/opinsys/puavo-monitor)

## Usage

Logrelay will listen to the UDP port specified in /etc/logrelay.json
and will relay the UDP packets to given target as JSON HTTP POST.

## Packet format

The packet is constructed from multiple key-value pairs separated by line
breaks:

    <key>:<value | [comma separated list of values]>

Key `type` is required for every packet.  If it is defined as `log` Logrelay
will just log it and won't relay it.  Useful for debugging.

Example

    type:example
    key1:foo
    key2:[foo,bar]

See `stream_test_packets.sh` for netcat based examples

