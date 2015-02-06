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

- libjansson
- ruby1.9.1
- ruby-puavobs

Compile and install
-------------------

    make
    sudo make install prefix=/usr
