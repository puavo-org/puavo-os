# Debian package building

Get opinsys-debs repo

    sudo apt-get install devscript build-essential git-core libssl-dev
    git clone https://github.com/opinsys/opinsys-debs.git
    cd opinsys-deb

Package node-webkit (runtime dependency of webmenu)

    cd packages/node-webkit/
    debian/rules get-orig-source
    debuild -us -uc
    
Works only on 32bit for now :(
    
Package nodejs-bundle (build dependency of webmenu)

    cd packages/nodejs-bundle
    debian/rules get-orig-source
    debuild -us -uc
    
Package webmenu

    sudo dpkg -i packages/nodejs-bundle*.deb # build dependency
    cd packages/webmenu
    debian/rules get-orig-source
    debuild -us -uc
