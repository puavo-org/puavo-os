changes_file = $(shell dpkg-parsechangelog -SSource)_$(shell dpkg-parsechangelog -SVersion)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes

rootfs_dir    := /var/tmp/puavo-os/rootfs
rootfs_mirror := $(shell awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}' /etc/apt/sources.list 2>/dev/null)

subdirs := parts

all: $(subdirs)

$(subdirs):
	make -C $@

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

rootfs: $(rootfs_dir)

$(rootfs_dir):
	mkdir -p '$(rootfs_dir).tmp'
	debootstrap --arch=amd64 --include=devscripts jessie '$(rootfs_dir).tmp' '$(rootfs_mirror)'
	git clone . '$(rootfs_dir).tmp/usr/local/src/puavo-os'
	mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

deb-pkg: release
	test -e '../$(changes_file)' || dpkg-buildpackage -b -uc
	test -e 'debs/$(changes_file)' || parts/devscripts/bin/mv-changes '../$(changes_file)' debs

release:
	@parts/devscripts/bin/git-update-debian-changelog

.PHONY: all			\
	deb-pkg-install-deps	\
	deb-pkg			\
	help			\
	release			\
	rootfs			\
	$(subdirs)
