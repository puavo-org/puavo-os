Scripts for installing puavo hosts.

To use the preseed-feature, setup a file such as the following
to the bootserver path ``/images/preseeds/index.json``:

```
{
  "force-operation_NO_HANDS_ON_THE_WHEEL": "preseed-install",
  "force-preseed": "A more elaborate test",
  "colorize": {
    "battery": "70 80 90",
    "disk": "128000000000 256000000000 512000000000",
    "memory": "4183116800 8366233600 16732467200"
  },
  "templates": {
    "basic": {
      "admin_user": "iamadmin",
      "puavoPersonallyAdministered": "true"
    }
  },
  "preseeds": {
    "Lapinpollot-organisation preseed settings": {
      "template": "basic",
      "puavo_server": "lapinpollot.puavo.org"
    },
    "A more elaborate test": {
      "admin_user": "admin-two",
      "admin_password": "secrets-secrets",
      "devicetype": "laptop",
      "server": "test.puavo.org",
      "puavoPersonallyAdministered": "true",
      "puavoSomeRandomVariable": "some-random-value",
      "ask-install-without-raid": "no",
      "ask-write-partitions": "yes",
      "force-disk-device": "default",
      "force-imageoverlay-size": "5G",
      "force-register-defaults": "true",
      "force-partition": "default",
      "force-unpartitioned-space": "0G",
      "force-wipe-partition": "no"
    }
  }
}
```

Then when installing, choose "preseed-install".

In case the ``force-preseed`` option is left out,
an admin can pick up one of the preseed options.

The parameters ``ask-disk-device``, ``ask-imageoverlay-size``,
``ask-install-without-raid`` (bootserver installation only),
``ask-partition``, ``ask-unpartitioned-space``, ``ask-wipe-partition``
and ``ask-write-partitions`` can be used to set defaults for disk setup
related questions, but all these have ``force-`` equivalents in which
case user is not prompted for the question.  Using the force equivalents,
a value "default" can be used to pick the default value.

If you really want to use the ``force-operation`` method, remove the
``_NO_HANDS_ON_THE_WHEEL`` from the key.  It is possible to fully
automate an installation using the ``force-operation`` with
other ``force-\*`` options, but this is of course potentially
rather destructive.

``colorize`` may contain keys for ``battery``, ``cpu``, ``disk`` and
``memory``, with a string of three values.  These values represent limits
between "red/yellow", "yellow/grey" and "grey/green" colors in Puavo OS
console, for quick evaluation of machine characteristics.  There values
have reasonable default values, but may be configured through the preseed
mechanism.
