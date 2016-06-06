rootfs_dir    := /var/tmp/puavo-os/rootfs
rootfs_mirror := $(shell 					\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

subdirs := parts

all: $(subdirs)

$(subdirs):
	make -C $@

help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    deb-pkg-build               -  build Debian packages'
	@echo '    deb-pkg-install-build-deps  -  install build dependencies of Debian packages (requires root)'
	@echo '    release                     -  make release commit'
	@echo '    rootfs                      -  build Puavo OS root filesystem directory (requires root)'

deb-pkg-install-build-deps: .deb-pkg-install-build-deps-parts \
	.deb-pkg-install-build-deps-ports

.deb-pkg-install-build-deps-parts:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

.deb-pkg-install-build-deps-ports:
	$(MAKE) -C ports deb-pkg-install-build-deps

rootfs: $(rootfs_dir)

$(rootfs_dir):
	mkdir -p '$(rootfs_dir).tmp'
	debootstrap --arch=amd64 --include=devscripts jessie \
		'$(rootfs_dir).tmp' '$(rootfs_mirror)'
	git clone . '$(rootfs_dir).tmp/usr/local/src/puavo-os'
	echo 'deb [trusted=yes] file:///usr/local/src/puavo-os/debs /' \
		>'$(rootfs_dir).tmp/etc/apt/sources.list.d/puavo-os.list'
	mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

release:
	@parts/devscripts/bin/git-update-debian-changelog

debs/Packages: deb-pkg-build
	apt-ftparchive --db debs/db packages debs >$@

debs/Packages.gz: debs/Packages
	gzip -f -k $<

deb-pkg-build: .deb-pkg-build-parts .deb-pkg-build-ports

.deb-pkg-build-parts: release
	dpkg-buildpackage -b -uc && parts/devscripts/bin/cp-changes debs

.deb-pkg-build-ports:
	$(MAKE) -C ports deb-pkg-build

deb-pkg-update-repo: debs/Packages.gz

.PHONY: all				\
	deb-pkg-build			\
	.deb-pkg-build-parts		\
	.deb-pkg-build-ports		\
	deb-pkg-install-build-deps	\
	deb-pkg-update-repo		\
	help				\
	release				\
	rootfs				\
	$(subdirs)
