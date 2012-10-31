# Installation

Webmenu runs on relatively new Ubuntu releases such as Precise Pangolin and Quantal Quetzal.

## .deb installation

Get .deb package from [downloads](https://github.com/opinsys/webmenu/downloads)
and install it with dpkg.

    sudo dpkg -i webmenu.deb

The package contains the Webmenu itself, node.js and all the required node.js
modules. The package has few dependencies, but they should be all found from
the default Ubuntu repositories.

### Usage

Start it with `webmenu` command. It should be kept running always and a
launcher can be created like with this command:

    wget http://localhost:1337/show/ -q -O -


