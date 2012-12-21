# Hacking

Here's how to setup the development environment for now:

Ubuntu dependecies

    sudo add-apt-repository ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install nodejs npm nodejs-dev wmctrl git-core build-essential gnome-themes-extras
    
And get node-webkit from <https://github.com/rogerwang/node-webkit#downloads>

## Running

Basic

    nw .

Devtools

    devtools=1 nw .

## Tests

No broken tests on master!

Run in node-webkit:

    make test-nw

Without window:

    make test-nw-hidden

node.js tests:

    make test-node



Travi-CI <https://travis-ci.org/opinsys/webmenu>

