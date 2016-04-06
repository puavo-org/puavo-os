changes_file = ../$(shell dpkg-parsechangelog -SSource)_$(shell dpkg-parsechangelog -SVersion)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes

mirror :=

all:

apt-get-build-dep:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

rootfs:
	debootstrap --arch=amd64 --include=devscripts jessie rootfs.tmp '$(mirror)'
	git clone . rootfs.tmp/opt/puavo-os
	mv rootfs.tmp rootfs

debs: release
	dpkg-buildpackage -b -uc
	parts/devscripts/bin/cp-changes '$(changes_file)' debs
	@echo Done.

release:
	@parts/devscripts/bin/git-update-debian-changelog

.PHONY: all                           \
        apt-get-build-dep             \
        debs                          \
        release
