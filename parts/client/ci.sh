
#!/bin/sh

set -eu
set -x

sudo apt-get update
sudo apt-get install -y wget make devscripts git equivs

. /etc/lsb-release
echo "deb http://archive.opinsys.fi/git-master ${DISTRIB_CODENAME} main" > /tmp/archive.list
sudo mv /tmp/archive.list /etc/apt/sources.list.d/archive.list
wget -O - http://archive.opinsys.fi/key | sudo apt-key add -
sudo apt-get update

sudo make install-build-dep


if [ "$(uname -p)" = "i686" ]; then
    make deb
else
    make deb-binary-arch
fi

mkdir -p $HOME/results
cp ../puavo-client_* $HOME/results

