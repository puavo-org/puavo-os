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

## Translations

Translation are written in [MessageFormat][] style and they are kept in the
`i18n` directory. After changes translations must be compiled with:

    make i18n

Translations can be accessed from templates using the `i18n` helper:

    {{ i18n "logout.cancel" }}

Where `logout` is the json file name and `cancel` a key name in the json
object.

For content translations see [menujson.md][menujson_i18n].

## Tests

No broken tests on master!

Run in node-webkit:

    make test-nw

Without window:

    make test-nw-hidden

node.js tests:

    make test-node

Debug tests in a real browser:

    make serve

## Installation

    sudo make install


[Travis-CI]: https://travis-ci.org/opinsys/webmenu
[PhantomJS]: http://phantomjs.org/
[MessageFormat]: https://github.com/SlexAxton/messageformat.js
[menujson_i18n]: https://github.com/opinsys/webmenu/blob/master/docs/menujson.md#translations
