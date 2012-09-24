# Logrelay

Buffering log relay from UPD to HTTP. Used by [school-status](https://github.com/opinsys/school-status).

Required Ubuntu Lucid packages:

    ruby libeventmachine-ruby libjson-ruby


## Usage

Logrelay will listen to the UDP port specified in /etc/logrelay.rb and will relay
the UDP packets to given target as JSON HTTP POST. See `config.rb-example`.

## Packet format

The packet is constructed from multiple key-value pairs separated by line breaks:

    <key>:<value | [comma separated list of values]>

Key `type` is required for every packet. If it is defined as `log` Logrelay
will just log it and won't relay it. Usefull for debugging.

Example

    type:example
    key1:foo
    key2:[foo,bar]

See `stream_test_packets.sh` for netcat based examples

For Ruby based example see [wlan-state]() script.

[wlan-state]: https://github.com/opinsys/wlan-state
