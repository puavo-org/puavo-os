# Revoke cached credentials before proceeding. Many targets mix sudo
# and non-sudo commands, we want to make sure user is prompted before
# doing anything as a super user.
$(shell sudo -k)

# Configurable parameters
rootfs_dir := /var/tmp/puavo-os/rootfs
image_dir     := /srv/puavo-os-images

_image_class := allinone
_image_file  := $(image_dir)/puavo-os-$(_image_class)-$(shell date -u +%Y-%m-%d-%H%M%S)_amd64.img

_debootstrap_mirror := $(shell				\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

_debootstrap_packages := devscripts,equivs,git,locales,lsb-release,make,\
                         puppet-common,sudo

_systemd_nspawn_cmd := systemd-nspawn -D '$(rootfs_dir)' --setenv=LANG=en_US.UTF-8

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    help                        -  display this help and exit'
	@echo '    rootfs                      -  build Puavo OS rootfs from scratch'
	@echo '    image                       -  pack container to a squashfs image'
	@echo '    spawn-rootfs-shell          -  spawn shell from Puavo OS rootfs'
	@echo '    update-rootfs               -  update Puavo OS container'
	@echo '    container-sync              -  synchronize Puavo OS container repository with the current repository'
	@echo '    local-update                -  update Puavo OS localhost'
	@echo '    push-release                -  make a release commit and publish it'
	@echo
	@echo 'Variables:'
	@echo '    rootfs_dir               -  set Puavo OS container directory [$(rootfs_dir)]'
	@echo '    image_dir                   -  set Puavo OS image directory [$(image_dir)]'

.PHONY: .ensure-head-is-release
.ensure-head-is-release:
	@parts/devscripts/bin/git-dch -f debs/puavo-os/debian/changelog -z

$(rootfs_dir):
	@echo ERROR: container does not exist, make rootfs first >&2
	@false

.PHONY: rootfs
rootfs:
	@[ ! -e '$(rootfs_dir)' ] || \
		{ echo ERROR: container directory '$(rootfs_dir)' already exists >&2; false; }
	sudo debootstrap					\
		--arch=amd64					\
		--include='$(_debootstrap_packages)'	\
		--components=main,contrib,non-free		\
		jessie '$(rootfs_dir).tmp' '$(_debootstrap_mirror)'

	sudo git clone . '$(rootfs_dir).tmp/puavo-os'

	echo 'deb [trusted=yes] file:///puavo-os/debs /' \
	| sudo tee '$(rootfs_dir).tmp/etc/apt/sources.list.d/puavo-os.list'

	sudo sed -r -i 's/^# (en_US.UTF-8 UTF-8)$$/\1/' \
		'$(rootfs_dir).tmp/etc/locale.gen'
	sudo systemd-nspawn -D '$(rootfs_dir).tmp' locale-gen

	sudo mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

	make update-rootfs

$(image_dir):
	sudo mkdir -p '$(image_dir)'

.PHONY: image
image: $(rootfs_dir) $(image_dir)
	sudo mksquashfs '$(rootfs_dir)' '$(_image_file).tmp'			\
		-noappend -no-recovery -wildcards				\
		-ef parts/ltsp/tools/image-build/config/puavoimage.excludes	\
		|| { rm -f '$(_image_file).tmp'; false; }
	sudo mv '$(_image_file).tmp' '$(_image_file)'
	@echo Built '$(image_file)' successfully.

.PHONY: spawn-rootfs-shell
spawn-rootfs-shell: $(rootfs_dir)
	sudo $(_systemd_nspawn_cmd)

.PHONY: rootfs
container-sync: $(rootfs_dir) .ensure-head-is-release
	sudo git						\
		--git-dir='$(rootfs_dir)/puavo-os/.git'	\
		--work-tree='$(rootfs_dir)/puavo-os'		\
		fetch origin
	sudo git						\
		--git-dir='$(rootfs_dir)/puavo-os/.git'	\
		--work-tree='$(rootfs_dir)/puavo-os'		\
		reset --hard origin/HEAD

.PHONY: update-rootfs
update-rootfs: container-sync
	sudo $(_systemd_nspawn_cmd) make -C /puavo-os local-update

.PHONY: local-update
local-update: /puavo-os
	make -C debs update-repo

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
