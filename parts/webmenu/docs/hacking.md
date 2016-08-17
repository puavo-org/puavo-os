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

    bin/webmenu

Devtools

    bin/webmenu --devtools

## Development

## Compile all assets manually

    make assets

## Watch stylus changes

    make watch-stylus

## Watch browserify changes

    make watch-browserify

## Translations

Translation are written in [MessageFormat][] style and they are kept in the
`i18n` directory. After changes translations must be compiled with:

    make i18n

Translations can be accessed from templates using the `i18n` helper:

    {{ i18n "logout.cancel" }}

Where `logout` is the json file name and `cancel` a key name in the json
object.

To create new translation just create a new directory for it  to `i18n` and run
`make i18n`:

    $ mkdir i18n/se
    $ make i18n

and edit the generated files. Remove the `[UNTRANSLATED]` tags from the strings
after translating.

For content translations see [menujson.md][menujson_i18n].

## menu.json development

For simple [menu.json][] development on Opinsys desktops copy the current
`menu.json` to `~/.config/webmenu/menu.json` and restart Webmenu manually from
the console.

Shutdown Webmenu:

    $ webmenu-spawn --webmenu-exit

Get current menu.json from Github:

    $ wget https://github.com/opinsys/webmenu/raw/master/menu.json -O ~/.config/webmenu/menu.json

Webmenu must be restarted after every change.

For json editing <http://jsoneditoronline.org/> can be used to avoid some
syntax errors.

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
[menu.json]: https://github.com/opinsys/webmenu/blob/master/docs/menujson.md
