Scripts for installing puavo hosts.

To use the preseed-feature, setup a file such as the following
to the bootserver path ``/images/preseeds/index.json``:

```
{
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
      "ask-disk-device": "sda",
      "ask-install-without-raid": "no",
      "force-imageoverlay-size": "5G",
      "force-partition": "whole",
      "force-unpartitioned-space": "0G",
      "force-wipe-partition": "no",
      "force-write-partitions": "yes"
    }
  }
}
```

Then when installing, choose "preseed-install".
