# Hacking

Here's how to setup the development environment for now:

Get dependecies listed in [`debian/control`](https://github.com/opinsys/opinsys-debs/blob/master/packages/webmenu/debian/control).

`node-webkit` can be found from from <https://github.com/rogerwang/node-webkit#downloads>.
The `nw` binary should be put in the `PATH`.

Make sure you use the version listed in the [`Makefile`](https://github.com/opinsys/webmenu/blob/master/Makefile).

Compile Webmenu

    make

## Running

Basic

    nw .

Devtools

    devtools=1 nw .
    
With reload loop and crash reporting

    bin/webmenu .

## Development

## Stylus compiling

    grunt stylus

or watch with

    make watch

## Tests

No broken tests on master!

Run in node-webkit:

    make test-nw

Without window:

    make test-nw-hidden

In [PhantomJS][] used on [Travis-CI][]

    make test-client

node.js tests:

    make test-node

Debug tests in a real browser:

    make serve
    
## Installation

    sudo make install


[Travis-CI]: https://travis-ci.org/opinsys/webmenu
[PhantomJS]: http://phantomjs.org/
