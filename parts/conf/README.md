# Puavo Conf

Puavo Conf is a database of parameters that control how a Puavo
host/device behaves. There is a library "libpuavoconf" that can be used
by programs, and a simple program "puavo-conf" that can be used to
get/set values on database. Database consists of key/value-pairs. Both
keys and values are character strings (can not contain NUL-byte).

To build on Debian, install:

- libdb-dev
- libtool-bin

How to use:

    puavo-conf key       # retrieves value for key
    puavo-conf key value # sets the value of key to "value"
