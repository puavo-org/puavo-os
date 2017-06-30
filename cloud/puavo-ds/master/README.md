# LDAP master setup tools

Install package from [opinsys/opinsys-debs](https://github.com/opinsys/opinsys-debs/tree/master/packages/puavo-ds)

As root init database

    # puavo-init-ldap

Add organisation

    # puavo-add-new-organisation hogwarts

## Using on virtual machines

Often entropy for randomness is lacking on virtual machines
which might cause `puavo-add-new-organisation` to timeout.
This can be worked around with rng-tools:

    # apt-get install rng-tools
    
Add `HRNGDEVICE=/dev/urandom` to `/etc/default/rng-tools` and (re)start:

    # echo "HRNGDEVICE=/dev/urandom" > /etc/default/rng-tools
    # /etc/init.d/rng-tools restart

