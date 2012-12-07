# Hacking

Here's how to setup the development environment for now:

Ubuntu dependecies

    sudo add-apt-repository ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install nodejs npm nodejs-dev wmctrl git-core build-essential libgtk2.0-dev gnome-themes-extras

## Running

Basic

    bin/webmenu

Disable hiding

    bin/webmenu --no-hide

With webkit inspector. Implies --no-hide

    bin/webmenu --dev-tools

## Tests

No broken tests on master!

    bin/test

Can be also debugged from http://localhost:1234/tests.html

Travi-CI <https://travis-ci.org/opinsys/webmenu>

