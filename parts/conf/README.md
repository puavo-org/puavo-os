# Puavo Conf

Puavo Conf is a database of parameters that control how a Puavo
host/device behaves. There is a library "libpuavoconf" that can be used
by programs, and a simple program "puavo-conf" that can be used to
get/set values on database. Database consists of key/value-pairs. Both
keys and values are character strings (can not contain NUL-byte).

## Build dependencies

- libdb-dev
- libtool-bin

## Building

By default, builds are targeted to `/usr/local` prefix. To make a build
targeted to `/usr` instead, run:

    make prefix=/usr
    sudo make install

## Usage

    puavo-conf key       # retrieves value for key
    puavo-conf key value # sets the value of key to "value"
