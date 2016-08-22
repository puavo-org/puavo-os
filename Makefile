# Revoke cached credentials before proceeding. Many targets mix sudo
# and non-sudo commands, we want to make sure user is prompted before
# doing anything as a super user.
$(shell sudo -k)

# Configurable parameters
container_dir := /var/tmp/puavo-os/container
image_dir     := /srv/puavo-os-images

_image_class := allinone
_image_file  := $(image_dir)/puavo-os-$(_image_class)-$(shell date -u +%Y-%m-%d-%H%M%S)_amd64.img

_container_bootstrap_mirror := $(shell				\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

_container_bootstrap_packages := devscripts,equivs,git,locales,lsb-release,\
                                 make,puppet-common,sudo

_systemd_nspawn_cmd := systemd-nspawn -D '$(container_dir)' --setenv=LANG=en_US.UTF-8

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    help                        -  display this help and exit'
	@echo '    image                       -  pack container to a squashfs image'
	@echo '    container-shell             -  spawn shell from Puavo OS container'
	@echo '    container-update            -  update Puavo OS container'
	@echo '    local-update                -  update Puavo OS localhost'
	@echo '    push-release                -  make a release commit and publish it'
	@echo
	@echo 'Variables:'
	@echo '    container_dir               -  set Puavo OS container directory [$(container_dir)]'
	@echo '    image_dir                   -  set Puavo OS image directory [$(image_dir)]'

.PHONY: .ensure-head-is-release
.ensure-head-is-release:
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog -z

$(container_dir):
	sudo debootstrap					\
		--arch=amd64					\
		--include='$(_container_bootstrap_packages)'	\
		--components=main,contrib,non-free		\
		jessie '$(container_dir).tmp' '$(_container_bootstrap_mirror)'

	sudo git clone . '$(container_dir).tmp/puavo-os'

	echo 'deb [trusted=yes] file:///puavo-os/debs /' \
	| sudo tee '$(container_dir).tmp/etc/apt/sources.list.d/puavo-os.list'

	sudo sed -r -i 's/^# (en_US.UTF-8 UTF-8)$$/\1/' \
		'$(container_dir).tmp/etc/locale.gen'
	sudo systemd-nspawn -D '$(container_dir).tmp' locale-gen

	sudo mv '$(container_dir).tmp' '$(container_dir)'

.PHONY: image
image: $(container_dir)
	sudo mkdir -p '$(image_dir)'
	sudo mksquashfs '$(container_dir)' '$(_image_file)'	\
		-noappend -no-recovery -wildcards		\
		-ef parts/ltsp/tools/image-build/config/puavoimage.excludes

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

	make .local-configure

.PHONY: .local-configure
.local-configure: /puavo-os
	sudo puppet apply					\
		--execute 'include image::$(_image_class)'	\
		--logdest /var/log/puavo-os/puppet.log		\
		--logdest console				\
		--modulepath 'parts/rules/rules/puppet'

/puavo-os:
	@echo ERROR: localhost is not Puavo OS system >&2
	@false

.PHONY: .release
.release:
	EDITOR=.aux/drop-release-commits git rebase -p -i origin/master
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog

.PHONY: push-release
push-release: .release
	git push origin master:master
