# Public, configurable variables
debootstrap_mirror	:= http://httpredir.debian.org/debian/
debootstrap_suite	:= stretch
image_class		:= allinone
image_dir		:= /srv/puavo-os-images
rootfs_dir		:= /var/tmp/puavo-os/rootfs

include .opinsys/defaults.mk

_adm_user	:= puavo-os
_adm_group	:= puavo-os
_adm_uid	:= 1000
_adm_gid	:= 1000

_repo_name   := $(shell basename $(shell git rev-parse --show-toplevel))
_image_file  := $(image_dir)/$(_repo_name)-$(image_class)-$(debootstrap_suite)-$(shell date -u +%Y-%m-%d-%H%M%S)-amd64.img

# Some basic dependencies for our build system.  "python3" is on this list,
# because installing "devscripts" fails if "python3" has not been installed
# earlier, working around some bug in Debian (on 2016-11-18).
_debootstrap_packages := python3,devscripts,equivs,git,locales,lsb-release,\
			 make,puppet-common,sudo

_systemd_nspawn_machine_name := \
  $(notdir $(rootfs_dir))-$(shell tr -dc A-Za-z0-9 < /dev/urandom | head -c8)
_systemd_nspawn_cmd := systemd-nspawn -D '$(rootfs_dir)' \
			 -M '$(_systemd_nspawn_machine_name)' -u '$(_adm_user)'

.PHONY: build
build: build-debs-ports build-debs-parts

.PHONY: build-debs-parts
build-debs-parts:
	$(MAKE) -C debs parts

.PHONY: build-debs-ports
build-debs-ports:
	$(MAKE) -C debs ports

.PHONY: build-parts
build-parts:
	$(MAKE) -C parts

.PHONY: install
install: install-parts
	$(MAKE) install-rules

.PHONY: install-parts
install-parts: /$(_repo_name)
	sudo $(MAKE) -C parts install prefix=/usr sysconfdir=/etc

.PHONY: install-build-deps
install-build-deps: /$(_repo_name)
	$(MAKE) -C debs update-repo

	sudo env FACTER_puavoruleset=prepare puppet apply	\
		--logdest '/var/log/$(_repo_name)/puppet.log'	\
		--logdest console				\
		--modulepath 'rules'				\
		rules/site.pp

	$(MAKE) -C debs install-build-deps

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    [build]              build all'
	@echo '    build-debs-parts     build Puavo OS Debian packages'
	@echo '    build-debs-ports     build all external Debian packages'
	@echo '    build-parts          build all parts'
	@echo '    help                 display this help and exit'
	@echo '    install              install all'
	@echo '    install-build-deps   install all build dependencies'
	@echo '    install-parts        install all parts'
	@echo '    install-rules        install all Puppet rules'
	@echo '    rootfs-debootstrap   build Puavo OS rootfs from scratch'
	@echo '    rootfs-image         pack rootfs to a squashfs image'
	@echo '    rootfs-shell         spawn shell from Puavo OS rootfs'
	@echo '    rootfs-sync-repo     sync Puavo OS rootfs repo with the current repo'
	@echo '    rootfs-update        update Puavo OS rootfs'
	@echo '    update               update Puavo OS localhost'
	@echo
	@echo 'Variables:'
	@echo '    debootstrap_mirror   debootstrap mirror [$(debootstrap_mirror)]'
	@echo '    image_dir            directory where images are built [$(image_dir)]'
	@echo '    rootfs_dir           Puavo OS rootfs directory [$(rootfs_dir)]'

$(rootfs_dir):
	@echo ERROR: rootfs does not exist, make rootfs-debootstrap first >&2
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
	sudo .aux/set-image-release '$(rootfs_dir)' '$(image_class)' \
	    '$(notdir $(_image_file))'
	sudo mksquashfs '$(rootfs_dir)' '$(_image_file).tmp'	\
		-noappend -no-recovery -wildcards		\
		-ef '.aux/$(image_class).excludes'		\
		|| { rm -f '$(_image_file).tmp'; false; }
	sudo mv '$(_image_file).tmp' '$(_image_file)'
	@echo Built '$(_image_file)' successfully.

.PHONY: rootfs-shell
rootfs-shell: $(rootfs_dir)
	sudo $(_systemd_nspawn_cmd)

.PHONY: rootfs-sync-repo
rootfs-sync-repo: $(rootfs_dir)
	sudo .aux/create-adm-user '$(rootfs_dir)' '/$(_repo_name)' \
	    '$(_adm_user)' '$(_adm_group)' '$(_adm_uid)' '$(_adm_gid)'
	sudo rsync "--chown=$(_adm_uid):$(_adm_gid)" --chmod=Dg+s,ug+w \
	    -glopr . '$(rootfs_dir)/$(_repo_name)/'

.PHONY: rootfs-update
rootfs-update: rootfs-sync-repo
	sudo $(_systemd_nspawn_cmd) $(MAKE) -C '/$(_repo_name)' update

.PHONY: update
update: install-build-deps
	$(MAKE)

	sudo apt-get update
	sudo apt-get dist-upgrade -V -y			\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"

	$(MAKE) install

	sudo updatedb

.PHONY: install-rules
install-rules: /$(_repo_name)
	sudo .aux/setup-debconf
	sudo env 'FACTER_puavoruleset=$(image_class)' puppet apply	\
		--logdest '/var/log/$(_repo_name)/puppet.log'		\
		--logdest console					\
		--modulepath 'rules'					\
		rules/site.pp

/$(_repo_name):
	@echo ERROR: localhost is not Puavo OS system >&2
	@false
