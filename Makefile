changes_file = $(shell dpkg-parsechangelog -SSource)_$(shell dpkg-parsechangelog -SVersion)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes

mirror := $(shell awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}' /etc/apt/sources.list 2>/dev/null)

all:

help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    deb-pkg-install-deps  -  install build dependencies of Debian packages (requires root)'
	@echo '    deb-pkg               -  build Debian packages'
	@echo '    release               -  make release commit'
	@echo '    rootfs                -  build Puavo OS root filesystem directory (requires root)'

deb-pkg-install-deps:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

rootfs:
	debootstrap --arch=amd64 --include=devscripts jessie rootfs.tmp '$(mirror)'
	git clone . rootfs.tmp/opt/puavo-os
	mv rootfs.tmp rootfs

deb-pkg: release
	test -e '../$(changes_file)' || dpkg-buildpackage -b -uc
	test -e 'debs/$(changes_file)' || parts/devscripts/bin/cp-changes '../$(changes_file)' debs

release:
	@parts/devscripts/bin/git-update-debian-changelog

.PHONY: all			\
	deb-pkg-install-deps	\
	deb-pkg			\
	help			\
	release
