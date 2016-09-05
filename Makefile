# Public, configurable variables
debootstrap_mirror	:= http://httpredir.debian.org/debian/
debootstrap_suite	:= jessie
image_class		:= allinone
image_dir		:= /srv/puavo-os-images
rootfs_dir		:= /var/tmp/puavo-os/rootfs

include .opinsys/defaults.mk

_repo_name   := $(shell basename $(shell git rev-parse --show-toplevel))
_image_file  := $(image_dir)/$(_repo_name)-$(image_class)-$(debootstrap_suite)-$(shell date -u +%Y-%m-%d-%H%M%S)-amd64.img

_debootstrap_packages := devscripts,equivs,git,locales,lsb-release,make,\
                         puppet-common,sudo

_systemd_nspawn_machine_name := \
  $(notdir $(rootfs_dir))-$(shell tr -dc A-Za-z0-9 < /dev/urandom | head -c8)
_systemd_nspawn_cmd := systemd-nspawn -D '$(rootfs_dir)' \
			 -M '$(_systemd_nspawn_machine_name)'

_subdirs := debs parts

.PHONY: all
all: $(_subdirs)

.PHONY: $(_subdirs)
$(_subdirs):
	$(MAKE) -C $@

.PHONY: install
install: install-parts
	$(MAKE) configure

.PHONY: install-parts
install-parts: /$(_repo_name)
	$(MAKE) -C parts install prefix=/usr sysconfdir=/etc

.PHONY: install-build-deps
install-build-deps: prepare
	$(MAKE) -C debs install-build-deps-toolchain
	$(MAKE) -C debs toolchain
	$(MAKE) -C debs install-build-deps

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    all                  build all'
	@echo '    configure            configure all'
	@echo '    help                 display this help and exit'
	@echo '    install              install all'
	@echo '    install-build-deps   install all build dependencies'
	@echo '    install-parts        install all parts'
	@echo '    push-release         make a release commit and publish it'
	@echo '    rootfs-debootstrap   build Puavo OS rootfs from scratch'
	@echo '    rootfs-image         pack rootfs to a squashfs image'
	@echo '    rootfs-shell         spawn shell from Puavo OS rootfs'
	@echo '    rootfs-update        update Puavo OS rootfs'
	@echo '    rootfs-sync-repo     sync Puavo OS rootfs repo with the current repo'
	@echo '    update               update Puavo OS localhost'
	@echo
	@echo 'Variables:'
	@echo '    debootstrap_mirror   debootstrap mirror [$(debootstrap_mirror)]'
	@echo '    image_dir            directory where images are built [$(image_dir)]'
	@echo '    rootfs_dir           Puavo OS rootfs directory [$(rootfs_dir)]'

$(rootfs_dir):
	@echo ERROR: rootfs does not exist, make rootfs first >&2
	@false

.PHONY: rootfs-debootstrap
rootfs-debootstrap:
	@[ ! -e '$(rootfs_dir)' ] || \
		{ echo ERROR: rootfs directory '$(rootfs_dir)' already exists >&2; false; }
	sudo debootstrap					\
		--arch=amd64					\
		--include='$(_debootstrap_packages)'	\
		--components=main,contrib,non-free		\
		'$(debootstrap_suite)'				\
		'$(rootfs_dir).tmp' '$(debootstrap_mirror)'

	sudo git clone . '$(rootfs_dir).tmp/$(_repo_name)'

	sudo ln -s '/$(_repo_name)/.aux/policy-rc.d' '$(rootfs_dir).tmp/usr/sbin/policy-rc.d'

	sudo mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

$(image_dir):
	sudo mkdir -p '$(image_dir)'

.PHONY: rootfs-image
rootfs-image: $(rootfs_dir) $(image_dir)
	sudo mksquashfs '$(rootfs_dir)' '$(_image_file).tmp'	\
		-noappend -no-recovery -wildcards		\
		-ef '.aux/$(image_class).excludes'		\
		|| { rm -f '$(_image_file).tmp'; false; }
	sudo mv '$(_image_file).tmp' '$(_image_file)'
	@echo Built '$(image_file)' successfully.

.PHONY: rootfs-shell
rootfs-shell: $(rootfs_dir)
	sudo $(_systemd_nspawn_cmd)

.PHONY: rootfs-sync-repo
rootfs-sync-repo: $(rootfs_dir)
	sudo rsync -rl . '$(rootfs_dir)/$(_repo_name)/'

.PHONY: rootfs-update
rootfs-update: rootfs-sync-repo
	sudo $(_systemd_nspawn_cmd) $(MAKE) -C '/$(_repo_name)' update

.PHONY: prepare
prepare: /$(_repo_name)
	$(MAKE) -C debs update-repo

	sudo puppet apply						\
		--execute 'include image::$(image_class)::prepare'	\
		--logdest '/var/log/$(_repo_name)/puppet.log'		\
		--logdest console					\
		--modulepath 'parts/rules/rules/puppet'

.PHONY: update
update: install-build-deps
	$(MAKE)

	sudo apt-get update
	sudo apt-get dist-upgrade -V -y			\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"

	$(MAKE) install

	sudo updatedb

.PHONY: configure
configure: /$(_repo_name)
	sudo puppet apply					\
		--execute 'include image::$(image_class)'	\
		--logdest '/var/log/$(_repo_name)/puppet.log'	\
		--logdest console				\
		--modulepath 'parts/rules/rules/puppet'

/$(_repo_name):
	@echo ERROR: localhost is not Puavo OS system >&2
	@false

.PHONY: push-release
push-release:
	EDITOR=.aux/drop-release-commits git rebase -p -i origin/master
	@parts/devscripts/bin/git-dch -f 'debs/puavo-os/debian/changelog'
	git push origin master:master
