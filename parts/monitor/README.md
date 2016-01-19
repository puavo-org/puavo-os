
# puavo-monitor

Monitor daemon for fat- and thinclients. Keeps active tcp connection open to the
[logrelay][] daemon. Logrelay uses that connection to determine whether the
client is up and running.

## Installation

    make
    sudo make install

## Usage

Just execute

    puavo-monitor

[logrelay]: https://github.com/opinsys/puavo-logrelay

