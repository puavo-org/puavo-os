puavoadmins
===========

This project provides following components for intergrating Puavo
organization owners to the host:

- Commands for updating /etc/puavo/org.json from Puavo via its REST
  API, validating it and ensuring home directories exist for all
  puavoadmins.

- NSS module which provides group and passwd databases.

  - Uses /etc/puavo/org.json as a backend.

  - Supports getpwnam(), getpwuid(), getpwent(), getgrnam(),
    getgrgid(), getgrent() and their reentrant counterparts.

  - Populates group database with puavoadmins group (gid=555). All
    puavoadmins belong to this group.

  - Populates passwd database with all puavoadmins listed in
    /etc/puavo/org.json.

- Command for outputting puavoadmin's public keys in OpenSSH
  authorized_keys format. Intended to be used as AuthorizedKeysCommand
  (requires OpenSSH 6.1 or newer).

Requirements
------------

- libjson-c
- ruby
- ruby-puavobs

Compile and install
-------------------

    make
    sudo make install # Implicitly defines prefix=/usr

Configuration
-------------

1. Run /usr/lib/puavoadmins-update-orgjson to fetch
   /etc/puavo/org.json

2. Add puavoadmins to passwd and group databases sources by modifying
   /etc/nsswitch.conf.

3. Optionally add following options to /etc/ssh/sshd_config:

     AuthorizedKeysCommand /usr/lib/puavoadmins-ssh-authorized-keys
     AuthorizedKeysCommandUser nobody

   And then restart/reload sshd.
