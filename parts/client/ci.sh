
#!/bin/sh

set -eu
set -x

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts aptirepo-upload

sudo make install-build-dep

dch-suffix --inplace --distribution $CI_TARGET_DIST --jenkins debian.default/changelog

if [ "${CI_TARGET_ARCH}" = i386 ]; then
        make deb
    else
        make deb-binary-arch
    fi
fi

aptirepo-upload -r $APTIREPO_REMOTE -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" ../puavo-client*.changes
