# Revoke cached credentials before proceeding. Many targets mix sudo
# and non-sudo commands, we want to make sure user is prompted before
# doing anything as a super user.
$(shell sudo -k)

# Configurable parameters
rootfs_dir := /var/tmp/puavo-os/rootfs

_rootfs_bootstrap_mirror := $(shell				\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

_systemd_nspawn_cmd := systemd-nspawn -D '$(rootfs_dir)' --setenv=LANG=en_US.UTF-8

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
	@echo '    apply                       -  apply all rules to Puavo OS localhost'
	@echo '    release                     -  make a release commit'
	@echo '    rootfs-bootstrap            -  build Puavo OS root filesystem directory'
	@echo '    rootfs-shell                -  spawn shell from Puavo OS root filesystem'
	@echo '    rootfs-update               -  update Puavo OS root filesystem'
	@echo '    update                      -  update Puavo OS localhost'
	@echo
	@echo 'Variables:'
	@echo '    rootfs_dir                  -  set Puavo OS root filesystem directory [$(rootfs_dir)]'

.PHONY: release
release:
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog

$(rootfs_dir):
	sudo debootstrap							\
		--arch=amd64							\
		--include='make,devscripts,equivs,git,puppet-common,locales,    \
			sudo,lsb-release'					\
		--components=main,contrib,non-free				\
		jessie '$(rootfs_dir).tmp' '$(_rootfs_bootstrap_mirror)'
	sudo git clone . '$(rootfs_dir).tmp/puavo-os'

	sudo echo 'deb [trusted=yes] file:///puavo-os/debs /' \
		>'$(rootfs_dir).tmp/etc/apt/sources.list.d/puavo-os.list'

	echo 'en_US.UTF-8 UTF-8' >'$(rootfs_dir).tmp/etc/locale.gen'
	sudo systemd-nspawn -D '$(rootfs_dir).tmp' locale-gen

	sudo mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

.PHONY: rootfs-bootstrap
rootfs-bootstrap: $(rootfs_dir)

.PHONY: rootfs-shell
rootfs-shell: $(rootfs_dir)
	sudo $(_systemd_nspawn_cmd)

.PHONY: rootfs-update
rootfs-update: $(rootfs_dir) .ensure-head-is-release
	sudo git                                        \
		--git-dir='$(rootfs_dir)/puavo-os/.git' \
		--work-tree='$(rootfs_dir)/puavo-os'    \
		fetch origin
	sudo git                                        \
		--git-dir='$(rootfs_dir)/puavo-os/.git' \
		--work-tree='$(rootfs_dir)/puavo-os'    \
		reset --hard origin/HEAD

	sudo $(_systemd_nspawn_cmd) make -C /puavo-os update

.PHONY: update
update: /puavo-os
	make -C debs install-build-deps-stage1
	make -C debs stage1
	sudo apt-get update

	make -C debs install-build-deps-stage2
	make -C debs stage2
	sudo apt-get update

	sudo apt-get dist-upgrade -V -y			\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"

	make apply

.PHONY: apply
apply: /puavo-os
	sudo puppet apply				\
		--execute 'include image::allinone'	\
		--logdest /var/log/puavo-os/puppet.log	\
		--logdest console			\
		--modulepath '/puavo-os/parts/rules/rules/puppet'
