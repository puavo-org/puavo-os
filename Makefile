rootfs_dir    := /var/tmp/puavo-os/rootfs
rootfs_mirror := $(shell 					\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

.PHONY: all
all: debs

.PHONY: .ensure-head-is-release
.ensure-head-is-release:
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog -z

.PHONY: debs
debs: .ensure-head-is-release
	$(MAKE) -C debs

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    all                         -  build everything'
	@echo '    debs                        -  build all Debian packages'
	@echo '    install-build-deps          -  install build dependencies (requires root)'
	@echo '    release                     -  make a release commit'
	@echo '    rootfs-bootstrap            -  build Puavo OS root filesystem directory (requires root)'
	@echo '    rootfs-shell                -  spawn shell from Puavo OS root filesystem (requires root)'
	@echo '    rootfs-update               -  update Puavo OS root filesystem (requires root)'

.PHONY: install-build-deps
install-build-deps:
	$(MAKE) -C debs install-build-deps

.PHONY: release
release:
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog

$(rootfs_dir):
	mkdir -p '$(rootfs_dir).tmp'
	debootstrap --arch=amd64 --include=make,devscripts,equivs,git,puppet-common,locales jessie \
		'$(rootfs_dir).tmp' '$(rootfs_mirror)'
	git clone . '$(rootfs_dir).tmp/puavo-os'

	echo 'deb [trusted=yes] file:///puavo-os/debs /' \
		>'$(rootfs_dir).tmp/etc/apt/sources.list.d/puavo-os.list'

	echo 'en_US.UTF-8 UTF-8' >'$(rootfs_dir).tmp/etc/locale.gen'
	systemd-nspawn -D '$(rootfs_dir).tmp' locale-gen

	mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

.PHONY: rootfs-bootstrap
rootfs-bootstrap: $(rootfs_dir)

.PHONY: rootfs-shell
rootfs-shell: $(rootfs_dir)
	systemd-nspawn -D '$(rootfs_dir)'

.PHONY: rootfs-update
rootfs-update: $(rootfs_dir) .ensure-head-is-release
	git                                             \
		--git-dir='$(rootfs_dir)/puavo-os/.git' \
		--work-tree='$(rootfs_dir)/puavo-os'    \
		fetch origin
	git                                             \
		--git-dir='$(rootfs_dir)/puavo-os/.git' \
		--work-tree='$(rootfs_dir)/puavo-os'    \
		reset --hard origin/HEAD

	systemd-nspawn -D '$(rootfs_dir)' make -C /puavo-os \
		install-build-deps

	systemd-nspawn -D '$(rootfs_dir)' make -C /puavo-os/debs

	systemd-nspawn -D '$(rootfs_dir)' apt-get update
	systemd-nspawn -D '$(rootfs_dir)' apt-get dist-upgrade -V -y	\
		-o Dpkg::Options::="--force-confdef"			\
		-o Dpkg::Options::="--force-confold"

	systemd-nspawn -D '$(rootfs_dir)' --setenv=LANG=en_US.UTF-8	\
		puppet apply						\
		--execute 'include image::basic'			\
		--logdest /var/log/puavo-os/puppet.log			\
		--logdest console					\
		--modulepath '/puavo-os/parts/rules/rules/puppet'
