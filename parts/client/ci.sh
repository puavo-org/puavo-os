
#!/bin/sh

set -eu
set -x

sudo apt-get update
sudo apt-get install -y wget make devscripts git equivs

sudo make install-build-dep

if [ "${CI_TARGET_ARCH}" = i386 ]; then
        make deb
    else
        make deb-binary-arch
    fi
fi

cp ../puavo-ticket_* $HOME/results

