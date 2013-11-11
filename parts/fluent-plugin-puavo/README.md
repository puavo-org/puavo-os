
# fluent-plugin-puavo


A [fluentd](http://fluentd.org/) plugin which intelligently configures itself
on puavo managed installations.

On ltsp servers and fat clients it will just auto configure the default
[out_forward][] plugin to forward packets to a near by boot server.

On boot servers and laptops it will forward the packets to the cloud
installation of puavo-rest ([fluent_relay][] resource) using http(s) with the
credentials of the device.

## Configuration

```
<match **>
  type puavo

  # These are automatically detected but can be overridden here for development
  # purposes
  #rest_host localhost
  #rest_port 9393

  <device bootserver|laptop>
    # Use longer flush interval for boot servers and laptops to avoid ddosing
    # our cloud installation of puavo-rest
    flush_interval 60s
  </device>

  <device ltspserver|fatclient>
    # ltsp servers and fat clients just forwards packets to a boot server on a
    # local network. Small flush interval is ok.
    flush_interval 1s
  </device>

  <server>
    # Boot server configuration
    name bootserver

    # Boot server address and port is automatically detected also, but can be
    # overridden for development purposes
    #port 4567
    #host localhost
  </server>

  buffer_type file
  buffer_path /tmp/fluent-plugin-puavo.*.buffer
</match>
```

[out_forward]: http://docs.fluentd.org/articles/out_forward
[fluent_relay]: https://github.com/opinsys/puavo-users/blob/master/rest/resources/fluent_relay.rb

