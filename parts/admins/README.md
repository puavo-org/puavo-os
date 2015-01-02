puavoadmins
===========

This project provides following components for intergrating Puavo
organization admininstrators to the host:

- NSS module which provides group and passwd databases.

  - Supports getpwnam(), getpwuid(), getpwent(), getgrnam(),
    getgrgid(), getgrent() and their reentrant counterparts.

- Command for feeding public SSH keys of Puavo administrators to sshd
  via AuthorizedKeysCommand (requires OpenSSH 6.1 or newer).

Requirements
------------

- libjansson

Compile and install
-------------------

    make
    sudo make install prefix=/usr
