# Installation

Webmenu runs on relatively new Ubuntu releases such as Precise Pangolin and Quantal Quetzal.


## Source installation

Here's how to setup the development environment for now:

Ubuntu dependecies

    sudo add-apt-repository ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install nodejs npm nodejs-dev wmctrl git-core build-essential libgtk2.0-dev

Fetch and build the fork for 32 bit machines (bit complicated sorry)

    git clone git://github.com/opinsys/appjs.git appjs
    cd appjs/
    git checkout origin/epeli
    mkdir deps
    cd deps/
    wget https://github.com/downloads/appjs/appjs/cef_binary_1.1180.724_linux_ia32.tar.gz
    tar xzvf cef_binary_1.1180.724_linux_ia32.tar.gz
    mv cef_binary_1.1180.724_linux_ia32 cef
    wget http://dists.appjs.org/0.0.19/appjs-0.0.19-linux-ia32.tar.gz
    tar xzvf appjs-0.0.19-linux-ia32.tar.gz
    cp app/data/bin/libffmpegsumo.so cef/Release/lib.target/
    cd ..
    cp $(which node) data/linux/ia32/node-bin/
    npm install

64bit

    git clone git://github.com/opinsys/appjs.git appjs
    cd appjs/
    git checkout origin/epeli
    mkdir deps
    cd deps/
    wget https://github.com/downloads/appjs/appjs/cef_binary_1.1180.724_linux_x64.tar.gz
    tar xzvf cef_binary_1.1180.724_linux_x64.tar.gz 
    mv cef_binary_1.1180.724_linux_x64 cef
    cd ..
    cp $(which node) data/linux/x64/node-bin/
    npm install


Fetch and build Web Menu inside our fork

    cd app/data
    git clone git@github.com:opinsys/webmenu.git
    cd webmenu
    npm install
    # Make sure to use our fork of appjs
    rm -rf node_modules/appjs*

## Binary installation

Binary tarballs contains everything needed for Webmenu to run except Node.js npm & wmctrl.

Get them using apt-get:

    sudo add-apt-repository ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install nodejs npm nodejs-dev wmctrl

Get binary tarball from [downloads](https://github.com/opinsys/webmenu/downloads)

## Usage


Go in to the webmenu directory and start it `npm start`

You can also view it from http://localhost:1337 using a browser

You can create menu launcher with this command

    wget http://localhost:1337/show/ -q -O -


