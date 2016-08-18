# Revoke cached credentials before proceeding. Many targets mix sudo
# and non-sudo commands, we want to make sure user is prompted before
# doing anything as a super user.
$(shell sudo -k)

# Configurable parameters
container_dir := /var/tmp/puavo-os/container

_container_bootstrap_mirror := $(shell				\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

_systemd_nspawn_cmd := systemd-nspawn -D '$(container_dir)' --setenv=LANG=en_US.UTF-8

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
	@echo '    container-shell             -  spawn shell from Puavo OS container'
	@echo '    container-update            -  update Puavo OS container'
	@echo '    debs                        -  build all Debian packages'
	@echo '    local-update                -  update Puavo OS localhost'
	@echo '    release                     -  make a release commit'
	@echo
	@echo 'Variables:'
	@echo '    container_dir               -  set Puavo OS container directory [$(container_dir)]'

.PHONY: release
release:
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog

$(container_dir):
	sudo debootstrap							\
		--arch=amd64							\
		--include='make,devscripts,equivs,git,puppet-common,locales,    \
			sudo,lsb-release'					\
		--components=main,contrib,non-free				\
		jessie '$(container_dir).tmp' '$(_container_bootstrap_mirror)'
	sudo git clone . '$(container_dir).tmp/puavo-os'

	sudo echo 'deb [trusted=yes] file:///puavo-os/debs /' \
		>'$(container_dir).tmp/etc/apt/sources.list.d/puavo-os.list'

	echo 'en_US.UTF-8 UTF-8' >'$(container_dir).tmp/etc/locale.gen'
	sudo systemd-nspawn -D '$(container_dir).tmp' locale-gen

	sudo mv '$(container_dir).tmp' '$(container_dir)'

.PHONY: container-shell
container-shell: $(container_dir)
	sudo $(_systemd_nspawn_cmd)

.PHONY: container-update
container-update: $(container_dir) .ensure-head-is-release
	sudo git						\
		--git-dir='$(container_dir)/puavo-os/.git'	\
		--work-tree='$(container_dir)/puavo-os'		\
		fetch origin
	sudo git						\
		--git-dir='$(container_dir)/puavo-os/.git'	\
		--work-tree='$(container_dir)/puavo-os'		\
		reset --hard origin/HEAD

	sudo $(_systemd_nspawn_cmd) make -C /puavo-os local-update

.PHONY: local-update
local-update: /puavo-os
	make -C debs install-build-deps-stage1
	make -C debs stage1

	make -C debs install-build-deps-stage2
	make -C debs stage2

	sudo apt-get update
	sudo apt-get dist-upgrade -V -y			\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"

	sudo puppet apply				\
		--execute 'include image::allinone'	\
		--logdest /var/log/puavo-os/puppet.log	\
		--logdest console			\
		--modulepath '/puavo-os/parts/rules/rules/puppet'
